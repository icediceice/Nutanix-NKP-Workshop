import io
import os
import zipfile
from pathlib import Path
from typing import Optional

from fastapi import APIRouter
from fastapi.responses import FileResponse, JSONResponse, Response, StreamingResponse

router = APIRouter()

# CA cert location — mounted from ConfigMap in cluster, fallback for local dev
_CA_CERT_CANDIDATES = [
    "/app/ca/workshop-ca.crt",
    os.path.join(os.path.dirname(__file__), "..", "..", "..", "..",
                 "workshops", "nkp-workshop", "resources", "workshop-ca.crt"),
]

# Write-through cache: once extracted from cluster, store locally for fast serving
_CA_CERT_CACHE_PATH = Path("/tmp/workshop-ca.crt")


def _extract_ca_from_cluster() -> Optional[str]:
    """Try to pull the workshop CA cert from the running cluster.

    Searches cert-manager and Traefik TLS secrets for a ca.crt or the root
    cert in a TLS chain.  Returns PEM text or None.
    """
    try:
        from kubernetes import client, config as k8s_config  # type: ignore

        kubeconfig = os.environ.get("KUBECONFIG_PATH", "")
        if kubeconfig and Path(kubeconfig).exists():
            k8s_config.load_kube_config(config_file=kubeconfig)
        else:
            k8s_config.load_incluster_config()

        v1 = client.CoreV1Api()

        # ── Pass 1: look for a secret with a ca.crt key ──────────────────
        for ns in ("cert-manager", "kommander", "kommander-default-workspace"):
            try:
                secrets = v1.list_namespaced_secret(ns, timeout_seconds=5)
            except Exception:
                continue
            for secret in secrets.items:
                data = secret.data or {}
                if "ca.crt" in data:
                    import base64
                    return base64.b64decode(data["ca.crt"]).decode("utf-8", errors="replace")

        # ── Pass 2: extract root cert from Traefik / wildcard TLS chain ──
        for ns in ("kommander-default-workspace", "kube-system", "traefik"):
            try:
                secrets = v1.list_namespaced_secret(ns, timeout_seconds=5)
            except Exception:
                continue
            for secret in secrets.items:
                name = (secret.metadata.name or "").lower()
                if not any(kw in name for kw in ("traefik", "wildcard", "tls", "workshop")):
                    continue
                data = secret.data or {}
                if "tls.crt" not in data:
                    continue
                import base64
                pem_chain = base64.b64decode(data["tls.crt"]).decode("utf-8", errors="replace")
                # Split into individual certs; the last one is the root CA
                certs = []
                buf: list = []
                for line in pem_chain.splitlines():
                    buf.append(line)
                    if "-----END CERTIFICATE-----" in line:
                        certs.append("\n".join(buf))
                        buf = []
                if len(certs) >= 2:
                    return certs[-1]

    except Exception:
        pass

    return None


def _find_ca_cert() -> Path:
    # 1. Static candidates (ConfigMap mount or local dev path)
    for p in _CA_CERT_CANDIDATES:
        resolved = Path(p).resolve()
        if resolved.exists():
            return resolved

    # 2. In-memory cache from a previous cluster extraction
    if _CA_CERT_CACHE_PATH.exists():
        return _CA_CERT_CACHE_PATH

    # 3. Live extraction from the cluster
    pem = _extract_ca_from_cluster()
    if pem:
        _CA_CERT_CACHE_PATH.write_text(pem)
        return _CA_CERT_CACHE_PATH

    raise FileNotFoundError(
        "workshop-ca.crt not found. "
        "Run bootstrap-educates.sh to create the workshop-ca-cert ConfigMap "
        "or mount the nkp-kubeconfigs Secret so the backend can auto-discover it."
    )


_PS1_SCRIPT = r"""# NKP Workshop — CA Certificate Installer
# Run as Administrator: right-click → "Run with PowerShell" or "Run as administrator"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$certFile  = Join-Path $scriptDir "nkp-workshop-ca.crt"

if (-not (Test-Path $certFile)) {
    Write-Host "ERROR: nkp-workshop-ca.crt not found next to this script." -ForegroundColor Red
    Write-Host "Make sure both files are in the same folder." -ForegroundColor Red
    pause; exit 1
}

Write-Host "Installing NKP Workshop CA certificate..." -ForegroundColor Cyan
certutil -addstore -f "Root" "$certFile"

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "Success! Please restart your browser, then return to the setup page." -ForegroundColor Green
} else {
    Write-Host ""
    Write-Host "ERROR: certutil failed (exit code $LASTEXITCODE)." -ForegroundColor Red
    Write-Host "Make sure you are running as Administrator." -ForegroundColor Red
}
pause
"""

