# DevSecOps demo – OWASP Juice Shop v20.2.0

Pipeline `.github/workflows/devsecops-selfhosted.yml` chạy trên self-hosted runner (nhãn `devsecops-cd`):

| Gate | Công cụ | Lỗi được demo | Chính sách |
|---|---|---|---|
| G1 | Conftest (Policy-as-Code) | `docker-compose.yml` chạy privileged, mở cổng 0.0.0.0, secret trong environment, mount Docker socket | POL-01, 02, 03 |
| G2 | Semgrep (Security-as-Code) | `routes/login.ts` ghép chuỗi SQL | POL-05 |
| G3 | node:test (Test-Driven Security) | `POST /api/Cards` trả về và lưu đủ 16 số thẻ | POL-07 |
| G4 | cinc-auditor/InSpec (Compliance-as-Code) | Nginx để lộ `/ftp`, `/support/logs`, `/encryptionkeys`, `/metrics` | POL-03 |
| CD | docker compose | Build, deploy Juice Shop + Nginx, smoke test, rollback | – |

## Kịch bản 5 lần push

| Lần | Lệnh | Kết quả |
|---|---|---|
| 1 | push bản gốc (đã có sẵn 4 lỗi) | đỏ ở G1 |
| 2 | `bash demo/step.sh 2` | qua G1, đỏ ở G2 |
| 3 | `bash demo/step.sh 3` | qua G2, đỏ ở G3 |
| 4 | `bash demo/step.sh 4` | qua G3, đỏ ở G4 |
| 5 | `bash demo/step.sh 5` | xanh cả 4 gate, tự deploy |

Bản sửa của từng bước nằm trong `demo/fixes/` (cùng đường dẫn với file gốc).

## Tổng duyệt (không deploy)

```bash
git switch -c rehearsal
bash demo/step.sh all
git add -A && git commit -m "rehearsal: áp tất cả bản sửa" && git push -u origin rehearsal
```

Vào tab Actions → workflow "DevSecOps - Juice Shop (self-hosted)" → Run workflow → chọn nhánh `rehearsal`.
Kỳ vọng: G1–G4 xanh, job CD bị bỏ qua (chỉ deploy khi push vào `main`).
