# Trạng thái đồ án

## Trạng thái hiện tại

PoC bảo mật Kubernetes đã triển khai hoàn tất.

## Các thành phần đã hoàn thành

| Hạng mục | Trạng thái |
|---|---|
| Rancher Server | Hoàn thành |
| RKE2 Cluster | Hoàn thành |
| 1 control-plane + 2 worker | Hoàn thành |
| Cilium CNI | Hoàn thành |
| Hubble UI | Hoàn thành |
| Namespace demo `microseg-demo` | Hoàn thành |
| Default-deny NetworkPolicy | Hoàn thành |
| Explicit allow NetworkPolicy | Hoàn thành |
| Attacker pod validation | Hoàn thành |
| Falco Runtime IDS | Hoàn thành |
| Loki + Grafana + Alloy | Hoàn thành |
| Auto-response quarantine PoC | Hoàn thành |

## Luồng phòng thủ đã chứng minh

```text
Hành vi nghi vấn trong container
    ↓
Falco phát hiện runtime alert
    ↓
Alloy thu thập log Falco
    ↓
Loki lưu trữ log
    ↓
Grafana truy vấn và hiển thị cảnh báo
    ↓
Script auto-response gắn label quarantine=true
    ↓
CiliumNetworkPolicy chặn ingress/egress
    ↓
Pod nghi vấn bị cô lập