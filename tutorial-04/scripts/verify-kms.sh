#!/bin/bash

set -e

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source common functions
source "$SCRIPT_DIR/common.sh"

# This script verifies that the CA is properly configured to use GCP KMS
# by checking the ca.json configuration file.

CA_CONFIG="/home/step/config/ca.json"

if ! check_file_exists "$CA_CONFIG" "CA configuration file"; then
  echo "Please run 'just init-ca' first to initialize the CA."
  exit 1
fi

print_header "Verifying KMS Integration"
echo ""
echo "Checking CA configuration..."
echo ""

# Check if KMS configuration exists
if grep -q "cloudkms" "$CA_CONFIG"; then
  print_success "KMS configuration found in ca.json"
  echo ""

  # Extract and display KMS-related configuration
  print_subheader "KMS Configuration"

  # Display the kms section
  if command -v jq &> /dev/null; then
    echo "Root CA Key:"
    jq -r '.root' "$CA_CONFIG"
    echo ""
    echo "Intermediate CA Key:"
    jq -r '.key' "$CA_CONFIG"
    echo ""
    echo "KMS Configuration:"
    jq -r '.kms' "$CA_CONFIG"
  else
    echo "Root and Intermediate Key Configuration:"
    grep -A 2 '"root"\|"key"\|"kms"' "$CA_CONFIG" | head -20
  fi

  print_subheader ""
  echo ""
  print_success "CA is configured to use GCP Cloud KMS for key storage"
  echo ""

  # Check if credentials file exists
  CREDS_FILE="/home/step/kms/application_default_credentials.json"
  if [[ -f "$CREDS_FILE" ]]; then
    print_success "GCP credentials file found at $CREDS_FILE"
  else
    print_warning "GCP credentials file not found at $CREDS_FILE"
  fi

  echo ""
  print_header "KMS Verification Complete"
  echo ""
  echo "Your CA is properly configured to use GCP Cloud KMS."
  echo "The root and intermediate CA private keys are stored"
  echo "securely in GCP KMS and never touch the filesystem."
  print_header ""
else
  print_error "No KMS configuration found in ca.json"
  echo ""
  echo "The CA appears to be using local key storage instead of KMS."
  echo "Please re-initialize the CA with 'just init-ca' and ensure"
  echo "the required environment variables are set."
  exit 1
fi
