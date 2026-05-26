#!/bin/bash

set -e

KUBECTL="sudo /var/lib/rancher/rke2/bin/kubectl --kubeconfig /etc/rancher/rke2/rke2.yaml"

APP_NS="microseg-demo"
FALCO_NS="falco"
KUBE_NS="kube-system"

echo "============================================================"
echo " Kubernetes Security Lab - Cluster Health Check"
echo "============================================================"
echo "Time: $(date)"
echo

echo "============================================================"
echo "[1] Nodes"
echo "============================================================"
$KUBECTL get nodes -o wide
echo

NOT_READY_NODES=$($KUBECTL get nodes --no-headers | awk '$2!="Ready"{print $1}' || true)

if [ -n "$NOT_READY_NODES" ]; then
  echo "[WARN] Some nodes are not Ready:"
  echo "$NOT_READY_NODES"
else
  echo "[OK] All nodes are Ready."
fi
echo

echo "============================================================"
echo "[2] All pods overview"
echo "============================================================"
$KUBECTL get pods -A -o wide
echo

echo "============================================================"
echo "[3] Non-healthy pods"
echo "============================================================"
BAD_PODS=$($KUBECTL get pods -A --no-headers | awk '$4!="Running" && $4!="Completed"{print}' || true)

if [ -n "$BAD_PODS" ]; then
  echo "[WARN] Found pods not Running/Completed:"
  echo "$BAD_PODS"
else
  echo "[OK] No abnormal pod status found."
fi
echo

echo "============================================================"
echo "[4] Services overview"
echo "============================================================"
$KUBECTL get svc -A
echo

echo "============================================================"
echo "[5] Cilium status"
echo "============================================================"
$KUBECTL -n "$KUBE_NS" get pods | grep -i cilium || true
echo
$KUBECTL -n "$KUBE_NS" get ds | grep -i cilium || true
echo

CILIUM_DS=$($KUBECTL -n "$KUBE_NS" get ds cilium --no-headers 2>/dev/null || true)

if [ -z "$CILIUM_DS" ]; then
  echo "[WARN] Cilium DaemonSet not found."
else
  DESIRED=$(echo "$CILIUM_DS" | awk '{print $2}')
  READY=$(echo "$CILIUM_DS" | awk '{print $4}')
  if [ "$DESIRED" = "$READY" ]; then
    echo "[OK] Cilium DaemonSet Ready: $READY/$DESIRED"
  else
    echo "[WARN] Cilium DaemonSet not fully ready: $READY/$DESIRED"
  fi
fi
echo

echo "============================================================"
echo "[6] Hubble status"
echo "============================================================"
$KUBECTL -n "$KUBE_NS" get pods | grep -i hubble || true
echo
$KUBECTL -n "$KUBE_NS" get deploy | grep -i hubble || true
echo
$KUBECTL -n "$KUBE_NS" get svc | grep -i hubble || true
echo
$KUBECTL -n "$KUBE_NS" get endpoints hubble-ui 2>/dev/null || true
echo

if $KUBECTL -n "$KUBE_NS" get svc hubble-ui >/dev/null 2>&1; then
  echo "[OK] Hubble UI service exists."
else
  echo "[WARN] Hubble UI service not found."
fi
echo

echo "============================================================"
echo "[7] Falco status"
echo "============================================================"

if $KUBECTL get ns "$FALCO_NS" >/dev/null 2>&1; then
  $KUBECTL get pods -n "$FALCO_NS" -o wide
  echo
  $KUBECTL get ds -n "$FALCO_NS"
  echo

  FALCO_DS=$($KUBECTL get ds -n "$FALCO_NS" falco --no-headers 2>/dev/null || true)

  if [ -z "$FALCO_DS" ]; then
    echo "[WARN] Falco DaemonSet not found."
  else
    DESIRED=$(echo "$FALCO_DS" | awk '{print $2}')
    READY=$(echo "$FALCO_DS" | awk '{print $4}')
    if [ "$DESIRED" = "$READY" ]; then
      echo "[OK] Falco DaemonSet Ready: $READY/$DESIRED"
    else
      echo "[WARN] Falco DaemonSet not fully ready: $READY/$DESIRED"
    fi
  fi
