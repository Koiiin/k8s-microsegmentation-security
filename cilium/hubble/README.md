# Cilium và Hubble

Thư mục này chứa cấu hình bật Hubble cho Cilium trong RKE2.

## File chính

| File | Mục đích |
|---|---|
| `rke2-cilium-hubble.yaml` | Bật Hubble Relay và Hubble UI cho Cilium |

## Vai trò trong PoC

- Cilium là CNI chính của cluster.
- Hubble dùng để quan sát traffic pod-to-pod.
- Hubble giúp chứng minh flow `forwarded` và `dropped` khi áp dụng NetworkPolicy.

## Mở Hubble UI

```bash
~/k8s-lab/scripts/open-hubble.sh
```

### Truy cập: http://192.168.113.11:12000/?namespace=microseg-demo
