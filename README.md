# Kubernetes Micro-segmentation Security PoC

## 1. Giới thiệu

Đây là đồ án triển khai mô hình bảo mật cho môi trường Kubernetes theo hướng **Defense-in-Depth**, tập trung vào các mục tiêu chính:

* Xây dựng Kubernetes cluster bằng Rancher và RKE2.
* Triển khai micro-segmentation bằng Cilium và Kubernetes NetworkPolicy.
* Quan sát traffic giữa các pod bằng Hubble.
* Phát hiện hành vi runtime bất thường bằng Falco.
* Tập trung hóa log bảo mật bằng Alloy, Loki và Grafana.
* Xây dựng cơ chế auto-response/quarantine ở mức PoC để cô lập pod nghi vấn.

PoC này chứng minh luồng bảo mật:

```text
Prevent → Observe → Detect → Investigate → Respond
```

Trong đó:

```text
Cilium/NetworkPolicy       → Ngăn chặn traffic không hợp lệ
Hubble                     → Quan sát network flow
Falco                      → Phát hiện hành vi runtime bất thường
Alloy + Loki + Grafana     → Thu thập, lưu trữ và truy vấn log cảnh báo
Auto-response script       → Gắn label quarantine cho pod nghi vấn
CiliumNetworkPolicy        → Cô lập pod bị quarantine
```

---

## 2. Kiến trúc tổng quan

### 2.1. Mô hình VM

| VM  | Hostname         | IP               | Vai trò                   |
| --- | ---------------- | ---------------- | ------------------------- |
| VM1 | `rancher-server` | `192.168.113.10` | Rancher Server            |
| VM2 | `k8s-master-1`   | `192.168.113.11` | RKE2 Control Plane + etcd |
| VM3 | `k8s-worker-1`   | `192.168.113.12` | Worker Node               |
| VM4 | `k8s-worker-2`   | `192.168.113.13` | Worker Node               |

### 2.2. Thành phần triển khai

| Lớp                     | Công cụ                           | Vai trò                                      |
| ----------------------- | --------------------------------- | -------------------------------------------- |
| Cluster Management      | Rancher                           | Quản lý Kubernetes cluster                   |
| Kubernetes Distribution | RKE2                              | Nền tảng Kubernetes chính                    |
| CNI / Network Security  | Cilium                            | CNI và thực thi network policy               |
| Network Observability   | Hubble                            | Quan sát flow forwarded/dropped              |
| Runtime Detection       | Falco                             | Phát hiện hành vi bất thường trong container |
| Log Collection          | Alloy                             | Thu thập log từ pod                          |
| Log Storage             | Loki                              | Lưu trữ log tập trung                        |
| Visualization           | Grafana                           | Truy vấn và hiển thị log bảo mật             |
| Auto-response           | Bash script + CiliumNetworkPolicy | Cô lập pod nghi vấn                          |

---

## 3. Namespace demo

PoC sử dụng namespace:

```text
microseg-demo
```

Đây là namespace demo nhẹ, dùng để kiểm chứng các cơ chế bảo mật trước khi xây dựng ứng dụng hoàn chỉnh.

### 3.1. Workload trong namespace demo

| Workload            | Vị trí         | Vai trò              |
| ------------------- | -------------- | -------------------- |
| `backend-nginx`     | `k8s-worker-2` | Backend service      |
| `client-netshoot`   | `k8s-worker-1` | Client hợp lệ        |
| `attacker-netshoot` | `k8s-worker-1` | Pod giả lập attacker |

### 3.2. Mục đích của namespace demo

Namespace này dùng để chứng minh:

* Pod-to-pod communication giữa hai worker node.
* Cilium/Hubble quan sát được traffic.
* Default-deny NetworkPolicy chặn traffic mặc định.
* Explicit allow policy chỉ cho phép client hợp lệ truy cập backend.
* Attacker pod bị chặn dù nằm cùng namespace.
* Falco phát hiện hành vi mở shell trong container.
* Auto-response có thể gắn label quarantine và cô lập pod nghi vấn.

---

## 4. Luồng PoC đã triển khai

