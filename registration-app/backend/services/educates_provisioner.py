"""
Educates Training Portal integration service.

Educates (https://educates.dev) exposes a REST API on the TrainingPortal that allows
programmatic workshop session management. This service is the interface between our
registration app and the Educates platform.

IMPORTANT: The exact Educates REST API contract must be verified against the live docs:
  https://docs.educates.dev/en/stable/custom-resources/training-portal.html

If the REST API doesn't support direct session creation by user ID, alternatives are:
  1. Generate unique per-participant portal access URLs (anonymous access tokens)
  2. Use kubectl to create WorkshopSession CRDs directly

The dry_run mode allows full testing without a live Educates installation.
"""

import os
import json
import logging
import yaml
from datetime import datetime
from typing import List

import httpx

logger = logging.getLogger(__name__)

COURSES_YAML = os.path.join(os.path.dirname(__file__), "..", "..", "..", "courses.yaml")


def _resolve_workshops(selected_modules: List[str]) -> List[str]:
    """
    Given a list of selected bundle IDs, return the deduplicated list of
    Educates workshop CRD names to provision (foundation always included).
    """
    path = os.path.abspath(COURSES_YAML)
    if not os.path.exists(path):
        path = "courses.yaml"
    with open(path) as f:
        data = yaml.safe_load(f)

    workshop_set: list = []
    seen = set()

    def add_workshops(workshops):
        for w in workshops:
            if w not in seen:
                seen.add(w)
                workshop_set.append(w)

    # Foundation is always included
    foundation = data.get("foundation", {})
    add_workshops(foundation.get("workshops", []))

    # Add workshops for each selected bundle
    bundles = data.get("bundles", {})
    for bundle_id in selected_modules:
        bundle = bundles.get(bundle_id, {})
        add_workshops(bundle.get("workshops", []))

    return workshop_set


class EducatesProvisioner:
    def __init__(self, portal_url: str, portal_password: str, dry_run: bool = True):
        self.portal_url = portal_url
        self.portal_password = portal_password
        self.dry_run = dry_run

    def provision_participant(self, participant, db):
        """
        Request Educates workshop sessions for a participant.

        Resolves the workshop list from foundation + selected bundles in courses.yaml,
        deduplicates, then provisions each unique workshop.

        Sets participant.status = "ready" on success, "error" on failure.
        """
        selected_modules = json.loads(participant.modules) if participant.modules else []
        workshops = _resolve_workshops(selected_modules)

        if not workshops:
            raise ValueError(f"No workshops resolved for modules: {selected_modules}")

        if self.dry_run:
            urls = self._dry_run_urls(participant.username, workshops)
        else:
            urls = self._request_sessions(participant.username, workshops)

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

    def _dry_run_urls(self, username: str, workshops: List[str]) -> dict:
        """Generate fake workshop URLs for dry-run testing."""
        return {
            workshop_id: f"https://dry-run.local/workshop/{workshop_id}/session/{username}"
            for workshop_id in workshops
        }

    def _request_sessions(self, username: str, workshops: List[str]) -> dict:
        """
        Call Educates Training Portal REST API to create workshop sessions.

        TODO: Implement after verifying the actual Educates REST API contract.
        Reference: https://docs.educates.dev/en/stable/custom-resources/training-portal.html

        The API likely requires:
          - Authentication (bearer token or basic auth with portal credentials)
          - A request per workshop identifying the user
          - Returns a session URL the user can access directly

        Adapt this method based on actual Educates API response shape.
        """
        if not self.portal_url:
            raise ValueError("EDUCATES_PORTAL_URL is not configured.")

        urls = {}
        with httpx.Client(timeout=30.0) as client:
            for workshop_id in workshops:
                # Placeholder — replace with actual Educates API call
                response = client.post(
                    f"{self.portal_url}/workshops/environment/{workshop_id}/request/",
                    json={"user": username},
                    # headers={"Authorization": f"Bearer {self._get_token()}"},
                )
                if response.status_code in (200, 201):
                    data = response.json()
                    urls[workshop_id] = data.get("url", f"{self.portal_url}/workshop/{workshop_id}")
                else:
                    raise RuntimeError(
                        f"Educates API error for {workshop_id}: {response.status_code} {response.text}"
                    )
        return urls

    def cleanup_all_sessions(self):
        """
        Delete all active Educates workshop sessions.

        In dry_run mode: logs the operation.
        In live mode: calls Educates API or uses kubectl to delete WorkshopSession CRDs.

        TODO: Implement after verifying the cleanup API or CRD approach.
        """
        if self.dry_run:
            logger.info("[DRY RUN] Would delete all Educates workshop sessions.")
            return

        logger.info("Cleaning up all Educates workshop sessions...")
        # TODO: implement via Educates API or kubectl delete workshopsessions --all-namespaces

    def check_health(self) -> dict:
        """Check if Educates Training Portal is reachable."""
        if self.dry_run:
            return {"status": "dry_run", "portal_url": self.portal_url or "not configured"}

        if not self.portal_url:
            return {"status": "not_configured", "portal_url": ""}

        try:
            with httpx.Client(timeout=5.0) as client:
                response = client.get(f"{self.portal_url}/")
            return {"status": "ok", "portal_url": self.portal_url, "http_status": response.status_code}
        except Exception as exc:
            return {"status": "unreachable", "portal_url": self.portal_url, "error": str(exc)}
