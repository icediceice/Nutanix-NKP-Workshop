"""
Educates Training Portal integration service.

Auth flow (OAuth2 Resource Owner Password Credentials):
  1. POST /oauth2/token/ with Basic auth (client_id:client_secret) +
     form body: grant_type=password&username=robot@educates&password=<pw>
  2. Use the returned access_token as Bearer on all subsequent requests.
  3. Refresh via refresh_token before expiry (tracked internally).

Session flow:
  1. GET /workshops/catalog/environments/ → build workshop_name→env_name map
  2. For each workshop: POST /workshops/environment/<env_name>/request/
     → returns {"url": "<relative-path>", "name": "<session-name>", "user": "<uuid>"}
  3. Full activation URL = portal_url + url-field (one-time link, valid for `timeout` seconds)
  4. Store {workshop_id: activation_url} in participant.workshop_urls
  5. Cleanup: GET /workshops/session/<session-name>/terminate/

References:
  https://docs.educates.dev/en/stable/portal-rest-api/client-authentication/
  https://docs.educates.dev/en/stable/portal-rest-api/workshops-catalog/
  https://docs.educates.dev/en/stable/portal-rest-api/session-management/
"""

import json
import logging
import os
import time
import yaml
from datetime import datetime
from typing import List, Dict, Optional
from urllib.parse import urlencode

import httpx

logger = logging.getLogger(__name__)

COURSES_YAML = os.path.join(os.path.dirname(__file__), "..", "..", "..", "courses.yaml")

# How many seconds before token expiry we proactively refresh
TOKEN_REFRESH_BUFFER = 120


def _resolve_workshops(selected_modules: List[str]) -> List[str]:
    """
    Return deduplicated Educates workshop names for foundation + selected bundles.
    """
    path = os.path.abspath(COURSES_YAML)
    if not os.path.exists(path):
        path = "courses.yaml"
    with open(path) as f:
        data = yaml.safe_load(f)

    seen = set()
    workshops: List[str] = []

    def add(ws_list):
        for w in ws_list:
            if w not in seen:
                seen.add(w)
                workshops.append(w)

    add(data.get("foundation", {}).get("workshops", []))
    bundles = data.get("bundles", {})
    for bundle_id in selected_modules:
        add(bundles.get(bundle_id, {}).get("workshops", []))

    return workshops


