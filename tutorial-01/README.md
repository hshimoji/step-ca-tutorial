# tutorial-01: Step CA Tutorial

This tutorial demonstrates how to set up Smallstep Certificate Authority (step-ca) using Docker, including CA initialization, certificate issuance, and CA startup.

## Prerequisites

- Docker and Docker Compose installed

## Setup

### 1. Start the Container

```bash
docker-compose up -d
```

### 2. Connect to the Container

```bash
docker exec -it tu01-step-ca bash
```

## Tutorial Steps

### Step 1: Initialize the CA

Run the following inside the container:

```bash
scripts/init-ca.sh
```

When prompted, press Enter to auto-generate a password.

**Generated Files:**
- `/home/step/certs/root_ca.crt` - Root certificate
- `/home/step/certs/intermediate_ca.crt` - Intermediate certificate
- `/home/step/secrets/root_ca_key` - Root private key
- `/home/step/secrets/intermediate_ca_key` - Intermediate private key
- `/home/step/config/ca.json` - CA configuration file
- `/home/step/config/defaults.json` - Default configuration file

### Step 2: Issue a Certificate

With the CA running, execute the following inside the container:

```bash
scripts/issue-cert.sh
```

When prompted, enter the provisioner password.

**Generated Files:**
- `localhost.crt` - Client certificate
- `localhost.key` - Client private key

### Step 3: Start the CA

Run the following inside the container:

```bash
scripts/launch-ca.sh
```

When prompted, enter the password for the intermediate CA private key.

The CA will start listening on HTTPS port 9000.

## Directory Structure

```
tutorial-01/
├── compose.yml          # Docker Compose configuration file
├── scripts/
│   ├── init-ca.sh      # CA initialization script
│   ├── issue-cert.sh   # Certificate issuance script
│   └── launch-ca.sh    # CA startup script
├── certs/              # Certificate directory
├── config/             # CA configuration directory
├── data/               # Data directory
└── db/                 # Database directory
```

## Troubleshooting

### Set Directory Permissions on Host

On the first run, you may need to set permissions on the host:

```bash
sudo chown -R 1000:1000 certs/ config/ data/ db/
```

### Set Script Execution Permissions on Host

```bash
chmod +x scripts/*.sh
```

## CA Configuration

- **CA Name**: tutorial-01 CA
- **DNS**: localhost
- **Listen Address**: :9000 (HTTPS)
- **Deployment Type**: Standalone
- **Default Provisioner**: admin

## References

- [Smallstep Certificates Documentation](https://smallstep.com/docs/certificates/)
- [Step CLI Reference](https://smallstep.com/docs/step-cli/)
