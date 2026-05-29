# microseg-demo

Namespace `microseg-demo` là workload demo dùng để kiểm chứng các cơ chế bảo mật trước khi xây dựng ứng dụng hoàn chỉnh.

## Workload

| Workload | Mục đích |
|---|---|
| `backend-nginx` | Backend service |
| `client-netshoot` | Client hợp lệ |
| `attacker-netshoot` | Pod giả lập attacker |

## Mục tiêu kiểm thử

- Giao tiếp pod-to-pod giữa hai worker node
- Quan sát flow bằng Hubble
- Kiểm thử default-deny NetworkPolicy
- Kiểm thử explicit allow policy
- Kiểm thử attacker bị chặn
- Trigger Falco alert
- Kiểm thử auto-response quarantine