class EducatesProvisioner:
    def __init__(
        self,
        portal_url: str,
        robot_client_id: str,
        robot_client_secret: str,
        robot_username: str,
        robot_password: str,
        index_url: str = "http://localhost:3000",
        dry_run: bool = True,
    ):
        self.portal_url = portal_url.rstrip("/") if portal_url else ""
        self.robot_client_id = robot_client_id
        self.robot_client_secret = robot_client_secret
        self.robot_username = robot_username
        self.robot_password = robot_password
        self.index_url = index_url
        self.dry_run = dry_run

        # Token cache
        self._access_token: Optional[str] = None
        self._refresh_token: Optional[str] = None
        self._token_expires_at: float = 0.0

        # Environment catalog cache: workshop_name -> environment_name
        # e.g. "k8s-intro" -> "k8s-intro-w01"
        self._env_cache: Dict[str, str] = {}
        self._env_cache_at: float = 0.0
        self._ENV_CACHE_TTL = 300  # 5 minutes

        # SSL: use CA bundle from mounted ConfigMap if present, else skip verify
        _ca_path = "/app/ca/workshop-ca.crt"
        self._ssl_verify = _ca_path if os.path.exists(_ca_path) else False

    def _client(self, timeout: float = 15.0) -> httpx.Client:
        """Return an httpx.Client with correct SSL settings for the portal."""
        return httpx.Client(timeout=timeout, verify=self._ssl_verify)

    # -------------------------------------------------------------------------
    # Public interface
    # -------------------------------------------------------------------------

    def provision_participant(self, participant, db) -> None:
        """
        Request an Educates workshop session for every workshop in the
        participant's resolved bundle list. Stores activation URLs in
        participant.workshop_urls.

        Sets participant.status = "ready" on success, "error" on failure.
        """
        selected_modules = json.loads(participant.modules) if participant.modules else []
        workshops = _resolve_workshops(selected_modules)

        if not workshops:
            raise ValueError(f"No workshops resolved for modules: {selected_modules}")

        try:
            if self.dry_run:
                urls = self._dry_run_urls(participant.username, workshops)
            else:
                urls = self._request_sessions(participant.username, participant.email, workshops)

            participant.workshop_urls = json.dumps(urls)
            participant.status = "ready"
            participant.provisioned_at = datetime.utcnow()
            db.commit()
            logger.info(
                "Provisioned %s — %d workshops (%s)",
                participant.name,
                len(urls),
                ", ".join(selected_modules),
            )
        except Exception as exc:
            participant.status = "error"
            participant.error_message = str(exc)
            db.commit()
            logger.error("Failed to provision %s: %s", participant.name, exc)
            raise

    def cleanup_participant(self, participant) -> None:
        """
        Terminate all Educates sessions for a single participant.
        Uses GET /workshops/user/<username>/sessions/ to discover active sessions,
        then terminates each one.
        """
        if self.dry_run:
            logger.info("[DRY RUN] Would terminate sessions for %s", participant.username)
            return

        token = self._get_token()
        headers = {"Authorization": f"Bearer {token}"}

        with self._client(30.0) as client:
            resp = client.get(
                f"{self.portal_url}/workshops/user/{participant.username}/sessions/",
                headers=headers,
            )
            if resp.status_code == 404:
                logger.info("No sessions found for user %s", participant.username)
                return
            resp.raise_for_status()
            sessions = resp.json().get("sessions", [])

        for session in sessions:
            session_name = session["name"]
            try:
                with self._client(30.0) as client:
                    r = client.get(
                        f"{self.portal_url}/workshops/session/{session_name}/terminate/",
                        headers=headers,
                    )
                    r.raise_for_status()
                logger.info("Terminated session %s", session_name)
            except Exception as exc:
                logger.warning("Could not terminate session %s: %s", session_name, exc)

    def cleanup_all_sessions(self) -> None:
        """
        Terminate all active sessions across all environments.
        In dry_run: logs only. In live: queries catalog for all environments,
        then terminates all allocated sessions.
        """
        if self.dry_run:
            logger.info("[DRY RUN] Would terminate all Educates workshop sessions.")
            return

        token = self._get_token()
        headers = {"Authorization": f"Bearer {token}"}

        with self._client(30.0) as client:
            resp = client.get(
                f"{self.portal_url}/workshops/catalog/environments/",
                headers=headers,
                params={"sessions": "true"},
            )
            resp.raise_for_status()

        terminated = 0
        for env in resp.json().get("environments", []):
            for session in env.get("sessions", []):
                session_name = session["name"]
                try:
                    with self._client(30.0) as client:
                        r = client.get(
                            f"{self.portal_url}/workshops/session/{session_name}/terminate/",
                            headers=headers,
                        )
                        r.raise_for_status()
                    terminated += 1
                except Exception as exc:
                    logger.warning("Could not terminate session %s: %s", session_name, exc)

        logger.info("Cleanup complete — terminated %d sessions.", terminated)

    def check_health(self) -> dict:
        """Check if Educates Training Portal is reachable and credentials are valid."""
        if self.dry_run:
            return {"status": "dry_run", "portal_url": self.portal_url or "not configured"}

        if not self.portal_url:
            return {"status": "not_configured", "portal_url": ""}

        try:
            token = self._get_token()
            headers = {"Authorization": f"Bearer {token}"}
            with self._client(10.0) as client:
                resp = client.get(
                    f"{self.portal_url}/workshops/catalog/environments/",
                    headers=headers,
                )
            environments = resp.json().get("environments", [])
            return {
                "status": "ok",
                "portal_url": self.portal_url,
                "environments": len(environments),
                "environment_names": [e["name"] for e in environments],
            }
        except Exception as exc:
            return {"status": "unreachable", "portal_url": self.portal_url, "error": str(exc)}

    # -------------------------------------------------------------------------
    # Internal: OAuth2 token management
    # -------------------------------------------------------------------------

    def _get_token(self) -> str:
        """Return a valid access token, refreshing if near expiry."""
        now = time.time()

        # If token is still valid, return it
        if self._access_token and now < self._token_expires_at - TOKEN_REFRESH_BUFFER:
            return self._access_token

        # Try refresh token first (saves the robot password round-trip)
        if self._refresh_token:
            try:
                return self._refresh_access_token()
            except Exception:
                logger.debug("Token refresh failed, re-authenticating from scratch.")

        return self._authenticate()

    def _authenticate(self) -> str:
        """Obtain a fresh access token using robot credentials."""
        if not self.portal_url:
            raise ValueError("EDUCATES_PORTAL_URL is not configured.")
        if not self.robot_client_id or not self.robot_client_secret:
            raise ValueError(
                "Educates robot credentials not configured. "
                "Set EDUCATES_ROBOT_CLIENT_ID and EDUCATES_ROBOT_CLIENT_SECRET."
            )

        with self._client(15.0) as client:
            resp = client.post(
                f"{self.portal_url}/oauth2/token/",
                auth=(self.robot_client_id, self.robot_client_secret),
                data={
                    "grant_type": "password",
                    "username": self.robot_username,
                    "password": self.robot_password,
                },
            )

        if resp.status_code != 200:
            raise RuntimeError(
                f"Educates authentication failed: {resp.status_code} {resp.text}"
            )

        token_data = resp.json()
        self._access_token = token_data["access_token"]
        self._refresh_token = token_data.get("refresh_token")
        self._token_expires_at = time.time() + token_data.get("expires_in", 36000)
        logger.debug("Educates token obtained, expires in %ds", token_data.get("expires_in"))
        return self._access_token

    def _refresh_access_token(self) -> str:
        """Use the refresh token to obtain a new access token."""
        with self._client(15.0) as client:
            resp = client.post(
                f"{self.portal_url}/oauth2/token/",
                data={
                    "grant_type": "refresh_token",
                    "refresh_token": self._refresh_token,
                    "client_id": self.robot_client_id,
                    "client_secret": self.robot_client_secret,
                },
            )
        resp.raise_for_status()
        token_data = resp.json()
        self._access_token = token_data["access_token"]
        self._refresh_token = token_data.get("refresh_token", self._refresh_token)
        self._token_expires_at = time.time() + token_data.get("expires_in", 36000)
        logger.debug("Educates token refreshed.")
        return self._access_token

    # -------------------------------------------------------------------------
    # Internal: environment catalog
    # -------------------------------------------------------------------------

    def _get_env_name(self, workshop_name: str, headers: dict) -> str:
        """
        Resolve a workshop name (e.g. "k8s-intro") to the Educates environment
        name (e.g. "k8s-intro-w01") via the catalog API.

        Results are cached for _ENV_CACHE_TTL seconds to avoid hammering the API.
        """
        now = time.time()
        if now - self._env_cache_at > self._ENV_CACHE_TTL:
            self._refresh_env_cache(headers)

        env_name = self._env_cache.get(workshop_name)
        if not env_name:
            # Cache might be stale — try a fresh fetch
            self._refresh_env_cache(headers)
            env_name = self._env_cache.get(workshop_name)

        if not env_name:
            available = list(self._env_cache.keys())
            raise RuntimeError(
                f"Workshop '{workshop_name}' not found in Educates catalog. "
                f"Available workshops: {available}"
            )
        return env_name

    def _refresh_env_cache(self, headers: dict) -> None:
        """Fetch the workshop catalog and rebuild the workshop_name→env_name map."""
        with self._client(15.0) as client:
            resp = client.get(
                f"{self.portal_url}/workshops/catalog/environments/",
                headers=headers,
                params={"state": "RUNNING"},
            )
        resp.raise_for_status()

        self._env_cache = {}
        for env in resp.json().get("environments", []):
            workshop_name = env.get("workshop", {}).get("name", "")
            env_name = env.get("name", "")
            if workshop_name and env_name:
                self._env_cache[workshop_name] = env_name

        self._env_cache_at = time.time()
        logger.debug("Educates env cache refreshed: %s", self._env_cache)

    # -------------------------------------------------------------------------
    # Internal: session provisioning
    # -------------------------------------------------------------------------

    def _request_sessions(self, username: str, email: str, workshops: List[str]) -> Dict[str, str]:
        """
        Return direct session creation URLs for each workshop.

        With registration.type: anonymous, participants must NOT be sent to
        /activate/?token= URLs (those require portal login). Instead, use the
        /create/ endpoint which auto-creates an anonymous portal account on first
        visit — no login required.

        Reference: https://docs.educates.dev/en/stable/portal-rest-api/anonymous-access.html
        """
        token = self._get_token()
        headers = {"Authorization": f"Bearer {token}"}

        # Fall back to portal URL as index if localhost default is still set
        index_url = self.index_url if "localhost" not in self.index_url else self.portal_url

        urls: Dict[str, str] = {}
        for workshop_name in workshops:
            env_name = self._get_env_name(workshop_name, headers)
            create_url = (
                f"{self.portal_url}/workshops/environment/{env_name}/create/"
                f"?index_url={index_url}"
            )
            urls[workshop_name] = create_url
            logger.debug("Create URL for %s (%s) → %s", workshop_name, username, create_url)

        return urls

    def _dry_run_urls(self, username: str, workshops: List[str]) -> Dict[str, str]:
        """Generate placeholder activation URLs for dry-run testing."""
        return {
            w: f"https://dry-run.local/workshops/session/{w}-w01-s001/activate/?token=dryrun&user={username}"
            for w in workshops
        }
