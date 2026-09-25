#!/bin/bash
# Let's Encrypt 証明書の初回発行 (冪等: 発行済みなら何もしない)
#
# 443 の server block は証明書が無いと nginx が起動できず、
# webroot 方式の発行には nginx が 80 番で応答している必要がある。
# この循環を避けるため、初回のみ nginx を止めて certbot standalone で発行する。
# 以降の更新は certbot サービスが webroot 方式で行う。
set -euo pipefail

APP_DIR="${APP_DIR:-/home/ec2-user/music-portfolio-ai}"
COMPOSE="docker compose -f docker-compose.production.yml"
# nginx.conf の server_name / 証明書パスと一致させること
DOMAIN="musicportfolioai.com"
CERT_MISSING=3

cd "$APP_DIR"

LETSENCRYPT_EMAIL="$(grep -E '^LETSENCRYPT_EMAIL=' .env 2>/dev/null | tail -1 | cut -d= -f2- || true)"

if [ -z "$LETSENCRYPT_EMAIL" ]; then
  echo "ERROR: .env に LETSENCRYPT_EMAIL を設定してください"
  exit 1
fi

# 「証明書が無い」と「docker 側のエラー」を区別し、前者のときだけ発行する
set +e
$COMPOSE run --rm --no-deps --entrypoint sh certbot \
  -c "test -f /etc/letsencrypt/live/${DOMAIN}/fullchain.pem || exit ${CERT_MISSING}"
rc=$?
set -e

case $rc in
  0)
    echo "=== Certificate for ${DOMAIN} already exists. Skipping. ==="
    exit 0
    ;;
  "$CERT_MISSING")
    ;;
  *)
    echo "ERROR: letsencrypt ボリュームを確認できませんでした (rc=${rc})。nginx は停止していません"
    exit 1
    ;;
esac

echo "=== Issuing certificate for ${DOMAIN} and www.${DOMAIN} ==="

# standalone は 80 番を自前で listen するため nginx を止める
$COMPOSE stop nginx

if ! $COMPOSE run --rm --no-deps --publish 80:80 --entrypoint certbot certbot \
  certonly --standalone \
  --cert-name "$DOMAIN" \
  -d "$DOMAIN" -d "www.${DOMAIN}" \
  --email "$LETSENCRYPT_EMAIL" \
  --agree-tos --no-eff-email --non-interactive; then
  echo "ERROR: 証明書の発行に失敗しました。nginx は停止中です"
  echo "  1. dig +short ${DOMAIN} / www.${DOMAIN} が Elastic IP を返すか確認"
  echo "  2. セキュリティグループで 80 番が 0.0.0.0/0 に開いているか確認"
  echo "  3. 修正後に再実行: bash infrastructure/ec2/init-letsencrypt.sh && ${COMPOSE} up -d"
  echo "  (Let's Encrypt は 1 ホスト名あたり 1 時間に 5 回まで検証失敗を許容する)"
  exit 1
fi

echo "=== Certificate issued ==="
