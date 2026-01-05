#!/bin/bash

set -e

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source common functions
source "$SCRIPT_DIR/common.sh"

# This script issues a server certificate using the admin (JWK) provisioner.
# The certificate is signed by the intermediate CA whose private key is stored in GCP KMS.

PROVISIONER="admin"
CA_URL="https://localhost:9000"
ROOT_CERT="/home/step/certs/root_ca.crt"
DOMAIN="${1:-localhost}"

print_header "Issuing Certificate"
echo "Domain: $DOMAIN"
echo "Provisioner: $PROVISIONER"
echo "CA URL: $CA_URL"
print_header ""
echo ""

# Issue certificate
step ca certificate "$DOMAIN" "${DOMAIN}.crt" "${DOMAIN}.key" \
  --provisioner "$PROVISIONER" \
  --ca-url "$CA_URL" \
  --root "$ROOT_CERT" \
  --password-file /home/step/secrets/ca-password

echo ""
print_header "Certificate Issued Successfully"
echo ""
echo "Files created:"
echo "  - ${DOMAIN}.crt (Certificate)"
echo "  - ${DOMAIN}.key (Private key)"
echo ""
echo "Certificate details:"
print_subheader ""

step certificate inspect "${DOMAIN}.crt"

echo ""
print_header ""
echo "The certificate was signed using the intermediate CA key"
echo "stored in GCP Cloud KMS, demonstrating successful KMS"
echo "integration."
print_header ""
