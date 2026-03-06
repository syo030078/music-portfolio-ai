#!/bin/bash
set -euo pipefail

APP_DIR="/home/ec2-user/music-portfolio-ai"
COMPOSE="docker compose -f docker-compose.production.yml"

cd "$APP_DIR"

echo "=== Deploying ==="

git pull origin "$(git branch --show-current)"

$COMPOSE build

$COMPOSE up -d db
sleep 5

if ! $COMPOSE run --rm backend bundle exec rails db:migrate; then
  echo "ERROR: Migration failed"
  $COMPOSE logs backend
  exit 1
fi

$COMPOSE up -d

sleep 15

HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/api/v1/health)

if [ "$HTTP_STATUS" = "200" ]; then
  echo "=== Deploy OK ==="
  $COMPOSE ps
else
  echo "=== FAILED: Health check returned $HTTP_STATUS ==="
  $COMPOSE logs --tail=20
  exit 1
fi
