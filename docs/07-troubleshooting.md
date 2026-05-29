# Xử lý Lỗi Thường Gặp (Troubleshooting Guide)

## 1. Hubble UI Không Truy cập Được Sau Reboot

### Vấn đề
Port-forward chỉ tồn tại trong phiên terminal hiện tại. Khi khởi động lại, cần chạy lại script.

### Giải pháp
```bash
~/k8s-lab/scripts/open-hubble.sh
```

**Nếu port bị chiếm dụng:**
```bash
sudo pkill -f "port-forward.*hubble-ui"
~/k8s-lab/scripts/open-hubble.sh
```

---

## 2. Hubble Không Hiện Flow

### Vấn đề
Không thấy traffic flow trên Hubble UI

### Giải pháp
Sinh traffic mới để Hubble ghi lại:
```bash
~/k8s-lab/scripts/generate-client-flow.sh 10
~/k8s-lab/scripts/generate-attacker-flow.sh 5
```

---

## 3. Grafana UI Không Truy cập Được Sau Reboot

### Vấn đề
Port-forward Grafana bị mất sau reboot

### Giải pháp
```bash
~/k8s-lab/scripts/open-grafana.sh
```

**Nếu port bị chiếm dụng:**
```bash
sudo pkill -f "port-forward.*grafana"
~/k8s-lab/scripts/open-grafana.sh
```

---

## 4. Grafana Không Thấy Falco Log

### Vấn đề
Loki datasource không hiển thị Falco alerts

### Giải pháp
Tạo Falco alert mới:
```bash
# Lấy Attacker pod
ATTACKER_POD=$(kubectl get pod -n microseg-demo -l app=attacker-netshoot -o jsonpath='{.items[0].metadata.name}')

# Exec vào container để trigger alert
kubectl exec -n microseg-demo -it $ATTACKER_POD -- sh
```

Sau đó query trong Grafana Explore:
```logql
{namespace="falco"} |= "shell"
```

---

## 5. Rancher UI Không Truy cập Được

### Vấn đề
Rancher server không phản hồi

### Kiểm tra Trên rancher-server
```bash
# Kiểm tra tình trạng container
docker ps

# Kiểm tra tài nguyên
free -h
docker stats --no-stream

# Kiểm tra HTTPS
curl -kI https://127.0.0.1

# Kiểm tra log
docker logs --tail=100 rancher
```

### Giải pháp: Restart Rancher
```bash
docker restart rancher
```

---

## 6. cattle-cluster-agent CrashLoopBackOff

### Vấn đề
Cattle cluster agent không khởi động thành công

### Kiểm tra Trên k8s-master-1
```bash
# Xem status pod
kubectl get pods -n cattle-system -o wide

# Xem log
kubectl logs -n cattle-system -l app=cattle-cluster-agent --tail=150

# Restart deployment
kubectl rollout restart deployment cattle-cluster-agent -n cattle-system
```

---

## 7. Loki Log Bị Mất Sau Reboot

### Vấn đề
Log Falco cũ không tìm thấy sau khi khởi động lại

### Giải thích
Cấu hình Loki trong lab dùng filesystem nhẹ, không dùng object storage production-grade. Dữ liệu được lưu tạm thời.

### Giải pháp
1. Trigger Falco alert mới
2. Query lại trong Grafana Explore:
   ```logql
   {namespace="falco"} |= "shell"
   ```