_BAT_SCRIPT = r"""@echo off
echo NKP Workshop CA Certificate Installer
echo Run this file as Administrator (right-click ^> Run as administrator)
echo.
certutil -addstore -f "Root" "%~dp0nkp-workshop-ca.crt"
if %errorlevel%==0 (
    echo.
    echo Success! Restart your browser and return to the setup page.
) else (
    echo.
    echo ERROR: certutil failed. Right-click this file and choose "Run as administrator".
)
pause
"""


@router.get("/setup/ca.crt")
def download_ca_cert():
    """Serve the workshop CA certificate with the correct MIME type.
    On macOS/iOS the browser triggers the OS install dialog automatically.
    On Windows/Linux the user downloads the file and runs the install script.
    """
    try:
        ca_path = _find_ca_cert()
    except FileNotFoundError as exc:
        return JSONResponse(status_code=503, content={"error": str(exc)})
    return FileResponse(
        path=str(ca_path),
        media_type="application/x-x509-ca-cert",
        filename="nkp-workshop-ca.crt",
    )


@router.get("/setup/install-cert.ps1")
def download_ps1():
    return Response(
        content=_PS1_SCRIPT,
        media_type="text/plain; charset=utf-8",
        headers={"Content-Disposition": 'attachment; filename="Install-NKP-Workshop-CA.ps1"'},
    )


@router.get("/setup/install-cert.bat")
def download_bat():
    return Response(
        content=_BAT_SCRIPT,
        media_type="text/plain; charset=utf-8",
        headers={"Content-Disposition": 'attachment; filename="install-nkp-workshop-ca.bat"'},
    )


@router.get("/setup/install-cert.zip")
def download_zip():
    """Bundle: ca.crt + .ps1 + .bat in one zip for Windows users."""
    try:
        ca_path = _find_ca_cert()
        ca_bytes = ca_path.read_bytes()
    except FileNotFoundError as exc:
        return JSONResponse(status_code=503, content={"error": str(exc)})

    buf = io.BytesIO()
    with zipfile.ZipFile(buf, mode="w", compression=zipfile.ZIP_DEFLATED) as zf:
        zf.writestr("nkp-workshop-ca.crt", ca_bytes)
        zf.writestr("Install-NKP-Workshop-CA.ps1", _PS1_SCRIPT)
        zf.writestr("install-nkp-workshop-ca.bat", _BAT_SCRIPT)
        zf.writestr(
            "README.txt",
            "NKP Workshop CA Certificate Bundle\n"
            "===================================\n\n"
            "Windows (recommended):\n"
            "  1. Right-click Install-NKP-Workshop-CA.ps1 → Run with PowerShell\n"
            "     (or Run as Administrator if prompted)\n\n"
            "Windows (alternative):\n"
            "  1. Right-click install-nkp-workshop-ca.bat → Run as administrator\n\n"
            "After installing, restart your browser and return to the setup page.\n",
        )
    buf.seek(0)

    return StreamingResponse(
        buf,
        media_type="application/zip",
        headers={"Content-Disposition": 'attachment; filename="nkp-workshop-cert-installer.zip"'},
    )


@router.get("/setup/config")
def setup_config():
    """Returns the portal URL so SetupPage can discover where to send users
    and which HTTPS endpoint to use for cert trust verification — without
    needing the trainer to embed it in the setup URL."""
    from config import settings
    portal_url = settings.educates_portal_url or ""
    return {
        "portal_url": portal_url,
        # The verify URL is the portal itself — if the browser can fetch it
        # over HTTPS without a TypeError, the CA cert is trusted.
        "verify_url": portal_url,
    }


@router.get("/setup/ping")
def ping():
    """HTTPS reachability probe. The setup page JS fetches this over HTTPS.
    If the fetch succeeds the CA cert is trusted by the browser."""
    return {"ok": True}
