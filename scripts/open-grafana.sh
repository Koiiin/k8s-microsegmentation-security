#!/bin/bash

set -e

KUBECTL="sudo /var/lib/rancher/rke2/bin/kubectl --kubeconfig /etc/rancher/rke2/rke2.yaml"
LOCAL_PORT="3000"

echo "Opening Grafana UI..."
echo "URL: http://192.168.113.11:${LOCAL_PORT}"
echo "Username: admin"
echo "Password: Grafana@123456"
echo
echo "Press Ctrl+C to stop."

sudo pkill -f "port-forward.*grafana" 2>/dev/null || true
sleep 2

$KUBECTL -n logging port-forward svc/grafana --address 0.0.0.0 ${LOCAL_PORT}:80
