# Auto-response Quarantine PoC

Module này triển khai cơ chế phản ứng tự động ở mức PoC.

## Luồng hoạt động

```text
Falco alert
→ auto-quarantine script
→ gắn label quarantine=true
→ CiliumNetworkPolicy deny ingress/egress
→ pod bị cô lập
```

## Policy chính

```text
00-quarantine-deny-all-cnp.yaml chọn các pod có label: quarantine=true và chặn toàn bộ ingress/egress.
```


