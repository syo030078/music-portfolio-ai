#!/bin/bash
set -euo pipefail

REGION="ap-northeast-1"
KEY_NAME="music-portfolio-ai"
SG_NAME="music-portfolio-ai-sg"
INSTANCE_NAME="music-portfolio-ai"

echo "=== EC2 無料枠インスタンス作成 ==="

# 1. 最新の Amazon Linux 2023 AMI を取得
echo "[1/6] AMI を検索中..."
AMI_ID=$(aws ec2 describe-images \
  --region "$REGION" \
  --owners amazon \
  --filters "Name=name,Values=al2023-ami-2023.*-x86_64" \
            "Name=state,Values=available" \
  --query "sort_by(Images, &CreationDate)[-1].ImageId" \
  --output text)
echo "AMI: $AMI_ID"

# 2. キーペア作成
echo "[2/6] キーペア作成..."
KEY_FILE="$HOME/.ssh/${KEY_NAME}.pem"
if aws ec2 describe-key-pairs --key-names "$KEY_NAME" --region "$REGION" &>/dev/null; then
  echo "キーペア $KEY_NAME は既に存在します"
else
  aws ec2 create-key-pair \
    --key-name "$KEY_NAME" \
    --region "$REGION" \
    --query "KeyMaterial" \
    --output text > "$KEY_FILE"
  chmod 400 "$KEY_FILE"
  echo "秘密鍵: $KEY_FILE"
fi

# 3. セキュリティグループ作成
echo "[3/6] セキュリティグループ作成..."
MY_IP=$(curl -s https://checkip.amazonaws.com)

SG_ID=$(aws ec2 describe-security-groups \
  --group-names "$SG_NAME" \
  --region "$REGION" \
  --query "SecurityGroups[0].GroupId" \
  --output text 2>/dev/null || echo "")

if [ -z "$SG_ID" ] || [ "$SG_ID" = "None" ]; then
  SG_ID=$(aws ec2 create-security-group \
    --group-name "$SG_NAME" \
    --description "Music Portfolio AI - SSH and HTTP" \
    --region "$REGION" \
    --query "GroupId" \
    --output text)

  aws ec2 authorize-security-group-ingress \
    --group-id "$SG_ID" \
    --protocol tcp --port 22 \
    --cidr "${MY_IP}/32" \
    --region "$REGION"

  aws ec2 authorize-security-group-ingress \
    --group-id "$SG_ID" \
    --protocol tcp --port 80 \
    --cidr "0.0.0.0/0" \
    --region "$REGION"

  echo "SG: $SG_ID (SSH: ${MY_IP}, HTTP: 0.0.0.0/0)"
else
  echo "セキュリティグループ $SG_NAME は既に存在します ($SG_ID)"
fi

# 4. EC2 インスタンス起動
echo "[4/6] EC2 t2.micro 起動中..."
INSTANCE_ID=$(aws ec2 run-instances \
  --image-id "$AMI_ID" \
  --instance-type t2.micro \
  --key-name "$KEY_NAME" \
  --security-group-ids "$SG_ID" \
  --block-device-mappings "DeviceName=/dev/xvda,Ebs={VolumeSize=20,VolumeType=gp3}" \
  --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$INSTANCE_NAME}]" \
  --region "$REGION" \
  --query "Instances[0].InstanceId" \
  --output text)
echo "Instance: $INSTANCE_ID"

echo "起動待ち..."
aws ec2 wait instance-running --instance-ids "$INSTANCE_ID" --region "$REGION"

# 5. Elastic IP 割り当て
echo "[5/6] Elastic IP 割り当て..."
ALLOC_ID=$(aws ec2 allocate-address \
  --domain vpc \
  --region "$REGION" \
  --query "AllocationId" \
  --output text)

aws ec2 associate-address \
  --instance-id "$INSTANCE_ID" \
  --allocation-id "$ALLOC_ID" \
  --region "$REGION" > /dev/null

ELASTIC_IP=$(aws ec2 describe-addresses \
  --allocation-ids "$ALLOC_ID" \
  --region "$REGION" \
  --query "Addresses[0].PublicIp" \
  --output text)

# 6. 完了
echo ""
echo "[6/6] 完了!"
echo ""
echo "=========================================="
echo " Instance ID: $INSTANCE_ID"
echo " Elastic IP:  $ELASTIC_IP"
echo " SSH Key:     $KEY_FILE"
echo "=========================================="
echo ""
echo "次のステップ:"
echo ""
echo "1. SSH 接続 (30秒待ってから):"
echo "   ssh -i $KEY_FILE ec2-user@$ELASTIC_IP"
echo ""
echo "2. セットアップ実行:"
echo "   bash <(curl -fsSL https://raw.githubusercontent.com/syo030078/music-portfolio-ai/feature/ec2-cicd-v2/infrastructure/ec2/setup.sh) feature/ec2-cicd-v2"
echo ""
echo "3. GitHub Secrets 設定 (Settings > Secrets > Actions):"
echo "   EC2_HOST=$ELASTIC_IP"
echo "   EC2_SSH_KEY の値: cat $KEY_FILE"
echo ""
