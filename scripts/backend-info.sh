#!/bin/bash

set -e

KUBECTL="sudo /var/lib/rancher/rke2/bin/kubectl --kubeconfig /etc/rancher/rke2/rke2.yaml"
NAMESPACE="microseg-demo"

echo "Backend pod:"
$KUBECTL get pod -n "$NAMESPACE" -l app=backend-nginx -o wide

echo
echo "Backend service:"
$KUBECTL get svc -n "$NAMESPACE" backend-svc -o wide

echo
BACKEND_POD=$($KUBECTL get pod -n "$NAMESPACE" -l app=backend-nginx -o jsonpath='{.items[0].metadata.name}')
BACKEND_IP=$($KUBECTL get pod -n "$NAMESPACE" -l app=backend-nginx -o jsonpath='{.items[0].status.podIP}')
BACKEND_NODE=$($KUBECTL get pod -n "$NAMESPACE" -l app=backend-nginx -o jsonpath='{.items[0].spec.nodeName}')

echo "BACKEND_POD=$BACKEND_POD"
echo "BACKEND_IP=$BACKEND_IP"
echo "BACKEND_NODE=$BACKEND_NODE"