else
  echo "[WARN] Namespace $FALCO_NS not found."
fi
echo

echo "============================================================"
echo "[8] Demo namespace status"
echo "============================================================"

if $KUBECTL get ns "$APP_NS" >/dev/null 2>&1; then
  echo "[OK] Namespace $APP_NS exists."
  echo

  echo "--- Pods:"
  $KUBECTL get pods -n "$APP_NS" -o wide
  echo

  echo "--- Services:"
  $KUBECTL get svc -n "$APP_NS"
  echo

  echo "--- NetworkPolicies:"
  $KUBECTL get networkpolicy -n "$APP_NS"
  echo

  CLIENT_POD=$($KUBECTL get pod -n "$APP_NS" -l app=client-netshoot -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || true)
  ATTACKER_POD=$($KUBECTL get pod -n "$APP_NS" -l app=attacker-netshoot -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || true)
  BACKEND_POD=$($KUBECTL get pod -n "$APP_NS" -l app=backend-nginx -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || true)
  BACKEND_IP=$($KUBECTL get pod -n "$APP_NS" -l app=backend-nginx -o jsonpath='{.items[0].status.podIP}' 2>/dev/null || true)

  echo "--- Demo pod variables:"
  echo "CLIENT_POD=$CLIENT_POD"
  echo "ATTACKER_POD=$ATTACKER_POD"
  echo "BACKEND_POD=$BACKEND_POD"
  echo "BACKEND_IP=$BACKEND_IP"
  echo

  if [ -n "$CLIENT_POD" ] && [ -n "$BACKEND_POD" ]; then
    echo "--- Connectivity test: client-netshoot -> backend-svc"
    if $KUBECTL exec -n "$APP_NS" "$CLIENT_POD" -- curl -s -shoot -> backend-svc"
    if $KUBECTL exec -n "$APP_NS" "$CLIENT_POD" -- curl -s -o /dev/null -w "HTTP_CODE=%{http_code}\n" --connect-timeout 3 -m 5 http://backend-svc; then
      echo "[OK] Legitimate client can reach backend-svc."
    else
      echo "[WARN] Legitimate client cannot reach backend-svc."
    fi
    echo
  else
    echo "[WARN] client-netshoot or backend-nginx pod not found. Skipping client test."
    echo
  fi

  if [ -n "$ATTACKER_POD" ]; then
    echo "--- Connectivity test: attacker-netshoot -> backend-svc"
    echo "Expected result: timeout / denied"
    $KUBECTL exec -n "$APP_NS" "$ATTACKER_POD" -- curl -I --connect-timeout 3 -m 5 http://backend-svc || true
    echo "[INFO] If the attacker request timed out, NetworkPolicy is working as expected."
    echo
  else
    echo "[WARN] attacker-netshoot pod not found. Skipping attacker test."
    echo
  fi

else
  echo "[WARN] Namespace $APP_NS not found."
fi
echo

echo "============================================================"
echo "[9] Recent Falco alerts"
echo "============================================================"

if $KUBECTL get ns "$FALCO_NS" >/dev/null 2>&1; then
  $KUBECTL logs -n "$FALCO_NS" -l app.kubernetes.io/name=falco --tail=100 2>/dev/null | grep -Ei "shell|terminal|attacker|microseg-demo|sensitive|passwd" || true
else
  echo "[WARN] Falco namespace not found."
fi
echo

echo "============================================================"
echo "[10] Summary"
echo "============================================================"
echo "Health check completed."
echo
echo "Recommended next checks if something is wrong:"
echo "- kubectl describe pod <pod> -n <namespace>"
echo "- kubectl logs <pod> -n <namespace>"
echo "- kubectl get events -A --sort-by=.metadata.creationTimestamp"
echo "============================================================"
