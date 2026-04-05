"""
Cluster health and status monitoring service.

Connects to the Kubernetes cluster to check:
- Node readiness
- kube-system namespace UID (used to detect cluster recreation)
- Educates Training Portal health
- Resource availability
"""

import logging
from typing import Optional

logger = logging.getLogger(__name__)


class ClusterMonitor:
    def __init__(self, kubeconfig_path: str, cluster_context: str, dry_run: bool = True):
        self.kubeconfig_path = kubeconfig_path
        self.cluster_context = cluster_context
        self.dry_run = dry_run

    def get_status(self) -> dict:
        """Return cluster health summary."""
        if self.dry_run:
            return {
                "mode": "dry_run",
                "cluster_uid": "dry-run-uid-00000000",
                "nodes": {"total": 3, "ready": 3},
                "educates": {"status": "dry_run"},
                "message": "Running in dry-run mode — cluster not connected.",
            }

        try:
            client = self._get_k8s_client()
            return {
                "mode": "live",
                "cluster_uid": self._get_kube_system_uid(client),
                "nodes": self._get_node_status(client),
                "educates": self._check_educates(),
            }
        except Exception as exc:
            logger.warning("Cluster status check failed: %s", exc)
            return {"mode": "error", "error": str(exc)}

    def get_kube_system_uid(self) -> Optional[str]:
        """Return the kube-system namespace UID, used to detect cluster recreation."""
        if self.dry_run:
            return "dry-run-uid-00000000"
        try:
            client = self._get_k8s_client()
            return self._get_kube_system_uid(client)
        except Exception:
            return None

    def detect_cluster_change(self, stored_uid: str) -> bool:
        """Return True if the current cluster UID differs from the stored UID."""
        current_uid = self.get_kube_system_uid()
        if current_uid is None:
            return False  # Can't connect — don't assume change
        return current_uid != stored_uid

    def reconcile_after_cluster_change(self, db):
        """Reset all 'ready' participants to 'registered' after a detected cluster recreation."""
        from models.participant import Participant

        db.query(Participant).filter(Participant.status == "ready").update(
            {"status": "registered", "workshop_urls": None, "provisioned_at": None},
            synchronize_session=False,
        )
        db.commit()
        logger.info("Cluster change detected — reset all 'ready' participants to 'registered'.")

    def _get_k8s_client(self):
        from kubernetes import client, config as k8s_config

        if self.kubeconfig_path:
            k8s_config.load_kube_config(config_file=self.kubeconfig_path, context=self.cluster_context)
        else:
            try:
                k8s_config.load_incluster_config()
            except Exception:
                k8s_config.load_kube_config(context=self.cluster_context)

        return client.CoreV1Api()

    def _get_kube_system_uid(self, core_v1) -> str:
        ns = core_v1.read_namespace("kube-system")
        return str(ns.metadata.uid)

    def _get_node_status(self, core_v1) -> dict:
        nodes = core_v1.list_node()
        total = len(nodes.items)
        ready = sum(
            1
            for n in nodes.items
            if any(
                c.type == "Ready" and c.status == "True"
                for c in (n.status.conditions or [])
            )
        )
        return {"total": total, "ready": ready}

    def _check_educates(self) -> dict:
        from config import settings
        import httpx

        if not settings.educates_portal_url:
            return {"status": "not_configured"}
        try:
            import os
            _ca_path = "/app/ca/ca.crt"
            _ssl = _ca_path if os.path.exists(_ca_path) else False
            with httpx.Client(timeout=5.0, verify=_ssl) as http:
                resp = http.get(settings.educates_portal_url)
            return {"status": "ok", "http_status": resp.status_code}
        except Exception as exc:
            return {"status": "unreachable", "error": str(exc)}
