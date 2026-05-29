# Kịch bản Demo (Demo Runbook)

## 1. Kiểm tra Trạng thái Hệ thống

### Lệnh
```bash
~/k8s-lab/scripts/check-cluster-status.sh
```

---

## 2. Mở Hubble UI

### Lệnh
```bash
~/k8s-lab/scripts/open-hubble.sh
```

### Truy cập
- **URL**: http://192.168.113.11:12000/?namespace=microseg-demo
- **Ghi chú**: Truy cập từ Windows hoặc máy trong cùng mạng

---

## 3. Sinh Traffic Hợp Lệ (Client → Backend)

### Lệnh
```bash
~/k8s-lab/scripts/generate-client-flow.sh 10
```

### Kỳ vọng
- **Kết quả**: `client-netshoot → backend-nginx: forwarded`
- **Trạng thái**: Traffic được cho phép

---

## 4. Sinh Traffic Attacker Bị Chặn

### Lệnh
```bash
~/k8s-lab/scripts/generate-attacker-flow.sh 5
```

### Kỳ vọng
- **Kết quả**: `attacker-netshoot → backend-nginx: dropped`
- **Trạng thái**: Traffic bị từ chối

---

## 5. Trigger Falco Alert

### Lệnh
```bash
# Lấy Attacker pod
ATTACKER_POD=$(kubectl get pod -n microseg-demo -l app=attacker-netshoot -o jsonpath='{.items[0].metadata.name}')

# Exec vào container
kubectl exec -n microseg-demo -it $ATTACKER_POD -- sh
```

### Thực hiện Trong Container
```bash
id
whoami
cat /etc/passwd | head
exit
```

### Kỳ vọng Falco Alert
- **Alert**: `A shell was spawned in a container with an attached terminal`

---

## 6. Mở Grafana Dashboard

### Lệnh
```bash
~/k8s-lab/scripts/open-grafana.sh
```

### Truy cập Grafana
- **URL**: http://192.168.113.11:3000
- **Tài khoản**: `admin`
- **Mật khẩu**: `Grafana@123456`

### Loki Query Trong Explore
```logql
{namespace="falco"} |= "shell"
```

---

## 7. Demo Auto-Response Quarantine

### Bước 1: Chạy Watcher
```bash
~/k8s-lab/scripts/auto-quarantine-from-falco.sh 2m 10
```

### Bước 2: Trigger Falco Alert
Trigger Falco alert lại bằng kubectl exec (như bước 5)

### Bước 3: Kiểm tra Label
```bash
kubectl get pods -n microseg-demo --show-labels
```

### Kỳ vọng
- **Labels**: 
  - `quarantine=true`
  - `security-status=quarantined`

---

## 8. Demo Manual Quarantine Client

### Bước 1: Kiểm tra Kết Nối Trước Quarantine
```bash
CLIENT_POD=$(kubectl get pod -n microseg-demo -l app=client-netshoot -o jsonpath='{.items[0].metadata.name}')
kubectl exec -n microseg-demo -it $CLIENT_POD -- curl -I --connect-timeout 5 http://backend-svc
```

### Bước 2: Áp Dụng Quarantine
```bash
~/k8s-lab/scripts/quarantine-pod.sh microseg-demo $CLIENT_POD
```

### Bước 3: Kiểm tra Kết Nối Sau Quarantine
```bash
kubectl exec -n microseg-demo -it $CLIENT_POD -- curl -I --connect-timeout 5 http://backend-svc
```

### Bước 4: Unquarantine Pod
```bash
~/k8s-lab/scripts/unquarantine-pod.sh microseg-demo $CLIENT_POD
```

### Bước 5: Kiểm tra Kết Nối Sau Unquarantine
```bash
kubectl exec -n microseg-demo -it $CLIENT_POD -- curl -I --connect-timeout 5 http://backend-svc
```

### Kỳ vọng
| Giai đoạn | Kết quả Kỳ vọng |
|-----------|-----------------|
| Trước quarantine | `HTTP/1.1 200 OK` |
| Sau quarantine | `timeout` |
| Sau unquarantine | `HTTP/1.1 200 OK` |