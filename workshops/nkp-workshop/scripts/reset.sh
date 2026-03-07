#!/bin/bash
# reset.sh — Full workshop reset between sessions
# Switches to workshop-reset overlay (prunes all app resources), then idles.
set -eo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=== Workshop Reset ==="
echo "Switching to workshop-reset overlay (all app workloads will be pruned)..."
"${SCRIPT_DIR}/switch-lab.sh" workshop-reset

echo "Waiting 30s for prune to complete..."
sleep 30

echo "Switching to workshop-load-off (idle state)..."
"${SCRIPT_DIR}/switch-lab.sh" workshop-load-off

echo ""
echo "Workshop reset complete. Cluster is idle and ready for the next session."
