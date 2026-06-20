# Cilium L7 HTTP Policy

Phần này là module mở rộng của PoC micro-segmentation, dùng để kiểm thử khả năng kiểm soát HTTP Layer 7 bằng Cilium.

## Mục tiêu

Ở phase chính, đồ án kiểm soát L3/L4:

```text
client nào được gọi backend, port nào được phép
```

Ở phase mở rộng L7, đồ án kiểm soát thêm:
```
HTTP method nào được phép
HTTP path nào được phép
Workload
Workload	Vai trò
httpbin	Backend HTTP demo
client-netshoot-l7	Client hợp lệ
attacker-netshoot-l7	Pod giả lập attacker
Policy
```

File chính:
```
03-cilium-l7-allow-get-only.yaml
```
Policy chỉ cho phép:
```
client-netshoot-l7 → httpbin-svc GET /get
```
Các request không được phép:
```
client-netshoot-l7 → POST /post
client-netshoot-l7 → GET /headers
attacker-netshoot-l7 → GET /get
Kết quả kỳ vọng
GET /get từ client hợp lệ      → HTTP 200
POST /post từ client hợp lệ    → denied / không HTTP 200
GET /headers từ client hợp lệ  → denied / không HTTP 200
GET /get từ attacker           → denied / timeout
```
