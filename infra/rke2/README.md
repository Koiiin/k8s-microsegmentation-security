# RKE2 Cluster

RKE2 cluster gồm 1 control-plane/etcd node và 2 worker node.

## Node

| Hostname | IP | Vai trò |
|---|---|---|
| `k8s-master-1` | `192.168.113.11` | Control Plane, etcd |
| `k8s-worker-1` | `192.168.113.12` | Worker |
| `k8s-worker-2` | `192.168.113.13` | Worker |

## CNI

Cluster sử dụng Cilium làm CNI chính.
