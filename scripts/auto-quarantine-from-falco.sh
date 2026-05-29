#!/bin/bash

set -euo pipefail

KUBECTL="sudo /var/lib/rancher/rke2/bin/kubectl --kubeconfig /etc/rancher/rke2/rke2.yaml"
TARGET_NS="microseg-demo"
FALCO_NS="falco"
LOOKBACK="${1:-2m}"
INTERVAL="${2:-10}"

STATE_DIR="$HOME/k8s-lab/auto-response/state"
STATE_FILE="$STATE_DIR/quarantined-pods.txt"

mkdir -p "$STATE_DIR"
touch "$STATE_FILE"

echo "============================================================"
echo " Auto Quarantine from Falco"
echo "============================================================"
echo "Target namespace : $TARGET_NS"
echo "Falco namespace  : $FALCO_NS"
echo "Log lookback     : $LOOKBACK"
echo "Interval         : ${INTERVAL}s"
echo
echo "This script watches Falco logs for shell alerts and labels"
echo "matched pods with: quarantine=true security-status=quarantined"
echo
echo "Press Ctrl+C to stop."
echo "============================================================"

while true; do
  LOGS=$($KUBECTL logs -n "$FALCO_NS" -l app.kubernetes.io/name=falco --since="$LOOKBACK" --tail=1000 2>/dev/null || true)

  echo "$LOGS" | grep -Ei "shell|terminal" | grep "k8s_ns_name=$TARGET_NS" | while read -r line; do
    POD_NAME=$(echo "$line" | sed -n 's/.*k8s_pod_name=\([^ ]*\).*/\1/p')
    NS_NAME=$(echo "$line" | sed -n 's/.*k8s_ns_name=\([^ ]*\).*/\1/p')

    if [ -z "$POD_NAME" ] || [ -z "$NS_NAME" ]; then
      continue
    fi

    KEY="$NS_NAME/$POD_NAME"

    if grep -qx "$KEY" "$STATE_FILE"; then
      echo "[INFO] Already quarantined: $KEY"
      continue
    fi

    echo
    echo "[ALERT] Falco shell alert detected for pod: $KEY"
    echo "[ACTION] Applying quarantine labels..."

    $KUBECTL label pod "$POD_NAME" -n "$NS_NAME" \
      quarantine=true \
      security-status=quarantined \
      --overwrite

    $KUBECTL annotate pod "$POD_NAME" -n "$NS_NAME" \
      quarantine.reason="falco-shell-alert" \
      quarantine.time="$(date -Iseconds)" \
      --overwrite

    echo "$KEY" >> "$STATE_FILE"

    echo "[OK] Quarantined pod: $KEY"
  done

  sleep "$INTERVAL"
done