### 4.1. Micro-segmentation

Ban đầu, client hợp lệ có thể truy cập backend:

```text
client-netshoot → backend-nginx = HTTP 200
```

Sau khi áp dụng default-deny:

```text
client-netshoot → backend-nginx = timeout / dropped
```

Sau khi áp dụng explicit allow:

```text
client-netshoot → backend-nginx = HTTP 200
attacker-netshoot → backend-nginx = timeout / dropped
```

### 4.2. Runtime Detection

Falco được triển khai dưới dạng DaemonSet trên các worker node.

Khi thực hiện hành vi:

```bash
kubectl exec -n microseg-demo -it attacker-netshoot -- sh
```

Falco sinh cảnh báo:

```text
A shell was spawned in a container with an attached terminal
```

Alert có chứa các thông tin phục vụ điều tra như:

```text
user=root
process=sh
container_name=netshoot
k8s_pod_name=attacker-netshoot-...
k8s_ns_name=microseg-demo
```

### 4.3. Centralized Logging / SIEM-lite

Alloy thu thập log từ các pod và gửi về Loki. Grafana dùng Loki datasource để truy vấn log.

Query chính trong Grafana Explore:

```logql
{namespace="falco"} |= "shell"
```

Kết quả cần thấy:

```text
A shell was spawned in a container with an attached terminal
```

### 4.4. Auto-response / Quarantine PoC

Luồng phản ứng tự động:

```text
Falco alert
    ↓
auto-quarantine script đọc log
    ↓
trích xuất pod name và namespace
    ↓
gắn label quarantine=true
    ↓
CiliumNetworkPolicy quarantine-deny-all match pod đó
    ↓
chặn toàn bộ ingress/egress
    ↓
pod bị cô lập
```

CiliumNetworkPolicy chính:

```text
auto-response/00-quarantine-deny-all-cnp.yaml
```

Label dùng để quarantine:

```text
quarantine=true
security-status=quarantined
```

---

## 5. Cấu trúc repo

```text
.
├── README.md
├── PROJECT_STATUS.md
├── SECURITY_NOTES.md
│
├── app/
│   └── microseg-demo/
│       ├── backend-nginx.yaml
│       ├── client-netshoot.yaml
│       ├── attacker-netshoot.yaml
│       └── README.md
│
├── network-policy/
│   ├── 00-default-deny-all.yaml
│   ├── 01-allow-dns-egress.yaml
│   ├── 02-allow-client-egress-to-backend.yaml
│   ├── 03-allow-backend-ingress-from-client.yaml
│   └── README.md
│
├── cilium/
│   └── hubble/
│       ├── rke2-cilium-hubble.yaml
│       └── README.md
│
├── falco/
│   ├── install/
│   │   └── falco-values.yaml
│   └── README.md
│
├── siem/
│   ├── loki/
│   │   └── loki-values.yaml
│   ├── grafana/
│   │   └── grafana-values.yaml
│   ├── alloy/
│   │   └── alloy-values.yaml
│   └── README.md
│
├── auto-response/
│   ├── 00-quarantine-deny-all-cnp.yaml
│   └── README.md
│
├── scripts/
│   ├── check-cluster-status.sh
│   ├── health.sh
│   ├── open-hubble.sh
│   ├── open-grafana.sh
│   ├── get-demo-pods.sh
│   ├── backend-info.sh
│   ├── generate-client-flow.sh
│   ├── generate-attacker-flow.sh
│   ├── auto-quarantine-from-falco.sh
│   ├── quarantine-pod.sh
│   └── unquarantine-pod.sh
│
├── docs/
│   ├── 00-index.md
│   ├── 01-environment-inventory.md
│   ├── 02-progress-log.md
│   ├── 03-command-history.md
│   ├── 04-demo-namespace-note.md
│   ├── 05-architecture.md
│   ├── 06-demo-runbook.md
│   └── 07-troubleshooting.md
│
├── evidence/
│   ├── cluster/
│   ├── cilium/
│   ├── hubble/
│   ├── app/
│   ├── network-policy/
│   ├── falco/
│   ├── siem/
│   └── auto-response/
│
└── screenshots/
    ├── 01-rancher/
    ├── 02-cluster/
    ├── 03-cilium-hubble/
    ├── 04-network-policy/
    ├── 05-falco/
    ├── 06-siem/
    └── 07-auto-response/
```

