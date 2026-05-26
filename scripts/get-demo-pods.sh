#!/bin/bash

set -e

KUBECTL="sudo /var/lib/rancher/rke2/bin/kubectl --kubeconfig /etc/rancher/rke2/rke2.yaml"
NAMESPACE="microseg-demo"

echo "Namespace: $NAMESPACE"
echo

$KUBECTL get pods -n "$NAMESPACE" -o wide
echo

CLIENT_POD=$($KUBECTL get pod -n "$NAMESPACE" -l app=client-netshoot -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || true)
ATTACKER_POD=$($KUBECTL get pod -n "$NAMESPACE" -l app=attacker-netshoot -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || true)
BACKEND_POD=$($KUBECTL get pod -n "$NAMESPACE" -l app=backend-nginx -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || true)
BACKEND_IP=$($KUBECTL get pod -n "$NAMESPACE" -l app=backend-nginx -o jsonpath='{.items[0].status.podIP}' 2>/dev/null || true)

echo "CLIENT_POD=$CLIENT_POD"
echo "ATTACKER_POD=$ATTACKER_POD"
echo "BACKEND_POD=$BACKEND_POD"
echo "BACKEND_IP=$BACKEND_IP"
