# Falco - Runtime Intrusion Detection System

Falco được dùng làm Runtime IDS để phát hiện hành vi bất thường trong container.

---

## Mục tiêu (Objectives)

- Phát hiện shell được mở trong container
- Ghi nhận pod, namespace, image, process, user
- Cung cấp alert cho bước SIEM và auto-response

---

## Test Chính (Primary Test)

### Lệnh Thực Hiện

```bash
# Lấy Attacker pod
ATTACKER_POD=$(kubectl get pod -n microseg-demo -l app=attacker-netshoot -o jsonpath='{.items[0].metadata.name}')

# Exec vào container để trigger shell spawn
kubectl exec -n microseg-demo -it $ATTACKER_POD -- sh
```

### Kỳ vọng Alert

```
A shell was spawned in a container with an attached terminal
```

---

## Cách Hoạt Động (How It Works)

### Phát Hiện (Detection)
- Falco giám sát syscalls trong container runtime
- Phát hiện khi shell (sh, bash, zsh) được spawn
- Kiểm tra xem có terminal được attach hay không

### Ghi Nhận Thông Tin (Logging)
- Pod name
- Namespace
- Container image
- Process name
- User ID/Name
- Timestamp

### Gửi Alert (Alert Delivery)
- Xuất ra syslog hoặc stdout
- Được gửi đến Loki/Grafana qua SIEM
- Kích hoạt auto-response policies

---

## Cấu Hình (Configuration)

### Falco Values
Xem file cấu hình Helm tại: [falco/install/falco-values.yaml](install/falco-values.yaml)

### Rules
- Các rule mặc định đã bao gồm detection for shell spawn
- Custom rules có thể thêm vào nếu cần

---

## Troubleshooting

### Falco không phát hiện shell spawn
1. Kiểm tra Falco pods đang chạy:
   ```bash
   kubectl get pods -n falco
   ```

2. Xem log Falco:
   ```bash
   kubectl logs -n falco -l app=falco --tail=100
   ```

3. Đảm bảo rule đang active:
   ```bash
   kubectl describe daemonset falco -n falco
   ```

### Không thấy alert trong Grafana
1. Kiểm tra Loki datasource
2. Query: `{namespace="falco"}`
3. Trigger Falco alert mới