---

## 6. Kịch bản demo nhanh

### 6.1. Kiểm tra trạng thái hệ thống

```bash
~/k8s-lab/scripts/check-cluster-status.sh
```

### 6.2. Mở Hubble UI

```bash
~/k8s-lab/scripts/open-hubble.sh
```

Truy cập từ Windows:

```text
http://192.168.113.11:12000/?namespace=microseg-demo
```

### 6.3. Sinh traffic hợp lệ

```bash
~/k8s-lab/scripts/generate-client-flow.sh 10
```

Kỳ vọng trong Hubble:

```text
client-netshoot → backend-nginx: forwarded
```

### 6.4. Sinh traffic attacker bị chặn

```bash
~/k8s-lab/scripts/generate-attacker-flow.sh 5
```

Kỳ vọng trong Hubble:

```text
attacker-netshoot → backend-nginx: dropped
```

### 6.5. Trigger Falco alert

```bash
ATTACKER_POD=$(kubectl get pod -n microseg-demo -l app=attacker-netshoot -o jsonpath='{.items[0].metadata.name}')
kubectl exec -n microseg-demo -it $ATTACKER_POD -- sh
```

Trong container:

```sh
id
whoami
cat /etc/passwd | head
exit
```

Kiểm tra Falco log:

```bash
kubectl logs -n falco -l app.kubernetes.io/name=falco --tail=100 | grep -Ei "shell|attacker|microseg-demo"
```

### 6.6. Mở Grafana

```bash
~/k8s-lab/scripts/open-grafana.sh
```

Truy cập:

```text
http://192.168.113.11:3000
```

Query trong Grafana Explore:

```logql
{namespace="falco"} |= "shell"
```

### 6.7. Chạy auto-response quarantine

Mở terminal riêng:

```bash
~/k8s-lab/scripts/auto-quarantine-from-falco.sh 2m 10
```

Trigger lại Falco alert bằng `kubectl exec`.

Kiểm tra pod bị gắn label:

```bash
kubectl get pods -n microseg-demo --show-labels
```

Kỳ vọng:

```text
quarantine=true
security-status=quarantined
```

### 6.8. Manual quarantine test

Lấy client pod:

```bash
CLIENT_POD=$(kubectl get pod -n microseg-demo -l app=client-netshoot -o jsonpath='{.items[0].metadata.name}')
```

Trước quarantine:

```bash
kubectl exec -n microseg-demo -it $CLIENT_POD -- curl -I --connect-timeout 5 http://backend-svc
```

Kỳ vọng:

```text
HTTP/1.1 200 OK
```

Quarantine client:

```bash
~/k8s-lab/scripts/quarantine-pod.sh microseg-demo $CLIENT_POD
```

Test lại:

```bash
kubectl exec -n microseg-demo -it $CLIENT_POD -- curl -I --connect-timeout 5 http://backend-svc
```

Kỳ vọng:

```text
curl: (28) Connection timed out
```

Gỡ quarantine:

```bash
~/k8s-lab/scripts/unquarantine-pod.sh microseg-demo $CLIENT_POD
```

Test lại:

```bash
kubectl exec -n microseg-demo -it $CLIENT_POD -- curl -I --connect-timeout 5 http://backend-svc
```

Kỳ vọng:

```text
HTTP/1.1 200 OK
```

---

## 7. Các file cấu hình chính

### 7.1. App demo

| File                                       | Mục đích             |
| ------------------------------------------ | -------------------- |
| `app/microseg-demo/backend-nginx.yaml`     | Backend service      |
| `app/microseg-demo/client-netshoot.yaml`   | Client hợp lệ        |
| `app/microseg-demo/attacker-netshoot.yaml` | Pod giả lập attacker |

### 7.2. NetworkPolicy

