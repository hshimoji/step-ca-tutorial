step-ca-tutorial — Learning Private CAs with Smallstep

Overview

This repository is a hands-on tutorial collection for learning how to build and operate a private Certificate Authority (CA) with Smallstep (step-ca). Each tutorial demonstrates a specific CA configuration and certificate issuance workflow so you can step through real, practical examples from basic to advanced.

Repository layout

- [tutorial-01](tutorial-01)  — Basic CA using the default `admin` (JWK) provisioner and issuing a server certificate.
- [tutorial-02](tutorial-02)  — ACME provisioner: learn ACME basics and use an ACME client (certbot) to obtain a server certificate.
- [tutorial-03](tutorial-03)  — OIDC provisioner: obtain certificates using Google Workspace accounts via OIDC.
- [tutorial-04](tutorial-04)  — KMS-managed keys: store and use root/intermediate CA private keys in Google Cloud KMS.

What you will learn

- How to initialize a Smallstep CA and persist its configuration and PKI.
- How Smallstep provisioners work (JWK, ACME, OIDC) and when to use each.
- How to issue TLS certificates for servers and clients with the `step` CLI.
- Best-practice considerations for private CA key management, including using a cloud KMS for production key protection.

Tutorial summaries

- tutorial-01 — Basic CA (admin / JWK)
  - Goal: Build the simplest functional private CA using the default `admin` provisioner (JWK). Initialize a CA, start it, and issue a server certificate for `localhost`.
  - Good for: learning step-ca commands, local testing, and understanding generated files (root/intermediate certs, secrets, config, DB).

- tutorial-02 — ACME provisioner + certbot
  - Goal: Configure an ACME provisioner on step-ca and use an ACME client (certbot) to request and renew certificates via the ACME protocol.
  - Good for: understanding ACME flows, integrating existing ACME clients, and automated certificate issuance/renewal.

- tutorial-03 — OIDC provisioner (Google Workspace)
  - Goal: Configure an OIDC provisioner backed by Google Workspace (or other OIDC providers) so identities from your org can request certificates.
  - Good for: teams that want certificate issuance tied to identity providers and single-sign on.

- tutorial-04 — Cloud KMS key management
  - Goal: Protect root and intermediate private keys using Google Cloud KMS. Learn how to configure step-ca to use KMS-backed keys instead of locally stored private keys.
  - Good for: production deployments requiring strong key protection and centralized key management.

Prerequisites (general)

- Docker and Docker Compose (for containerized examples)
- `step` CLI (installed inside containers used in tutorials) — most example scripts assume the official `smallstep/step-ca` image
- For tutorial-02: an ACME client such as `certbot` and DNS or HTTP validation configured for your domain
- For tutorial-03: a Google Workspace account and ability to create/configure an OIDC client (or another OIDC provider)
- For tutorial-04: a GCP project and permissions to create/use Cloud KMS keys; `gcloud` configured for the target project

Security notes

- The examples are designed for learning and local testing. For production, follow Smallstep guidance on key protection, TLS configuration, network exposure, and monitoring.
- Avoid committing private keys or secrets to source control. Use KMS or other secret managers for production secrets.

Getting started

1. Choose a tutorial folder (e.g. `tutorial-01`) and read its `README.md` (or follow the example scripts).
2. Follow the prerequisites listed above for that tutorial (Docker, certbot, gcloud, etc.).
3. Run the provided `docker-compose` and scripts inside the container as instructed in each tutorial.

Contributing

Contributions, corrections, and improvements are welcome. Please open issues or pull requests against the `tutorial-` branch structure if you want to add new scenarios or fix instructions.

References

- Smallstep Certificates Documentation: https://smallstep.com/docs/certificates/
- Step CLI Reference: https://smallstep.com/docs/step-cli/
- Smallstep GitHub: https://github.com/smallstep/certificates
