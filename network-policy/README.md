# Network Policy

Thư mục này chứa các Kubernetes NetworkPolicy dùng cho micro-segmentation.

## Các policy

| File | Chức năng |
|---|---|
| `00-default-deny-all.yaml` | Chặn toàn bộ ingress/egress mặc định |
| `01-allow-dns-egress.yaml` | Cho phép DNS egress tới CoreDNS |
| `02-allow-client-egress-to-backend.yaml` | Cho phép client truy cập backend TCP/80 |
| `03-allow-backend-ingress-from-client.yaml` | Cho phép backend nhận traffic từ client |

## Luồng kiểm thử

```text
Trước policy: client -> backend = HTTP 200
Sau default-deny: client -> backend = timeout
Sau explicit allow: client -> backend = HTTP 200
Attacker pod: attacker -> backend = timeout