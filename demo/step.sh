#!/usr/bin/env bash
# demo/step.sh – áp bản sửa cho từng bước demo, commit và push
#
#   bash demo/step.sh 2          # sửa docker-compose.yml   -> qua G1, đỏ ở G2
#   bash demo/step.sh 3          # sửa routes/login.ts      -> qua G2, đỏ ở G3
#   bash demo/step.sh 4          # che số thẻ (PAN)         -> qua G3, đỏ ở G4
#   bash demo/step.sh 5          # Nginx chặn /ftp...       -> xanh cả 4 gate, tự deploy
#   bash demo/step.sh all        # áp cả 4 bản sửa, KHÔNG commit (dùng để tổng duyệt)
#   thêm --no-push để chỉ commit, không push
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"
F=demo/fixes
STEP="${1:-}"
PUSH=1
[ "${2:-}" = "--no-push" ] && PUSH=0

apply() {   # apply <file> ...: chép bản sửa đè lên file trong repo
  for f in "$@"; do
    mkdir -p "$(dirname "$f")"
    cp "$F/$f" "$f"
    echo "  đã áp: $f"
  done
}

case "$STEP" in
  2) FILES=(docker-compose.yml)
     MSG="fix(POL-01..03): cấu hình compose an toàn (demo 1 · G1)" ;;
  3) FILES=(routes/login.ts)
     MSG="fix(POL-05): truy vấn đăng nhập tham số hóa (demo 2 · G2)" ;;
  4) FILES=(lib/cardMasking.ts server.ts models/card.ts data/datacreator.ts)
     MSG="fix(POL-07): che số thẻ trước khi lưu và trả về (demo 3 · G3)" ;;
  5) FILES=(deploy/nginx/juice-shop.conf)
     MSG="fix(POL-03): Nginx chặn đường dẫn nội bộ (demo 4 · G4)" ;;
  all)
     apply docker-compose.yml routes/login.ts lib/cardMasking.ts server.ts \
           models/card.ts data/datacreator.ts deploy/nginx/juice-shop.conf
     echo "Đã áp tất cả bản sửa (chưa commit)."
     exit 0 ;;
  *) sed -n '2,10p' "$0"; exit 1 ;;
esac

echo "Bước $STEP:"
apply "${FILES[@]}"
git add "${FILES[@]}"
git commit -m "$MSG"
if [ "$PUSH" = 1 ]; then
  git push
  echo "Đã push. Mở tab Actions trên GitHub để xem pipeline."
fi
