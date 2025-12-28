#!/bin/bash

set -e

PROVISIONER="tutorial-03-oidc"
CA_URL="https://localhost:9000/"
ROOT_CERT="/home/step/certs/root_ca.crt"

# Use argument or default to the authenticated user's email
# Note: The CN and SANs in the certificate will be determined by the OIDC token claims (email, URI, etc.)
# not by this subject parameter. This is used as the certificate filename prefix.
SUBJECT="${1:-user}"

# This uses the interactive OIDC flow provided by the 'step' CLI. It will open a browser or show a URL to complete.
# The issued certificate will contain the user's identity (email, URI) in the SANs, not arbitrary domain names.
step ca certificate "$SUBJECT" "${SUBJECT}.crt" "${SUBJECT}.key" \
  --provisioner "$PROVISIONER" \
  --root "$ROOT_CERT" \
  --ca-url "$CA_URL"

echo "Certificate written to ${SUBJECT}.crt, key to ${SUBJECT}.key"

step certificate inspect "${SUBJECT}.crt"