#!/bin/bash

set -e

PROVISIONER="tutorial-03-oidc"
CA_URL="https://localhost:9000/"
ROOT_CERT="/home/step/certs/root_ca.crt"

# This uses the interactive OIDC flow provided by the 'step' CLI. It will open a browser or show a URL to complete.
step ca certificate localhost localhost.crt localhost.key \
  --provisioner $PROVISIONER \
  --root $ROOT_CERT \
  --ca-url $CA_URL

echo "Certificate written to localhost.crt, key to localhost.key"

step certificate inspect localhost.crt