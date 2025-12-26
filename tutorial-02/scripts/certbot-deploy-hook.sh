#!/bin/sh
set -eu
# Robust deploy-hook for certbot: create a temporary file without relying on mktemp (busybox may differ),
# then atomically move it into the live directory to trigger inotify moved_to events.
TMP="/tmp/cert.$$.$(date +%s)"
if ! printf 'x' > "$TMP" 2>/dev/null; then
  # fallback: try a simpler name
  TMP="/tmp/cert.$$"
  printf 'x' > "$TMP" 2>/dev/null || true
fi
DEST="/etc/letsencrypt/live/localhost/.certbot-reload-$(date +%s)"
if mv "$TMP" "$DEST" 2>/dev/null; then
  echo "[deploy-hook] moved $TMP -> $DEST"
elif cp "$TMP" "$DEST" 2>/dev/null; then
  echo "[deploy-hook] copied $TMP -> $DEST (mv failed)"
else
  echo "[deploy-hook] failed to move or copy tmp file (non-fatal)" >&2
fi
# Always exit 0 so the deploy-hook does not make Certbot consider the run a failure
exit 0
