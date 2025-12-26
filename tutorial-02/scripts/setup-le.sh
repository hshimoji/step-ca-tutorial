#!/bin/bash

set -euo pipefail

TUTORIAL=$(basename $(pwd))
LE_DIR=${LE_DIR:-/home/step/letsencrypt}
ARCHIVE_DIR="$LE_DIR/archive/localhost"
LIVE_DIR="$LE_DIR/live/localhost"
RENEWAL_DIR="$LE_DIR/renewal"

mkdir -p /tmp/initial-certs
step ca certificate localhost /tmp/initial-certs/fullchain.pem /tmp/initial-certs/privkey.pem \
    --provisioner admin \
    --root /home/step/certs/root_ca.crt \
    --ca-url https://localhost:9000/ \
    --password-file /home/step/secrets/ca-password

# Install into certbot-style layout so certbot recognizes "localhost"
mkdir -p "$ARCHIVE_DIR"
cp /tmp/initial-certs/fullchain.pem "$ARCHIVE_DIR/fullchain1.pem"
cp /tmp/initial-certs/privkey.pem "$ARCHIVE_DIR/privkey1.pem"
# extract cert (without chain) to cert1.pem
#openssl x509 -in /tmp/initial-certs/fullchain.pem -out "$ARCHIVE_DIR/cert1.pem" || true
step certificate inspect --format pem /tmp/initial-certs/fullchain.pem > "$ARCHIVE_DIR/cert1.pem" || true
# chain may be empty / same as fullchain - extract chain from fullchain if possible
# remove the first cert block, leaving the remainder as the chain
sed '1,/-----END CERTIFICATE-----/d' /tmp/initial-certs/fullchain.pem > "$ARCHIVE_DIR/chain1.pem" || true
if [ ! -s "$ARCHIVE_DIR/chain1.pem" ]; then
  # chain is empty — fall back to fullchain so Certbot's expected files exist
  cp "$ARCHIVE_DIR/fullchain1.pem" "$ARCHIVE_DIR/chain1.pem"
fi
# create live symlinks
mkdir -p "$LIVE_DIR"
ln -sf ../../archive/localhost/cert1.pem "$LIVE_DIR/cert.pem"
ln -sf ../../archive/localhost/fullchain1.pem "$LIVE_DIR/fullchain.pem"
ln -sf ../../archive/localhost/chain1.pem "$LIVE_DIR/chain.pem"
ln -sf ../../archive/localhost/privkey1.pem "$LIVE_DIR/privkey.pem"
# set conservative permissions for cert files
chmod 644 "$ARCHIVE_DIR"/*pem || true
chmod 600 "$ARCHIVE_DIR"/privkey1.pem || true

# create a minimal renewal config (try to auto-fill account kid if present)
mkdir -p "$RENEWAL_DIR"
ACCOUNT_KID=$(grep -oP '"kid"\s*:\s*"\K[^"]+' "$LE_DIR/accounts"/*/*/regr.json 2>/dev/null | sed -n '1p' || true)
cat > "$RENEWAL_DIR/localhost.conf" <<EOF
version = 1.2.0
archive_dir = /etc/letsencrypt/archive/localhost
cert = /etc/letsencrypt/live/localhost/cert.pem
privkey = /etc/letsencrypt/live/localhost/privkey.pem
chain = /etc/letsencrypt/live/localhost/chain.pem
fullchain = /etc/letsencrypt/live/localhost/fullchain.pem

[renewalparams]
account = ${ACCOUNT_KID:-}
authenticator = webroot
installer = None
server = https://localhost:9000/acme/${TUTORIAL}-acme
webroot_path = /usr/share/nginx/html

[[webroot_map]]
localhost = /usr/share/nginx/html
EOF

echo "Installed initial cert into $LIVE_DIR and created $RENEWAL_DIR/localhost.conf. Verify account KID and run 'certbot certificates' to confirm."
