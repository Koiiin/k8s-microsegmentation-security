\# Kubernetes Micro-segmentation Security Lab



\## Project Name



Nghiên cứu và triển khai giải pháp Micro-segmentation và giám sát an ninh trên môi trường Kubernetes.



\## Overview



This project implements a Kubernetes security lab based on a Defense-in-Depth architecture. The environment is built with Rancher, RKE2, Cilium, Hubble, and later Falco/SIEM for runtime detection and centralized security monitoring.



\## Current Architecture



| Component | Hostname | IP | Role |

|---|---|---|---|

| Rancher Server | rancher-server | 192.168.113.10 | Rancher Management |

| Kubernetes Master | k8s-master-1 | 192.168.113.11 | Control Plane, etcd |

| Worker Node 1 | k8s-worker-1 | 192.168.113.12 | Worker |

| Worker Node 2 | k8s-worker-2 | 192.168.113.13 | Worker |



\## Current Progress



\- \[x] Create 4 lightweight Ubuntu Server VMs

\- \[x] Configure persistent static IP for all VMs

\- \[x] Install Rancher Server using Docker

\- \[x] Create RKE2 custom cluster using Rancher

\- \[x] Join 1 control-plane/etcd node and 2 worker nodes

\- \[x] Install Cilium as the cluster CNI

\- \[x] Enable Hubble Relay and Hubble UI

\- \[x] Deploy cross-node demo workload

\- \[x] Verify pod-to-pod traffic from worker-1 to worker-2

\- \[ ] Apply default-deny NetworkPolicy

\- \[ ] Apply explicit allow NetworkPolicy

\- \[ ] Deploy Falco

\- \[ ] Integrate centralized logging / SIEM

\- \[ ] Build auto-response quarantine POC



\## Demo Workload



Namespace: `microseg-demo`



| Workload | Node | Purpose |

|---|---|---|

| client-netshoot | k8s-worker-1 | Traffic generator / client |

| backend-nginx | k8s-worker-2 | Backend service |



\## Key Evidence



\- `kubectl get nodes -o wide`

\- `kubectl get pods -n microseg-demo -o wide`

\- Hubble UI showing `client-netshoot -> backend-nginx` traffic with verdict `forwarded`

\- HTTP test returning `HTTP/1.1 200 OK`



\## Security Notes



Do not commit real Rancher tokens, kubeconfig files, SSH private keys, or passwords to this repository.

