# Kiến trúc hệ thống

## Mô hình tổng quan

```text
Windows Host
│
├── VM1: rancher-server
│   └── Rancher Server chạy bằng Docker
│
└── RKE2 Kubernetes Cluster
    ├── VM2: k8s-master-1
    │   └── Control Plane + etcd
    │
    ├── VM3: k8s-worker-1
    │   ├── client-netshoot
    │   ├── attacker-netshoot
    │   ├── Cilium agent
    │   ├── Falco agent
    │   └── Alloy agent
    │
    └── VM4: k8s-worker-2
        ├── backend-nginx
        ├── Loki
        ├── Grafana
        ├── Cilium agent
        ├── Falco agent
        └── Alloy agent
