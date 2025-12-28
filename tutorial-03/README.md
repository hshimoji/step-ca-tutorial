# tutorial-03: OIDC provisioner (Google Workspace)

This tutorial demonstrates how to configure Smallstep Certificate Authority (step-ca) to use an OIDC provisioner backed by Google Workspace (or another OIDC provider) so identities from your organization can request certificates.

---

## Goal

- Configure an OIDC provisioner and register it in the CA.
- Use the OIDC provisioner to request a certificate for a user identity that authenticates via Google Workspace.

## Prerequisites

- Docker and Docker Compose installed
- A Google Workspace account (or another OIDC provider) and the ability to create OAuth/OIDC client credentials
- The `step` CLI (available inside the container in this tutorial)

> Note: This tutorial uses interactive steps that require you to create OAuth client credentials (Client ID and Client Secret) for your OIDC provider. The README below provides example commands and placeholders where you should substitute values from your OIDC provider.

---

## Quick start (host -> container mapping)

1. Start the container:

```bash
docker-compose up -d
```

2. Connect to the container:

```bash
docker exec -it tu03-step-ca bash
```

3. Initialize the CA (inside the container):

```bash
scripts/init-ca.sh
```

4. Launch the CA (inside the container):

```bash
scripts/launch-ca.sh
```

5. Register the OIDC provisioner (inside the container):

- Create OAuth client credentials in Google Cloud Console (or your OIDC provider) as a "Web application".
- Set the redirect URI to `https://localhost:9000/oidc/callback` (or the OIDC callback URI your CA expects).
- Copy `CLIENT_ID` and `CLIENT_SECRET` from the OAuth client you created.

Then run:

```bash
export CLIENT_ID="<your-client-id>"
export CLIENT_SECRET="<your-client-secret>"
scripts/add-oidc-provisioner.sh
```

6. Request a certificate using the OIDC provisioner (inside the container):

```bash
scripts/issue-oidc-cert.sh
```

Follow the interactive flow: your browser will be opened (or a URL displayed) where you authenticate to your OIDC provider (Google Workspace). After successful authentication the `step` CLI will receive the identity token and complete the certificate issuance.

---

## Files and scripts

- `compose.yml` — Docker Compose file to run the step-ca container
- `scripts/init-ca.sh` — initialize the CA
- `scripts/launch-ca.sh` — start the CA
- `scripts/add-oidc-provisioner.sh` — template script to add an OIDC provisioner (requires you to set `CLIENT_ID` and `CLIENT_SECRET`)
- `scripts/issue-oidc-cert.sh` — example script to request a certificate using the OIDC provisioner
- `config/` — directory where CA config will be stored
- `certs/`, `db/` — data directories (persisted on host)

**Make scripts executable on the host if necessary:**

```bash
chmod +x scripts/*.sh
```

---

## Security notes

- Do not commit client secrets or private keys to source control. Store secrets in a secret manager for production workflows.
- This tutorial is intended for learning and local testing only.

---

## Troubleshooting

- If `step ca provisioner list` does not show the OIDC provisioner after adding it, ensure `step-ca` was reloaded (SIGHUP is sent by our scripts) and check the CA server logs.
- If the browser login fails, check that the OAuth client redirect URI matches the one configured in your provider.

---

If you'd like, I can add an automated `just` target for the common flow (start → init → launch → add-provisioner → issue-cert).