| File                                                       | Mục đích                                |
| ---------------------------------------------------------- | --------------------------------------- |
| `network-policy/00-default-deny-all.yaml`                  | Chặn toàn bộ ingress/egress mặc định    |
| `network-policy/01-allow-dns-egress.yaml`                  | Cho phép DNS egress                     |
| `network-policy/02-allow-client-egress-to-backend.yaml`    | Cho phép client egress tới backend      |
| `network-policy/03-allow-backend-ingress-from-client.yaml` | Cho phép backend nhận traffic từ client |

### 7.3. Cilium/Hubble

| File                                    | Mục đích                      |
| --------------------------------------- | ----------------------------- |
| `cilium/hubble/rke2-cilium-hubble.yaml` | Bật Hubble Relay và Hubble UI |

### 7.4. Falco

| File                              | Mục đích                     |
| --------------------------------- | ---------------------------- |
| `falco/install/falco-values.yaml` | Cấu hình cài Falco bằng Helm |

### 7.5. SIEM-lite

| File                               | Mục đích         |
| ---------------------------------- | ---------------- |
| `siem/loki/loki-values.yaml`       | Cấu hình Loki    |
| `siem/grafana/grafana-values.yaml` | Cấu hình Grafana |
| `siem/alloy/alloy-values.yaml`     | Cấu hình Alloy   |

### 7.6. Auto-response

| File                                            | Mục đích                                                  |
| ----------------------------------------------- | --------------------------------------------------------- |
| `auto-response/00-quarantine-deny-all-cnp.yaml` | CiliumNetworkPolicy cô lập pod có label `quarantine=true` |

---

## 8. Evidence và screenshot

Các bằng chứng triển khai được lưu trong:

```text
evidence/
```

Ảnh minh chứng được lưu trong:

```text
screenshots/
```

Các nhóm bằng chứng chính:

| Thư mục                    | Nội dung                      |
| -------------------------- | ----------------------------- |
| `evidence/cluster/`        | Node và pod toàn cluster      |
| `evidence/cilium/`         | Trạng thái Cilium             |
| `evidence/hubble/`         | Trạng thái Hubble             |
| `evidence/network-policy/` | Kết quả before/after policy   |
| `evidence/falco/`          | Log Falco và trạng thái Falco |
| `evidence/siem/`           | Trạng thái Loki/Grafana/Alloy |
| `evidence/auto-response/`  | Kết quả quarantine PoC        |

---

## 9. Ghi chú sau reboot

Sau khi shutdown và bật lại các VM, cần kiểm tra:

```bash
kubectl get nodes -o wide
kubectl get pods -A | grep -Ev 'Running|Completed'
~/k8s-lab/scripts/check-cluster-status.sh
```

Port-forward sẽ mất sau reboot, vì vậy cần mở lại:

```bash
~/k8s-lab/scripts/open-hubble.sh
~/k8s-lab/scripts/open-grafana.sh
```

Nếu Hubble không có flow mới, sinh lại traffic:

```bash
~/k8s-lab/scripts/generate-client-flow.sh 10
~/k8s-lab/scripts/generate-attacker-flow.sh 5
```

Nếu Grafana không thấy Falco log, trigger lại Falco alert.

---

## 10. Lưu ý bảo mật

Các giá trị như IP VM, mật khẩu Grafana lab và self-signed certificate chỉ phục vụ môi trường lab, không dùng cho production.

---

## 11. Hướng phát triển

* Thay namespace demo bằng ứng dụng microservices hoàn chỉnh.
* Bổ sung Cilium L7 HTTP policy.
* Tích hợp cảnh báo Grafana Alerting.
* Tích hợp Falcosidekick để gửi alert tới webhook/Slack/email.
* Xây dựng controller auto-response thay vì bash script.
* Bổ sung dashboard Grafana chuyên biệt cho security events.
* Sử dụng external object storage cho Loki.
* Tăng cường RBAC và hardening node.
* Triển khai GitOps bằng Argo CD hoặc Fleet.

---

## 12. Trạng thái hiện tại

PoC đã hoàn thành các lớp chính:

```text
Infrastructure
→ Network Security
→ Runtime Detection
→ Centralized Logging
→ Auto-response
```

