#!/bin/bash

set -e

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source common functions
source "$SCRIPT_DIR/common.sh"

# This script creates a GCP service account for step-ca with Cloud KMS access
# and downloads the service account key to gcp-credentials.json (in tutorial-04 root)

# Check required environment variables
if ! check_env_vars GCP_PROJECT_ID GCP_KEYRING; then
  print_env_usage
  exit 1
fi

# Set default value for optional environment variable
GCP_LOCATION="${GCP_LOCATION:-us-west2}"

# Get service account name from argument or generate random one
SA_NAME="$1"
if [[ -z "$SA_NAME" ]]; then
  # Generate random suffix to avoid conflicts
  RANDOM_SUFFIX=$(random_hex 8)
  SA_NAME="step-ca-kms-${RANDOM_SUFFIX}"
  echo "No service account name specified, using: $SA_NAME"
else
  echo "Using specified service account name: $SA_NAME"
fi

SA_EMAIL="${SA_NAME}@${GCP_PROJECT_ID}.iam.gserviceaccount.com"

print_header "GCP Service Account Setup"
echo "Project: $GCP_PROJECT_ID"
echo "Service Account: $SA_NAME"
echo "Email: $SA_EMAIL"
echo "Keyring: $GCP_KEYRING"
echo "Location: $GCP_LOCATION"
print_header ""
echo ""

# Set the active project
echo "Setting active GCP project..."
gcloud config set project "$GCP_PROJECT_ID"
echo ""

# Enable Cloud KMS API if not already enabled
echo "Enabling Cloud KMS API..."
gcloud services enable cloudkms.googleapis.com
print_success "Cloud KMS API enabled"
echo ""

# Ensure KMS keyring exists
if ! ensure_kms_keyring "$GCP_KEYRING" "$GCP_LOCATION" "$GCP_PROJECT_ID"; then
  exit 1
fi
echo ""

# Create service account if it doesn't exist
echo "Creating service account (if it doesn't exist)..."
if gcloud iam service-accounts describe "$SA_EMAIL" &>/dev/null; then
  print_success "Service account '$SA_NAME' already exists"
else
  gcloud iam service-accounts create "$SA_NAME" \
    --display-name="Step CA KMS Service Account"
  print_success "Service account '$SA_NAME' created"
fi
echo ""

# Grant IAM roles at keyring level
echo "Granting IAM roles to service account at keyring level..."

# Cloud KMS Admin (for creating and managing keys)
gcloud kms keyrings add-iam-policy-binding "$GCP_KEYRING" \
  --location="$GCP_LOCATION" \
  --member="serviceAccount:${SA_EMAIL}" \
  --role="roles/cloudkms.admin" \
  >/dev/null 2>&1 || true
print_success "Granted roles/cloudkms.admin"
echo ""

# Check service account key quota
echo "Checking service account key quota..."
KEY_COUNT=$(gcloud iam service-accounts keys list --iam-account="$SA_EMAIL" --format="value(name)" | wc -l)
if [[ $KEY_COUNT -ge 10 ]]; then
  print_error "Service account has reached the maximum number of keys (10)"
  echo ""
  echo "You need to delete old keys before creating a new one."
  echo ""
  echo "List existing keys:"
  echo "  gcloud iam service-accounts keys list --iam-account=\"$SA_EMAIL\""
  echo ""
  echo "Delete a key (replace KEY_ID with an actual key ID from the list):"
  echo "  gcloud iam service-accounts keys delete KEY_ID --iam-account=\"$SA_EMAIL\""
  echo ""
  echo "Or delete the service account and start over:"
  echo "  gcloud iam service-accounts delete \"$SA_EMAIL\""
  exit 1
fi
print_success "Key quota OK ($KEY_COUNT/10 keys used)"
echo ""

# Download service account key
echo "Downloading service account key..."
# Use absolute path to avoid gcloud permission issues
# Save to tutorial-04 root directory (not in secrets/ which gets cleaned up)
CREDS_FILE="$(pwd)/gcp-credentials.json"

if [[ -f "$CREDS_FILE" ]]; then
  print_warning "Credentials file already exists at $CREDS_FILE"
  echo ""
  echo "Choose an option:"
  echo "  1) Overwrite existing file"
  echo "  2) Save as a new file with timestamp suffix"
  echo "  3) Skip credential download"
  read -p "Enter your choice (1-3): " -n 1 -r choice
  echo ""
  echo ""

  case $choice in
    1)
      echo "Overwriting existing credentials file..."
      if ! rm -f "$CREDS_FILE"; then
        print_error "Failed to delete existing credentials file"
        exit 1
      fi
      # Verify file is deleted
      if [[ -f "$CREDS_FILE" ]]; then
        print_error "File still exists after deletion attempt"
        exit 1
      fi
      ;;
    2)
      TIMESTAMP=$(date +%Y%m%d-%H%M%S)
      CREDS_FILE="$(pwd)/gcp-credentials_${TIMESTAMP}.json"
      echo "Saving credentials to new file: $CREDS_FILE"
      ;;
    3)
      echo "Skipping credential download."
      echo ""
      print_header "Setup Complete"
      echo "Service Account: $SA_EMAIL"
      echo "Credentials: $(pwd)/gcp-credentials.json (not modified)"
      echo ""
      echo "Next steps:"
      echo "  1. Build and start the container: just container step-ca"
      echo "  2. Connect to the container: just shell step-ca"
      echo "  3. Initialize the CA: just init-ca"
      print_header ""
      exit 0
      ;;
    *)
      print_error "Invalid choice. Exiting."
      exit 1
      ;;
  esac
fi

# Ensure the target file doesn't exist before creating
if [[ -f "$CREDS_FILE" ]]; then
  print_error "Target credentials file still exists: $CREDS_FILE"
  print_error "Please remove it manually and try again."
  exit 1
fi

# Download service account key using gcloud
# Note: gcloud creates the file atomically and will fail if the file already exists
if gcloud iam service-accounts keys create "$CREDS_FILE" --iam-account="$SA_EMAIL"; then
  chmod 600 "$CREDS_FILE"
  print_success "Service account key downloaded to $CREDS_FILE"
else
  print_error "Failed to create service account key"
  echo "Debug: Check if file exists: $(ls -l "$CREDS_FILE" 2>&1 || echo 'file does not exist')"
  exit 1
fi
echo ""

# Create secrets directory for ca-password (will be created by init-ca)
mkdir -p secrets

# Save service account name for reference
echo "$SA_NAME" > .service-account-name

print_header "Setup Complete"
echo "Service Account: $SA_EMAIL"
echo "Credentials: $CREDS_FILE"
echo ""

# Check if a non-standard credentials file was used
STANDARD_CREDS_FILE="$(pwd)/gcp-credentials.json"
if [[ "$CREDS_FILE" != "$STANDARD_CREDS_FILE" ]]; then
  print_warning "You saved credentials to a non-standard file name."
  echo ""
  echo "To use this file, update the file name in compose-step-ca.yml:"
  echo "  Change the volume mount from './gcp-credentials.json' to:"
  echo "  './$(basename "$CREDS_FILE"):/home/step/gcp-credentials.json:ro'"
  echo ""
fi

echo "IMPORTANT: Keep your credentials secure!"
echo "- The credentials file is gitignored"
echo "- Never commit it to version control"
echo "- Rotate the key regularly (GCP recommends every 90 days)"
echo ""
echo "Next steps:"
echo "  1. Build and start the container: just container step-ca"
echo "  2. Connect to the container: just shell step-ca"
echo "  3. Initialize the CA: just init-ca"
print_header ""
