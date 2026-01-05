#!/bin/bash

set -e

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source common functions
source "$SCRIPT_DIR/common.sh"

# This script initializes a Step CA with GCP Cloud KMS-backed root and intermediate CA keys.
# It requires the following environment variables to be set:
#   - GCP_PROJECT_ID: Your GCP project ID
#   - GCP_LOCATION: The location of your KMS keyring (e.g., global, us-east1)
#   - GCP_KEYRING: The name of your KMS keyring

if ! check_env_vars GCP_PROJECT_ID GCP_KEYRING; then
  echo ""
  echo "Make sure you have:"
  echo "  1. Created a KMS keyring in your GCP project"
  echo "  2. Set up GCP credentials in ./kms/application_default_credentials.json"
  print_env_usage
  exit 1
fi

# Set default value for optional environment variable
GCP_LOCATION="${GCP_LOCATION:-us-west2}"

# Check if credentials file exists
CREDS_FILE="/home/step/gcp-credentials.json"
if ! check_gcp_credentials "$CREDS_FILE"; then
  exit 1
fi

CA_NAME="tutorial-04 CA"
DNS_NAME="localhost"
ADDRESS=":9000"
PROVISIONER="admin"

ROOT_KEY_NAME="step-ca-root-key"
INTERMEDIATE_KEY_NAME="step-ca-intermediate-key"

