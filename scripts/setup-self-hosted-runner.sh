#!/usr/bin/env bash
# scripts/setup-self-hosted-runner.sh
# Cài các thành phần CẦN SUDO cho self-hosted runner, chạy MỘT LẦN trên VM (Ubuntu 22.04/24.04):
#   sudo bash scripts/setup-self-hosted-runner.sh <user-chạy-runner>
# Conftest, Semgrep, Node, Python do workflow tự cài vào tool cache, không cần ở đây.
set -euo pipefail

RUNNER_USER="${1:-${SUDO_USER:-}}"
if [ -z "$RUNNER_USER" ] || ! id "$RUNNER_USER" >/dev/null 2>&1; then
  echo "Cách dùng: sudo bash $0 <user-chạy-runner>" >&2
  exit 1
fi
if [ "$(id -u)" -ne 0 ]; then
  echo "Cần chạy bằng sudo" >&2
  exit 1
fi

echo "==> Gói hệ thống (curl, git, công cụ build cho sqlite3)"
apt-get update
apt-get install -y --no-install-recommends \
  ca-certificates curl git tar unzip build-essential python3

echo "==> Docker Engine và Docker Compose v2"
if ! command -v docker >/dev/null; then
  curl -fsSL https://get.docker.com | sh
fi
docker compose version

echo "==> Cho user ${RUNNER_USER} dùng Docker không cần sudo"
usermod -aG docker "$RUNNER_USER"

echo "==> cinc-auditor (bản mã nguồn mở của InSpec) cho gate G4"
if ! command -v cinc-auditor >/dev/null; then
  curl -fsSL https://omnitruck.cinc.sh/install.sh | bash -s -- -P cinc-auditor
fi
cinc-auditor version

cat <<'EOF'

Xong. Khởi động lại dịch vụ runner để quyền nhóm docker có hiệu lực:
  cd ~/actions-runner && sudo ./svc.sh stop && sudo ./svc.sh start
Kiểm tra runner có đủ nhãn: self-hosted, linux, x64, devsecops-cd
EOF
