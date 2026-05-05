#!/usr/bin/env bash
# One-shot installer for herald. Adds the ra-yavuz apt repository, then
# installs herald from it. Idempotent.
#
#   curl -fsSL https://raw.githubusercontent.com/ra-yavuz/herald/main/scripts/get.sh | sudo bash
#
# DISCLAIMER: provided AS IS, no warranty. See README.
set -euo pipefail

REPO_HOST=ra-yavuz.github.io/apt
KEY_URL="https://${REPO_HOST}/pubkey.gpg"
KEYRING=/etc/apt/keyrings/ra-yavuz.gpg
SOURCES_LIST=/etc/apt/sources.list.d/ra-yavuz.list
SOURCE_LINE="deb [arch=amd64,arm64 signed-by=${KEYRING}] https://${REPO_HOST} stable main"
PKG=herald

log()  { printf '[get.sh] %s\n' "$*"; }
fail() { printf '[get.sh] ERROR: %s\n' "$*" >&2; exit 1; }

[ "$(id -u)" -eq 0 ] || fail "must be run as root: sudo bash $0 (or pipe through 'sudo bash')"
command -v apt-get >/dev/null 2>&1 || fail "apt-get not found; this script targets Debian/Ubuntu and derivatives."
command -v curl >/dev/null 2>&1 || { log "curl missing, installing"; DEBIAN_FRONTEND=noninteractive apt-get update -qq; DEBIAN_FRONTEND=noninteractive apt-get install -y curl; }
command -v gpg  >/dev/null 2>&1 || { log "gnupg missing, installing"; DEBIAN_FRONTEND=noninteractive apt-get install -y gnupg; }

log "fetching signing key from $KEY_URL"
install -m 0755 -d /etc/apt/keyrings
TMP_KEY=$(mktemp)
trap 'rm -f "$TMP_KEY"' EXIT
curl -fsSL "$KEY_URL" -o "$TMP_KEY"
gpg --no-default-keyring --keyring "$TMP_KEY" --list-keys >/dev/null 2>&1 || fail "fetched file is not a valid GPG keyring; aborting."
install -m 0644 "$TMP_KEY" "$KEYRING"

log "adding apt source"
echo "$SOURCE_LINE" > "$SOURCES_LIST"
chmod 0644 "$SOURCES_LIST"

log "running apt update"
DEBIAN_FRONTEND=noninteractive apt-get update
log "installing $PKG"
DEBIAN_FRONTEND=noninteractive apt-get install -y "$PKG"

echo
echo "================================================================"
echo "  herald installed. Quick reference:"
echo "================================================================"
echo
echo "  herald                      print today's quote"
echo "  herald status               show what's enabled and when next refresh"
echo "  sudo herald terminal on     enable the terminal greeting"
echo "  sudo herald motd on         enable the login banner (needs update-motd)"
echo "  sudo herald all on          enable both"
echo "  sudo herald set-refresh 24  refresh once a day"
echo "  sudo herald set-prefix \"...\" set a custom prefix above the quote"
echo
echo "  Future upgrades: sudo apt upgrade"
echo "  Full removal:    sudo apt purge herald"
echo