# Clean up any existing CA files
echo "Cleaning up existing CA files..."
rm -rf /home/step/certs/*
rm -rf /home/step/config/*
rm -rf /home/step/db/*
rm -rf /home/step/secrets/*
print_success "Cleanup complete"
echo ""

# Create secrets directory and generate password
echo "Generating CA password..."
mkdir -p /home/step/secrets
step crypto rand 32 > /home/step/secrets/ca-password
print_success "CA password generated"
echo ""

# KMS configuration
KMS_URI="cloudkms:credentials-file=$CREDS_FILE"

# Key paths in Cloud KMS (without version)
ROOT_KEY_PATH="projects/${GCP_PROJECT_ID}/locations/${GCP_LOCATION}/keyRings/${GCP_KEYRING}/cryptoKeys/${ROOT_KEY_NAME}"
INTERMEDIATE_KEY_PATH="projects/${GCP_PROJECT_ID}/locations/${GCP_LOCATION}/keyRings/${GCP_KEYRING}/cryptoKeys/${INTERMEDIATE_KEY_NAME}"

print_header "Step CA Cloud KMS Initialization"
echo "CA Name: $CA_NAME"
echo "DNS: $DNS_NAME"
echo "Address: $ADDRESS"
echo "Provisioner: $PROVISIONER"
echo ""
echo "GCP Project: $GCP_PROJECT_ID"
echo "KMS Location: $GCP_LOCATION"
echo "KMS Keyring: $GCP_KEYRING"
echo ""
echo "Root Key: $ROOT_KEY_NAME"
echo "Intermediate Key: $INTERMEDIATE_KEY_NAME"
print_header ""
echo ""

# Step 1: Get or create root CA key in Cloud KMS
echo "Step 1: Getting root CA key from Cloud KMS..."

# Try version 1 first (most common case for existing keys)
ROOT_KEY_VERSION="cryptoKeyVersions/1"
ROOT_KEY_URI="${ROOT_KEY_PATH}/${ROOT_KEY_VERSION}"

# Test if the key version exists
set +e  # Temporarily disable exit on error
PLUGIN_OUTPUT=$(step-kms-plugin key --kms "$KMS_URI" "$ROOT_KEY_URI" 2>&1)
PLUGIN_EXIT_CODE=$?
set -e  # Re-enable exit on error

if [[ $PLUGIN_EXIT_CODE -eq 0 ]]; then
  # Key version 1 exists
  print_success "Using existing root key: $ROOT_KEY_URI"
else
  # Version 1 doesn't exist, try to create the key
  echo "  Key doesn't exist (step-kms-plugin error was: $PLUGIN_OUTPUT)"
  echo "  Creating new key..."
  set +e  # Temporarily disable exit on error
  ROOT_KEY_OUTPUT=$(step kms create --json --kms "$KMS_URI" "$ROOT_KEY_PATH" 2>&1)
  ROOT_KEY_EXIT_CODE=$?
  set -e  # Re-enable exit on error

  if [[ $ROOT_KEY_EXIT_CODE -ne 0 ]]; then
    print_error "Error creating root key:"
    echo "$ROOT_KEY_OUTPUT"
    echo ""
    echo "Debug information:"
    echo "  KMS URI: $KMS_URI"
    echo "  Root key path: $ROOT_KEY_PATH"
    echo "  Credentials file: $CREDS_FILE"
    exit 1
  fi

  # Parse the version from the output
  ROOT_KEY_VERSION=$(echo "$ROOT_KEY_OUTPUT" | grep -o 'cryptoKeyVersions/[0-9]*' | head -1)
  if [[ -z "$ROOT_KEY_VERSION" ]]; then
    ROOT_KEY_VERSION="cryptoKeyVersions/1"
  fi
  ROOT_KEY_URI="${ROOT_KEY_PATH}/${ROOT_KEY_VERSION}"
  print_success "Root key created: $ROOT_KEY_URI"
fi
echo ""

# Step 2: Create root CA certificate
echo "Step 2: Creating root CA certificate..."
mkdir -p /home/step/certs

step certificate create \
  --profile root-ca \
  --kms "$KMS_URI" \
  --key "$ROOT_KEY_URI" \
  --no-password --insecure \
  "$CA_NAME Root CA" \
  /home/step/certs/root_ca.crt

print_success "Root certificate created: /home/step/certs/root_ca.crt"
echo ""

# Step 3: Get or create intermediate CA key in Cloud KMS
echo "Step 3: Getting intermediate CA key from Cloud KMS..."

# Try version 1 first (most common case for existing keys)
INTERMEDIATE_KEY_VERSION="cryptoKeyVersions/1"
INTERMEDIATE_KEY_URI="${INTERMEDIATE_KEY_PATH}/${INTERMEDIATE_KEY_VERSION}"

# Test if the key version exists
set +e  # Temporarily disable exit on error
PLUGIN_OUTPUT=$(step-kms-plugin key --kms "$KMS_URI" "$INTERMEDIATE_KEY_URI" 2>&1)
PLUGIN_EXIT_CODE=$?
set -e  # Re-enable exit on error

if [[ $PLUGIN_EXIT_CODE -eq 0 ]]; then
  # Key version 1 exists
  print_success "Using existing intermediate key: $INTERMEDIATE_KEY_URI"
else
  # Version 1 doesn't exist, try to create the key
  echo "  Key doesn't exist (step-kms-plugin error was: $PLUGIN_OUTPUT)"
  echo "  Creating new key..."
  set +e  # Temporarily disable exit on error
  INTERMEDIATE_KEY_OUTPUT=$(step kms create --json --kms "$KMS_URI" "$INTERMEDIATE_KEY_PATH" 2>&1)
  INTERMEDIATE_KEY_EXIT_CODE=$?
  set -e  # Re-enable exit on error

  if [[ $INTERMEDIATE_KEY_EXIT_CODE -ne 0 ]]; then
    print_error "Error creating intermediate key:"
    echo "$INTERMEDIATE_KEY_OUTPUT"
    echo ""
    echo "Debug information:"
    echo "  KMS URI: $KMS_URI"
    echo "  Intermediate key path: $INTERMEDIATE_KEY_PATH"
    echo "  Credentials file: $CREDS_FILE"
    exit 1
  fi

  # Parse the version from the output
  INTERMEDIATE_KEY_VERSION=$(echo "$INTERMEDIATE_KEY_OUTPUT" | grep -o 'cryptoKeyVersions/[0-9]*' | head -1)
  if [[ -z "$INTERMEDIATE_KEY_VERSION" ]]; then
    INTERMEDIATE_KEY_VERSION="cryptoKeyVersions/1"
  fi
  INTERMEDIATE_KEY_URI="${INTERMEDIATE_KEY_PATH}/${INTERMEDIATE_KEY_VERSION}"
  print_success "Intermediate key created: $INTERMEDIATE_KEY_URI"
fi
echo ""

# Step 4: Create intermediate CA certificate signed by root
echo "Step 4: Creating intermediate CA certificate..."
step certificate create \
  --profile intermediate-ca \
  --kms "$KMS_URI" \
  --ca-kms "$KMS_URI" \
  --ca /home/step/certs/root_ca.crt \
  --ca-key "$ROOT_KEY_URI" \
  --key "$INTERMEDIATE_KEY_URI" \
  --no-password --insecure \
  "$CA_NAME Intermediate CA" \
  /home/step/certs/intermediate_ca.crt

print_success "Intermediate certificate created: /home/step/certs/intermediate_ca.crt"
echo ""

# Step 5: Initialize Step CA to create provisioner
echo "Step 5: Initializing Step CA with admin provisioner..."
mkdir -p /home/step/config /home/step/db

# Create a temporary directory for initial CA
TEMP_CA_DIR=$(mktemp -d)

# Run step ca init in the temp directory to generate provisioner
# This will fail at the end (no TTY) but will create the config files we need
(
  export STEPPATH="$TEMP_CA_DIR"
  step ca init \
    --name "$CA_NAME" \
    --dns "$DNS_NAME" \
    --address "$ADDRESS" \
    --provisioner "$PROVISIONER" \
    --password-file /home/step/secrets/ca-password \
    --with-ca-url "https://${DNS_NAME}:9000" 2>&1 || true
) | grep -v "error allocating terminal" | grep -v "open /dev/tty"

#Copy the generated ca.json which has the provisioner
if [[ -f "$TEMP_CA_DIR/config/ca.json" ]]; then
  cp "$TEMP_CA_DIR/config/ca.json" /home/step/config/ca.json
  cp "$TEMP_CA_DIR/config/defaults.json" /home/step/config/defaults.json 2>/dev/null || true
  print_success "CA configuration created"
else
  print_error "Failed to create CA configuration"
  rm -rf "$TEMP_CA_DIR"
  exit 1
fi

# Clean up temp directory
rm -rf "$TEMP_CA_DIR"
echo ""

# Step 6: Update ca.json to use KMS certificates and keys
echo "Step 6: Configuring ca.json to use Cloud KMS..."

# Update ca.json with our KMS-backed certificates and correct paths
jq --arg root_cert "/home/step/certs/root_ca.crt" \
   --arg intermediate_cert "/home/step/certs/intermediate_ca.crt" \
   --arg intermediate_key "${INTERMEDIATE_KEY_URI}" \
   --arg kms_type "cloudkms" \
   --arg kms_uri "${KMS_URI}" \
   --arg db_path "/home/step/db" \
   '.root = $root_cert |
    .crt = $intermediate_cert |
    .key = $intermediate_key |
    .db.dataSource = $db_path |
    .kms = {type: $kms_type, uri: $kms_uri}' \
   /home/step/config/ca.json > /home/step/config/ca.json.tmp && \
   mv /home/step/config/ca.json.tmp /home/step/config/ca.json

print_success "ca.json updated with Cloud KMS configuration"
echo ""

# Step 7: Update defaults.json with correct fingerprint
echo "Step 7: Updating defaults.json..."

# Get the fingerprint of our root certificate
ROOT_FINGERPRINT=$(step certificate fingerprint /home/step/certs/root_ca.crt)

# Update defaults.json with correct root certificate and fingerprint
jq --arg root_cert "/home/step/certs/root_ca.crt" \
   --arg fingerprint "$ROOT_FINGERPRINT" \
   '.root = $root_cert |
    .fingerprint = $fingerprint' \
   /home/step/config/defaults.json > /home/step/config/defaults.json.tmp && \
   mv /home/step/config/defaults.json.tmp /home/step/config/defaults.json

print_success "defaults.json updated"
echo ""

# Step 8: Verify configuration
echo "Step 8: Verifying configuration..."

# Verify the intermediate certificate matches the key
echo "Verifying certificate chain..."
step certificate verify /home/step/certs/intermediate_ca.crt --roots /home/step/certs/root_ca.crt

# Test KMS connection
echo "Testing KMS connection..."
step-kms-plugin key --kms "$KMS_URI" "$INTERMEDIATE_KEY_URI"

print_success "Configuration verified"

echo ""

# Step 9: Display summary
print_header "CA Initialization Complete"
echo ""
echo "Generated files:"
echo "  - /home/step/certs/root_ca.crt (Root certificate)"
echo "  - /home/step/certs/intermediate_ca.crt (Intermediate certificate)"
echo "  - /home/step/config/ca.json (CA configuration)"
echo "  - /home/step/config/defaults.json (Default settings)"
echo "  - /home/step/secrets/ca-password (CA password)"
echo ""
echo "Private keys are stored in Cloud KMS:"
echo "  - Root key: $ROOT_KEY_URI"
echo "  - Intermediate key: $INTERMEDIATE_KEY_URI"
echo ""
echo "Cloud KMS configuration in ca.json:"
echo "  - Type: cloudkms"
echo "  - Credentials: $CREDS_FILE"
echo ""
echo "Next steps:"
echo "  1. Verify Cloud KMS integration: just verify-kms"
echo "  2. Launch the CA: just launch-ca"
echo "  3. Issue a certificate: just issue-cert localhost"
print_header ""
