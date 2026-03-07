#!/bin/bash
# bootstrap-workshop.sh — First-time setup for the NKP workshop
# Usage: ./scripts/bootstrap-workshop.sh [--lab <overlay-name>]
set -eo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAB="${LAB:-lab-01-start}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --lab) LAB="$2"; shift 2 ;;
    *) echo "Unknown arg: $1"; exit 1 ;;
  esac
done

echo "=== NKP Workshop Bootstrap ==="
echo "Initial lab: $LAB"
echo ""

# Apply the ArgoCD Application
echo "Applying ArgoCD Application..."
kubectl apply -f "${SCRIPT_DIR}/../platform/argocd/application.yaml"

# Wait for ArgoCD Application to be ready
echo "Waiting for ArgoCD Application to be created..."
sleep 5

# Switch to the initial lab overlay
echo "Switching to initial overlay: $LAB"
"${SCRIPT_DIR}/switch-lab.sh" "$LAB"

# Print access URLs
echo ""
"${SCRIPT_DIR}/print-access.sh"

echo ""
echo "Bootstrap complete. Workshop is ready."
