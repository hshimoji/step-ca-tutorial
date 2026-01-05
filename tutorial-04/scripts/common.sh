#!/bin/bash

# Common utility functions for tutorial-04 scripts

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Print a section header
print_header() {
  local title="$1"
  echo "============================================================"
  echo "$title"
  echo "============================================================"
}

# Print a subsection header
print_subheader() {
  local title="$1"
  echo "------------------------------------------------------------"
  echo "$title"
  echo "------------------------------------------------------------"
}

# Print success message
print_success() {
  echo "  ✓ $1"
}

# Print error message
print_error() {
  echo "  ✗ $1" >&2
}

# Print warning message
print_warning() {
  echo "  ⚠ $1"
}

# Check if required environment variables are set
check_env_vars() {
  local missing=0
  for var in "$@"; do
    if [[ -z "${!var}" ]]; then
      print_error "Environment variable $var is not set"
      missing=1
    fi
  done

  if [[ $missing -eq 1 ]]; then
    return 1
  fi
  return 0
}

# Print environment variable usage
print_env_usage() {
  echo ""
  echo "Required:"
  echo "  export GCP_PROJECT_ID=my-project"
  echo "  export GCP_KEYRING=step-ca-keyring"
  echo ""
  echo "Optional (with default):"
  echo "  export GCP_LOCATION=us-west2  # default: us-west2"
  echo ""
}

# Check if a file exists
check_file_exists() {
  local file="$1"
  local description="$2"

  if [[ ! -f "$file" ]]; then
    print_error "$description not found at $file"
    return 1
  fi
  return 0
}

# Check if GCP credentials file exists
check_gcp_credentials() {
  local creds_file="${1:-/home/step/kms/application_default_credentials.json}"

  if [[ ! -f "$creds_file" ]]; then
    print_error "GCP credentials file not found at $creds_file"
    echo ""
    echo "Please place your GCP service account credentials at:"
    echo "  $creds_file"
    echo ""
    echo "You can create a service account key with:"
    echo "  gcloud iam service-accounts keys create application_default_credentials.json \\"
    echo "    --iam-account=YOUR_SERVICE_ACCOUNT@PROJECT_ID.iam.gserviceaccount.com"
    return 1
  fi
  return 0
}

# Wait for user confirmation
confirm() {
  local prompt="${1:-Continue?}"
  read -p "$prompt (y/N): " -n 1 -r
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    return 0
  fi
  return 1
}

# Generate random hex string
random_hex() {
  local length="${1:-8}"
  openssl rand -hex "$((length / 2))"
}

# Check if KMS keyring exists, create if it doesn't
ensure_kms_keyring() {
  local keyring="${1:-$GCP_KEYRING}"
  local location="${2:-$GCP_LOCATION}"
  local project="${3:-$GCP_PROJECT_ID}"

  if [[ -z "$keyring" ]] || [[ -z "$location" ]] || [[ -z "$project" ]]; then
    print_error "Missing parameters for ensure_kms_keyring"
    return 1
  fi

  echo "Checking KMS keyring..."
  if gcloud kms keyrings describe "$keyring" --location="$location" --project="$project" &>/dev/null; then
    print_success "Keyring '$keyring' already exists"
  else
    echo "Creating KMS keyring '$keyring'..."
    if gcloud kms keyrings create "$keyring" --location="$location" --project="$project"; then
      print_success "Keyring '$keyring' created"
    else
      print_error "Failed to create keyring '$keyring'"
      return 1
    fi
  fi
  return 0
}
