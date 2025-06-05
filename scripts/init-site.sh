#!/bin/sh
# Initialize a new Payload CMS site on the server
set -eu

read -r -p "Site name: " SITE_NAME
read -r -p "Site domain: " SITE_DOMAIN

# Repository containing the Payload project
REPO_URL="${1:-${REPO_URL:-}}"
if [ -z "$REPO_URL" ]; then
  echo "Usage: REPO_URL=<git repository> $0 [repo_url]" >&2
  exit 1
fi

TARGET="/srv/$SITE_NAME"

if [ -d "$TARGET" ]; then
  echo "Directory $TARGET already exists" >&2
  exit 1
fi

git clone "$REPO_URL" "$TARGET"

cp "$TARGET/.env.example" "$TARGET/.env"

PAYLOAD_SECRET=$(openssl rand -hex 32)
DATABASE_URI="postgres://payload:payload@db:5432/payload"
S3_ENDPOINT="http://minio:9000"
PORT=3000
TRUST_PROXY=1

sed -i "s/^PAYLOAD_SECRET=.*/PAYLOAD_SECRET=$PAYLOAD_SECRET/" "$TARGET/.env"
sed -i "s|^DATABASE_URI=.*|DATABASE_URI=$DATABASE_URI|" "$TARGET/.env"
sed -i "s|^S3_ENDPOINT=.*|S3_ENDPOINT=$S3_ENDPOINT|" "$TARGET/.env"
sed -i "s/^PORT=.*/PORT=$PORT/" "$TARGET/.env"
sed -i "s/^SITE_NAME=.*/SITE_NAME=$SITE_NAME/" "$TARGET/.env"
sed -i "s/^SITE_DOMAIN=.*/SITE_DOMAIN=$SITE_DOMAIN/" "$TARGET/.env"
sed -i "s/^TRUST_PROXY=.*/TRUST_PROXY=$TRUST_PROXY/" "$TARGET/.env"

SERVICE_FILE="/etc/systemd/system/${SITE_NAME}.service"
cat <<SERVICE > "$SERVICE_FILE"
[Unit]
Description=Payload CMS site $SITE_NAME
After=docker.service
Requires=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=$TARGET
ExecStart=/usr/bin/docker compose up -d
ExecStop=/usr/bin/docker compose down

[Install]
WantedBy=multi-user.target
SERVICE

systemctl daemon-reload
systemctl enable --now "${SITE_NAME}.service"

echo "Site $SITE_NAME initialized at $TARGET"
