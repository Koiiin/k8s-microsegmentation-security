#!/bin/bash

set -e

KUBECTL="sudo /var/lib/rancher/rke2/bin/kubectl --kubeconfig /etc/rancher/rke2/rke2.yaml"
NAMESPACE="microseg-demo"
COUNT="${1:-10}"

CLIENT_POD=$($KUBECTL get pod -n "$NAMESPACE" -l app=client-netshoot -o jsonpath='{.items[0].metadata.name}')

echo "Generating allowed traffic:"
echo "client-netshoot -> backend-svc"
echo "CLIENT_POD=$CLIENT_POD"
echo "COUNT=$COUNT"
echo

for i in $(seq 1 "$COUNT"); do
  echo "[client request $i/$COUNT] expected: ALLOWED"
  $KUBECTL exec -n "$NAMESPACE" "$CLIENT_POD" -- curl -s -o /dev/null -w "HTTP_CODE=%{http_code}\n" --connect-timeout 3 -m 5 http://backend-svc || true
  sleep 1
done

echo
echo "Done. Check Hubble UI for forwarded flow."
