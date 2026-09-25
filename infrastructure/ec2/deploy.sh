#!/bin/bash
set -euo pipefail

APP_DIR="/home/ec2-user/music-portfolio-ai"
COMPOSE="docker compose -f docker-compose.production.yml"

cd "$APP_DIR"

echo "=== Deploying ==="

git pull origin "$(git branch --show-current)"

$COMPOSE build

bash infrastructure/ec2/init-letsencrypt.sh

$COMPOSE up -d db
sleep 5

if ! $COMPOSE run --rm backend bundle exec rails db:migrate; then
  echo "ERROR: Migration failed"
  $COMPOSE logs backend
  exit 1
fi

$COMPOSE up -d

sleep 15

HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" \
  --resolve musicportfolioai.com:443:127.0.0.1 https://musicportfolioai.com/api/v1/health)

if [ "$HTTP_STATUS" = "200" ]; then
  echo "=== Deploy OK ==="
  $COMPOSE ps
else
  echo "=== FAILED: Health check returned $HTTP_STATUS ==="
  $COMPOSE logs --tail=20
  exit 1
fi
