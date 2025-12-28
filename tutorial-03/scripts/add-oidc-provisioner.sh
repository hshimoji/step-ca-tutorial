#!/bin/bash

set -e

# This script registers an OIDC provisioner in the CA.
# Requires CLIENT_ID and CLIENT_SECRET environment variables to be set.

if [[ -z "$CLIENT_ID" || -z "$CLIENT_SECRET" || -z "$DOMAIN" ]]; then
  echo "Please set CLIENT_ID, CLIENT_SECRET, and DOMAIN environment variables before running this script."
  echo "Example: export CLIENT_ID=abc123; export CLIENT_SECRET=secret; export DOMAIN=exmaple.com"
  exit 1
fi

PROVISIONER_NAME="tutorial-03-oidc"

export STEPPATH=$(pwd)
step ca provisioner add $PROVISIONER_NAME \
  --type OIDC \
  --listen-address ":10000" \
  --client-id "$CLIENT_ID" \
  --client-secret "$CLIENT_SECRET" \
  --configuration-endpoint https://accounts.google.com/.well-known/openid-configuration \
  --ca-url https://localhost:9000 \
  --root ./certs/root_ca.crt \
  --domain $DOMAIN

# If step-ca is running in the same container, reload it
if pgrep step-ca > /dev/null 2>&1 ; then
  kill -1 `pgrep step-ca`
fi

echo "OIDC provisioner '$PROVISIONER_NAME' added. Use 'step ca provisioner list' to verify."