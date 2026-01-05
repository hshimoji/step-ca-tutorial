# step-ca-tutorial — Learning Private CAs with Smallstep

## Overview

This repository is a hands-on tutorial collection for learning how to build and operate a private Certificate Authority (CA) with Smallstep (step-ca). Each tutorial demonstrates a specific CA configuration and certificate issuance workflow so you can step through real, practical examples from basic to advanced.

All tutorials use the [`just`](https://github.com/casey/just) command runner for consistent task execution and include detailed architecture diagrams and sequence diagrams to help you understand the workflows.

## Repository layout

- [tutorial-01](tutorial-01/) — Basic CA using the default `admin` (JWK) provisioner and issuing server certificates.
- [tutorial-02](tutorial-02/) — ACME provisioner with certbot and nginx using HTTP-01 challenge for automated certificate management.
- [tutorial-03](tutorial-03/) — OIDC provisioner: obtain user certificates (client certificates for people) using Google Workspace accounts via OIDC.
- [tutorial-04](tutorial-04/) — KMS-managed keys: store and use root/intermediate CA private keys in Google Cloud KMS for production-grade security.

## What you will learn

- How to initialize a Smallstep CA and persist its configuration and PKI
- How Smallstep provisioners work (JWK, ACME, OIDC) and when to use each
- How to issue TLS certificates for servers and clients with the `step` CLI
- How to automate certificate lifecycle management with ACME and certbot
- How to integrate identity providers (OIDC) for user certificate issuance
- Best-practice considerations for private CA key management, including using a cloud KMS for production key protection

## Tutorial summaries

### tutorial-01 — Basic CA (admin / JWK)

- **Goal**: Build the simplest functional private CA using the default `admin` provisioner (JWK). Initialize a CA, start it, and issue server certificates with automated password management.
- **Good for**: Learning step-ca commands, local testing, and understanding generated files (root/intermediate certs, secrets, config, DB).
- **Key features**: Automated password generation, `just` command runner integration, detailed architecture and sequence diagrams.

### tutorial-02 — ACME provisioner + certbot + nginx

- **Goal**: Configure an ACME provisioner on step-ca and use certbot to request and automatically renew certificates via the ACME protocol with HTTP-01 challenge validation.
- **Good for**: Understanding ACME flows, integrating existing ACME clients, automated certificate issuance/renewal, and setting up production-like certificate management.
- **Key features**: nginx web server with automatic certificate reload, certbot deploy hooks, Let's Encrypt-compatible workflow.

### tutorial-03 — OIDC provisioner (Google Workspace)

- **Goal**: Configure an OIDC provisioner backed by Google Workspace (or other OIDC providers) so identities from your org can request user certificates (client certificates for people).
- **Good for**: Teams that want certificate issuance tied to identity providers and single sign-on. Note: OIDC provisioners issue certificates for people (user/client authentication), not for servers.
- **Key features**: Browser-based OIDC authentication flow, user certificates with email in SAN, integration with corporate identity providers.

### tutorial-04 — Cloud KMS key management

- **Goal**: Protect root and intermediate private keys using Google Cloud KMS. Learn how to configure step-ca to use KMS-backed keys instead of locally stored private keys.
- **Good for**: Production deployments requiring strong key protection, centralized key management, audit logging, and compliance requirements.
- **Key features**: GCP Cloud KMS integration, service account authentication, IAM-based access control, production-grade key security.

## Prerequisites (general)

- Docker and Docker Compose (for containerized examples)
- [`just`](https://github.com/casey/just) command runner installed on the host
- `step` CLI (included inside the `smallstep/step-ca` container image)

### Tutorial-specific prerequisites:

- **tutorial-02**: nginx and certbot containers (defined in compose files)
- **tutorial-03**: A Google Workspace account and ability to create/configure an OIDC client (or another OIDC provider)
- **tutorial-04**: A GCP project with Cloud KMS API enabled, permissions to create/use Cloud KMS keys, and `gcloud` CLI configured for the target project

## Security notes

- The examples are designed for learning and local testing. For production, follow Smallstep guidance on key protection, TLS configuration, network exposure, and monitoring.
- Avoid committing private keys or secrets to source control. Use KMS or other secret managers for production secrets.
- tutorial-04 demonstrates production-grade key management practices suitable for real deployments.

## Getting started

1. Install [`just`](https://github.com/casey/just) on your host machine
2. Choose a tutorial folder (e.g., `tutorial-01`) and read its `README.md`
3. Each tutorial includes:
   - Architecture and sequence diagrams explaining the workflow
   - A `justfile` with all necessary commands
   - Scripts for automated setup and configuration
4. Run `just --list` in any tutorial directory to see available commands
5. Follow the Quick Start section in each tutorial's README

### Example workflow (tutorial-01):

```bash
cd tutorial-01
just container step-ca        # Start the container
just shell step-ca            # Open a shell in the container
just init-ca                  # Initialize the CA (run inside container)
just launch-ca                # Start the CA server (run inside container)
# In another terminal/shell:
just shell step-ca
just issue-cert               # Issue a certificate for localhost
```

## Common `just` commands

Each tutorial provides these common commands (run `just --list` for the full list):

- `just container <name>` — Start the Docker container(s)
- `just shell <name>` — Open a shell in the specified container
- `just cleanup` — Remove all generated artifacts and stop containers
- `just init-ca` — Initialize the CA (tutorial-01, tutorial-03, tutorial-04)
- `just launch-ca` — Start the CA server

Tutorial-specific commands are documented in each tutorial's README.

## Contributing

Contributions, corrections, and improvements are welcome. Please open issues or pull requests if you want to add new scenarios or fix instructions.

## References

- [Smallstep Certificates Documentation](https://smallstep.com/docs/certificates/)
- [Step CLI Reference](https://smallstep.com/docs/step-cli/)
- [Smallstep GitHub](https://github.com/smallstep/certificates)
- [just command runner](https://github.com/casey/just)
