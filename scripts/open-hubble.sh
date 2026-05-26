#!/bin/bash

set -e

KUBECTL="sudo /var/lib/rancher/rke2/bin/kubectl --kubeconfig /etc/rancher/rke2/rke2.yaml"
HUBBLE_CONFIG="$HOME/rke2-cilium-hubble.yaml"
LOCAL_PORT="12000"

echo "[1/5] Checking Hubble config file..."

if [ ! -f "$HUBBLE_CONFIG" ]; then
  echo "File $HUBBLE_CONFIG not found. Creating it..."

  cat > "$HUBBLE_CONFIG" <<'EOF'
apiVersion: helm.cattle.io/v1
kind: HelmChartConfig
metadata:
  name: rke2-cilium
  namespace: kube-system
spec:
  valuesContent: |-
    hubble:
      enabled: true
      relay:
        enabled: true
      ui:
        enabled: true
EOF
fi

echo "[2/5] Applying Hubble config..."
$KUBECTL apply -f "$HUBBLE_CONFIG"

echo "[3/5] Waiting for Cilium/Hubble components to reconcile..."
sleep 10

echo "[4/5] Current Cilium/Hubble pods:"
$KUBECTL -n kube-system get pods | grep -E 'cilium|hubble|helm-install-rke2-cilium' || true

echo
echo "Checking Hubble services..."
$KUBECTL -n kube-system get svc | grep hubble || true

echo
echo "Waiting for hubble-ui service to exist..."

for i in {1..30}; do
  if $KUBECTL -n kube-system get svc hubble-ui >/dev/null 2>&1; then
    echo "hubble-ui service found."
    break
  fi

  echo "hubble-ui service not ready yet... retry $i/30"
  sleep 5
done

if ! $KUBECTL -n kube-system get svc hubble-ui >/dev/null 2>&1; then
  echo "ERROR: hubble-ui service was not created."
  echo "Debug commands:"
  echo "$KUBECTL -n kube-system get helmchartconfig"
  echo "$KUBECTL -n kube-system get pods | grep -E 'cilium|hubble|helm-install'"
  echo "$KUBECTL -n kube-system get svc | grep hubble"
  exit 1
fi

echo "[5/5] Opening Hubble UI port-forward..."
echo "Open this URL on Windows:"
echo "http://192.168.113.11:${LOCAL_PORT}"
echo
echo "Keep this terminal open. Press Ctrl+C to stop port-forward."
echo

$KUBECTL -n kube-system port-forward svc/hubble-ui --address 0.0.0.0 ${LOCAL_PORT}:80
