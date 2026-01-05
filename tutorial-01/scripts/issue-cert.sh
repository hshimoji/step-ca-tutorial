#!/bin/bash

set -e

# This script issues a server certificate using the admin (JWK) provisioner.

PROVISIONER="admin"
CA_URL="https://localhost:9000"
ROOT_CERT="/home/step/certs/root_ca.crt"
DOMAIN="${1:-localhost}"

echo "============================================"
echo "Issuing Certificate"
echo "============================================"
echo "Domain: $DOMAIN"
echo "Provisioner: $PROVISIONER"
echo "CA URL: $CA_URL"
echo "============================================"
echo ""

# Issue certificate
step ca certificate "$DOMAIN" "${DOMAIN}.crt" "${DOMAIN}.key" \
  --provisioner "$PROVISIONER" \
  --ca-url "$CA_URL" \
  --root "$ROOT_CERT" \
  --provisioner-password-file /home/step/secrets/ca-password

echo ""
echo "============================================"
echo "Certificate Issued Successfully"
echo "============================================"
echo ""
echo "Files created:"
echo "  - ${DOMAIN}.crt (Certificate)"
echo "  - ${DOMAIN}.key (Private key)"
echo ""
echo "Certificate details:"
echo ""

step certificate inspect "${DOMAIN}.crt"