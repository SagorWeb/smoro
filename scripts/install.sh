#!/bin/bash
# Sendmoro server bootstrap: downloads the checksum-verified web installer and
# starts it. Run on a fresh Ubuntu 26.04 LTS (x86_64) server:
#
#   sudo bash -c 'curl -fsSL https://raw.githubusercontent.com/SagorWeb/smoro/main/scripts/install.sh | bash'
#
# All work happens inside main(), so a partly downloaded script runs nothing.

set -euo pipefail

readonly SCRIPT_URL="https://raw.githubusercontent.com/SagorWeb/smoro/main/scripts/install.sh"
readonly RELEASES="https://github.com/SagorWeb/smoro/releases"
readonly ASSET="sendmoro-installer-linux-amd64"
readonly UNIT="sendmoro-installer"
readonly BIN="/usr/local/sbin/sendmoro-installer"
readonly PORT="8090"
readonly INSTALL_CMD="sudo bash -c 'curl -fsSL ${SCRIPT_URL} | bash'"
TMP_DIR=""

fail() {
  printf '\nSendmoro cannot install on this server.\n  %s\n\nInstall command:\n  %s\n' "$1" "$INSTALL_CMD" >&2
  exit 1
}

fetch() {
  curl --proto '=https' --tlsv1.2 -fsSL --retry 3 --retry-all-errors \
    --connect-timeout 15 --max-time 300 -o "$2" "$1"
}

become_root() {
  if [ "$(id -u)" -eq 0 ]; then
    return
  fi
  if [ "${1:-}" = "--as-root" ]; then
    fail "sudo ran, but this account is still not root (UID 0)."
  fi
  if command -v sudo >/dev/null 2>&1 && sudo -n true 2>/dev/null; then
    exec sudo bash -c "curl --proto =https -fsSL '${SCRIPT_URL}' | bash -s -- --as-root"
  fi
  fail "Root access is required. Run the install command below as root or with sudo."
}

# The installer prints its link, with a one-time key, when it starts.
print_url() {
  local run url
  run=$(systemctl show -p InvocationID --value "$UNIT" 2>/dev/null) || true
  [ -n "$run" ] || return 1
  url=$(journalctl _SYSTEMD_INVOCATION_ID="$run" -o cat --no-pager 2>/dev/null |
    sed -n 's/.*Open: \(http[^ ]*\).*/\1/p' | tail -n 1) || true
  [ -n "$url" ] || return 1
  printf '\nThe Sendmoro installer is running. Open this link in your browser:\n\n    %s\n\n' "$url"
  echo "The link includes a one-time key, so keep it private."
  echo "If the page does not load, allow TCP port ${PORT} in your hosting provider's firewall."
}

main() {
  become_root "$@"

  [ "$(uname -m)" = "x86_64" ] || fail "Unsupported CPU ($(uname -m)). Sendmoro needs an x86_64 server."
  [ "$(ps -p 1 -o comm= 2>/dev/null)" = "systemd" ] || fail "systemd is not PID 1. Use a normal VPS or dedicated server."
  if [ -e /opt/webmail/bin/webmail-api ] || [ -e /etc/systemd/system/sendmoro-api.service ]; then
    fail "Sendmoro is already installed on this server."
  fi
  if systemctl is-active --quiet "$UNIT"; then
    print_url || echo "The Sendmoro installer is already running. Show its link with: journalctl -u ${UNIT} -o cat | grep Open"
    return
  fi

  TMP_DIR=$(mktemp -d)
  trap 'rm -rf "$TMP_DIR"' EXIT

  echo ">>> Downloading the Sendmoro installer..."
  fetch "${RELEASES}/latest/download/release.json" "$TMP_DIR/release.json" ||
    fail "Could not download the release manifest from GitHub."
  local url sha
  url=$(sed -n "s|.*\"\(${RELEASES}/download/[^\"/]*/${ASSET}\.tar\.gz\)\".*|\1|p" "$TMP_DIR/release.json")
  sha=$(sed -n "s|.*\"${ASSET}\.tar\.gz\": *\"\([0-9a-f]\{64\}\)\".*|\1|p" "$TMP_DIR/release.json")
  if [ -z "$url" ] || [ -z "$sha" ]; then
    fail "The release manifest has no installer download or checksum."
  fi
  fetch "$url" "$TMP_DIR/installer.tar.gz" || fail "Could not download the installer from GitHub."
  echo "${sha}  ${TMP_DIR}/installer.tar.gz" | sha256sum --check --status ||
    fail "The installer download failed its SHA-256 check."
  tar -xzf "$TMP_DIR/installer.tar.gz" -C "$TMP_DIR" "$ASSET" || fail "The installer archive is damaged."
  install -m 0755 "$TMP_DIR/$ASSET" "$BIN"

  # The installer opens every port when it enables UFW at the end. If UFW is
  # already on, open the installer page and the Let's Encrypt check now.
  if command -v ufw >/dev/null 2>&1 && ufw status 2>/dev/null | grep -q '^Status: active'; then
    local p
    for p in "$PORT" 80; do
      ufw allow "${p}/tcp" >/dev/null || fail "Could not open port ${p} in UFW."
    done
  fi

  local since
  since=$(date +%s)
  systemd-run --quiet --collect --unit="$UNIT" --setenv=HOME=/root "$BIN" ||
    fail "Could not start the installer service."

  local _
  for _ in $(seq 30); do
    if curl -fs -o /dev/null --max-time 2 "http://127.0.0.1:${PORT}/" && print_url; then
      return
    fi
    systemctl is-active --quiet "$UNIT" || break
    sleep 1
  done
  journalctl -u "$UNIT" --since "@${since}" -o cat --no-pager 2>/dev/null | tail -n 25 >&2 || true
  fail "The installer did not start. Its log is shown above."
}

main "$@"
