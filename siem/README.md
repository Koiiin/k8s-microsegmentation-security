# SIEM-lite

Thư mục này chứa cấu hình Loki, Grafana và Alloy.

## Thành phần

| Thành phần | Vai trò |
|---|---|
| Alloy | Thu thập log từ Kubernetes pod |
| Loki | Lưu trữ log |
| Grafana | Truy vấn và hiển thị log |

## Query quan trọng

```logql
{namespace="falco"} |= "shell"