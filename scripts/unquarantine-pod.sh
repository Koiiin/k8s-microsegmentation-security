#!/bin/bash

set -euo pipefail

KUBECTL="sudo /var/lib/rancher/rke2/bin/kubectl --kubeconfig /etc/rancher/rke2/rke2.yaml"
NS="${1:-microseg-demo}"
POD="${2:-}"

if [ -z "$POD" ]; then
  echo "Usage: $0 <namespace> <pod-name>"
  exit 1
fi

echo "Removing quarantine from pod: $NS/$POD"

$KUBECTL label pod "$POD" -n "$NS" \
  quarantine- \
  security-status- \
  --overwrite || true

$KUBECTL annotate pod "$POD" -n "$NS" \
  quarantine.reason- \
  quarantine.time- \
  --overwrite || true

echo "Done."
$KUBECTL get pod "$POD" -n "$NS" --show-labels
