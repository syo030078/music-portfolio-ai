#!/bin/bash
set -euo pipefail

REPO_URL="https://github.com/miyatasyo/music-portfolio-ai.git"
BRANCH="${1:-main}"
APP_DIR="/home/ec2-user/music-portfolio-ai"

echo "=== Music Portfolio AI - EC2 Setup ==="
echo "Branch: $BRANCH"

# 1. System update & Docker install
echo "[1/7] Installing Docker..."
sudo dnf update -y
sudo dnf install -y docker git
sudo systemctl enable docker
sudo systemctl start docker
sudo usermod -aG docker ec2-user

sudo mkdir -p /usr/local/lib/docker/cli-plugins
sudo curl -SL "https://github.com/docker/compose/releases/latest/download/docker-compose-linux-$(uname -m)" \
  -o /usr/local/lib/docker/cli-plugins/docker-compose
sudo chmod +x /usr/local/lib/docker/cli-plugins/docker-compose

# 2. Create 2GB swap
echo "[2/7] Creating 2GB swap..."
if [ ! -f /swapfile ]; then
  sudo dd if=/dev/zero of=/swapfile bs=1M count=2048
  sudo chmod 600 /swapfile
  sudo mkswap /swapfile
  sudo swapon /swapfile
  echo '/swapfile swap swap defaults 0 0' | sudo tee -a /etc/fstab
fi

# 3. Clone repository
echo "[3/7] Cloning repository..."
if [ -d "$APP_DIR" ]; then
  cd "$APP_DIR"
  git fetch origin
  git checkout "$BRANCH"
  git pull origin "$BRANCH"
else
  git clone -b "$BRANCH" "$REPO_URL" "$APP_DIR"
  cd "$APP_DIR"
fi

# 4. Generate secrets
echo "[4/7] Generating secrets..."
DB_PASSWORD=$(openssl rand -hex 16)
SECRET_KEY_BASE=$(openssl rand -hex 64)

# 5. Get EC2 public IP (IMDSv2)
echo "[5/7] Detecting public IP..."
TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" \
  -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")

if [ -z "$TOKEN" ]; then
  echo "ERROR: Failed to get IMDSv2 token. Are you running on EC2?"
  exit 1
fi

PUBLIC_IP=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" \
  http://169.254.169.254/latest/meta-data/public-ipv4)

if [ -z "$PUBLIC_IP" ]; then
  echo "ERROR: Could not determine public IP."
  exit 1
fi

echo "Detected public IP: $PUBLIC_IP"

# 6. Create .env file
echo "[6/7] Creating .env..."
cat > "$APP_DIR/.env" <<EOF
DB_USERNAME=postgres
DB_PASSWORD=${DB_PASSWORD}
SECRET_KEY_BASE=${SECRET_KEY_BASE}
RAILS_MASTER_KEY=REPLACE_WITH_YOUR_MASTER_KEY
FRONTEND_URL=http://${PUBLIC_IP}
NEXT_PUBLIC_API_URL=http://${PUBLIC_IP}
EOF

echo ""
echo "============================================"
echo " IMPORTANT: Edit .env and set RAILS_MASTER_KEY"
echo " Get it from your local backend/config/master.key"
echo " Run: nano $APP_DIR/.env"
echo "============================================"
echo ""
read -p "Press Enter after setting RAILS_MASTER_KEY..."

if grep -q "REPLACE_WITH_YOUR_MASTER_KEY" "$APP_DIR/.env"; then
  echo "ERROR: RAILS_MASTER_KEY was not updated in .env"
  exit 1
fi

# 7. Build and start
echo "[7/7] Building and starting services..."
cd "$APP_DIR"
sudo docker compose -f docker-compose.production.yml build
sudo docker compose -f docker-compose.production.yml up -d

echo "Waiting for services to be healthy..."
sleep 15

sudo docker compose -f docker-compose.production.yml exec backend \
  bundle exec rails db:create db:migrate

echo ""
echo "=== Setup Complete ==="
echo "Access the app at: http://${PUBLIC_IP}/"
echo "Log out and back in to use 'docker' without sudo."
