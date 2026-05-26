#!/bin/bash

set -e

KUBECTL="sudo /var/lib/rancher/rke2/bin/kubectl --kubeconfig /etc/rancher/rke2/rke2.yaml"
NAMESPACE="microseg-demo"
COUNT="${1:-5}"

ATTACKER_POD=$($KUBECTL get pod -n "$NAMESPACE" -l app=attacker-netshoot -o jsonpath='{.items[0].metadata.name}')

echo "Generating denied traffic:"
echo "attacker-netshoot -> backend-svc"
echo "ATTACKER_POD=$ATTACKER_POD"
echo "COUNT=$COUNT"
echo

for i in $(seq 1 "$COUNT"); do
  echo "[attacker request $i/$COUNT] expected: DROPPED / TIMEOUT"
  $KUBECTL exec -n "$NAMESPACE" "$ATTACKER_POD" -- curl -I --connect-timeout 3 -m 5 http://backend-svc || true
  sleep 1
done

echo
echo "Done. Check Hubble UI for dropped flow."
