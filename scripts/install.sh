#!/bin/bash
# Sendmoro server bootstrap: downloads the checksum-verified installer and
# either starts the web wizard on port 8090 or runs a full unattended setup.
#
# Mode 1 — Interactive Browser Setup Wizard:
#   curl -fsSL https://raw.githubusercontent.com/SagorWeb/smoro/main/scripts/install.sh | sudo bash
#
# Mode 2 — One-Line Automated / Marketplace Setup:
#   curl -fsSL https://raw.githubusercontent.com/SagorWeb/smoro/main/scripts/install.sh | sudo bash -s -- \
#     --hostname mail.yourdomain.com \
#     --email admin@yourdomain.com \
#     --password 'YourStrongPassword123!'
#
# All work happens inside main(), so a partly downloaded script runs nothing.

set -euo pipefail

readonly SCRIPT_URL="https://raw.githubusercontent.com/SagorWeb/smoro/main/scripts/install.sh"
readonly RELEASES="https://github.com/SagorWeb/smoro/releases"
readonly ASSET="sendmoro-installer-linux-amd64"
readonly UNIT="sendmoro-installer"
readonly BIN="/usr/local/sbin/sendmoro-installer"
readonly TOKEN_FILE="/opt/webmail/.install_token"
readonly PORT="8090"
readonly INSTALL_CMD="curl -fsSL ${SCRIPT_URL} | sudo bash"
TMP_DIR=""
AUTO_HOSTNAME="${SENDMORO_HOSTNAME:-}"
AUTO_EMAIL="${ADMIN_EMAIL:-}"
AUTO_PASSWORD="${ADMIN_PASSWORD:-}"

fail() {
  printf '\nSendmoro cannot install on this server.\n  %s\n\nInstall command:\n  %s\n' "$1" "$INSTALL_CMD" >&2
  exit 1
}

fetch() {
  curl --proto '=https' --tlsv1.2 -fsSL --retry 3 --retry-all-errors \
    --connect-timeout 15 --max-time 300 -o "$2" "$1"
}

parse_args() {
  while [ $# -gt 0 ]; do
    case "$1" in
      --as-root)
        shift
        ;;
      --hostname|-h)
        [ $# -ge 2 ] || fail "Missing value for $1 (e.g. --hostname mail.yourdomain.com)"
        AUTO_HOSTNAME="$2"
        shift 2
        ;;
      --hostname=*)
        AUTO_HOSTNAME="${1#*=}"
        shift
        ;;
      --email|--admin-email|-e)
        [ $# -ge 2 ] || fail "Missing value for $1 (e.g. --email admin@yourdomain.com)"
        AUTO_EMAIL="$2"
        shift 2
        ;;
      --email=*|--admin-email=*)
        AUTO_EMAIL="${1#*=}"
        shift
        ;;
      --password|--admin-password|-p)
        [ $# -ge 2 ] || fail "Missing value for $1 (e.g. --password 'YourStrongPassword')"
        AUTO_PASSWORD="$2"
        shift 2
        ;;
      --password=*|--admin-password=*)
        AUTO_PASSWORD="${1#*=}"
        shift
        ;;
      *)
        fail "Unknown argument: $1"
        ;;
    esac
  done

  if [ -n "$AUTO_HOSTNAME" ] || [ -n "$AUTO_EMAIL" ] || [ -n "$AUTO_PASSWORD" ]; then
    if [ -z "$AUTO_HOSTNAME" ] || [ -z "$AUTO_EMAIL" ] || [ -z "$AUTO_PASSWORD" ]; then
      fail "For one-line automated setup, provide all three: --hostname <fqdn> --email <admin-email> --password <password>"
    fi
  fi
}

become_root() {
  if [ "$(id -u)" -eq 0 ]; then
    return
  fi
  for arg in "$@"; do
    if [ "$arg" = "--as-root" ]; then
      fail "sudo ran, but this account is still not root (UID 0)."
    fi
  done
  if command -v sudo >/dev/null 2>&1 && sudo -n true 2>/dev/null; then
    exec sudo -E bash -c 'curl --proto =https -fsSL "$1" | bash -s -- --as-root "${@:2}"' _ "$SCRIPT_URL" "$@"
  fi
  fail "Root access is required. Run the install command below as root or with sudo."
}

print_url() {
  local run url
  run=$(systemctl show -p InvocationID --value "$UNIT" 2>/dev/null) || true
  [ -n "$run" ] || return 1
  url=$(journalctl _SYSTEMD_INVOCATION_ID="$run" -o cat --no-pager 2>/dev/null |
    sed -n 's/.*Open: \(https\{0,1\}:\/\/[^ ]*\).*/\1/p' | tail -n 1) || true
  [ -n "$url" ] || return 1
  printf '\nThe Sendmoro installer is running (protected with TLS & one-time setup token).\nOpen this link in your browser:\n\n    %s\n\n' "$url"
  echo "Note: Accept the temporary self-signed setup certificate warning in your browser."
  echo "If the page does not load, allow TCP port ${PORT} in your hosting provider's firewall."
}

installer_token() {
  tr -d ' \r\n' < "$TOKEN_FILE" 2>/dev/null || true
}

run_unattended_install() {
  echo ">>> Starting unattended Sendmoro setup for ${AUTO_HOSTNAME} (${AUTO_EMAIL})..."
  local resp http_code body tok payload_file
  tok="$(installer_token)"
  [ -n "$tok" ] || fail "Installer setup token is missing at ${TOKEN_FILE}."

  payload_file="$(mktemp "${TMP_DIR:-/tmp}/sendmoro-install-XXXXXX")"
  chmod 0600 "$payload_file"
  python3 -c 'import json,sys; print(json.dumps({"hostname":sys.argv[1],"admin_email":sys.argv[2],"admin_password":sys.argv[3]}))' \
    "$AUTO_HOSTNAME" "$AUTO_EMAIL" "$AUTO_PASSWORD" > "$payload_file" 2>/dev/null || {
    local esc_host esc_email esc_pass
    esc_host=$(printf '%s' "$AUTO_HOSTNAME" | sed 's/\\/\\\\/g; s/"/\\"/g')
    esc_email=$(printf '%s' "$AUTO_EMAIL" | sed 's/\\/\\\\/g; s/"/\\"/g')
    esc_pass=$(printf '%s' "$AUTO_PASSWORD" | sed 's/\\/\\\\/g; s/"/\\"/g')
    printf '{"hostname":"%s","admin_email":"%s","admin_password":"%s"}\n' "$esc_host" "$esc_email" "$esc_pass" > "$payload_file"
  }

  resp=$(curl -skS -w $'\n%{http_code}' -X POST "https://127.0.0.1:${PORT}/api/install" \
    -H "Content-Type: application/json" \
    -H "X-Setup-Token: ${tok}" \
    --data-binary @"$payload_file") || { rm -f "$payload_file"; fail "Could not reach local installer on port ${PORT}."; }
  rm -f "$payload_file"

  http_code=$(printf '%s\n' "$resp" | tail -n 1)
  body=$(printf '%s\n' "$resp" | sed '$d')
  if [ "$http_code" != "200" ]; then
    fail "Installer rejected configuration (HTTP ${http_code}): ${body}"
  fi

  local last_msg="" state status pct title log_line ssl_ready proto
  while true; do
    state=$(curl -fskS -H "X-Setup-Token: ${tok}" "https://127.0.0.1:${PORT}/api/status") || fail "Lost connection to local installer."
    status=$(printf '%s\n' "$state" | grep -o '"status":"[^"]*"' | head -n 1 | cut -d'"' -f4)
    pct=$(printf '%s\n' "$state" | grep -o '"percent":[0-9]*' | head -n 1 | cut -d: -f2)
    title=$(printf '%s\n' "$state" | grep -o '"title":"[^"]*"' | head -n 1 | cut -d'"' -f4)
    log_line=$(printf '%s\n' "$state" | grep -o '"log":"[^"]*"' | head -n 1 | cut -d'"' -f4)

    if [ -n "$log_line" ] && [ "${pct}:${log_line}" != "$last_msg" ]; then
      printf '[%3s%%] %s — %s\n' "${pct:-0}" "$title" "$log_line"
      last_msg="${pct}:${log_line}"
    fi

    if [ "$status" = "complete" ]; then
      ssl_ready=$(printf '%s\n' "$state" | grep -o '"ssl_ready":[a-z]*' | head -n 1 | cut -d: -f2)
      curl -fskS -X POST -H "X-Setup-Token: ${tok}" "https://127.0.0.1:${PORT}/api/delete" >/dev/null 2>&1 || true
      proto="https://"
      [ "$ssl_ready" = "true" ] || proto="http://"
      printf '\n✓ Sendmoro installation 100%% complete!\n'
      printf '  Webmail URL:     %s%s\n' "$proto" "$AUTO_HOSTNAME"
      printf '  Admin Dashboard: %s%s/admin\n' "$proto" "$AUTO_HOSTNAME"
      printf '  Admin Email:     %s\n\n' "$AUTO_EMAIL"
      return 0
    fi

    if [ "$status" = "error" ]; then
      fail "Provisioning failed at ${title}: ${log_line}"
    fi

    sleep 2
  done
}

main() {
  become_root "$@"
  parse_args "$@"

  [ "$(uname -m)" = "x86_64" ] || fail "Unsupported CPU ($(uname -m)). Sendmoro needs an x86_64 server."
  [ "$(ps -p 1 -o comm= 2>/dev/null)" = "systemd" ] || fail "systemd is not PID 1. Use a normal VPS or dedicated server."
  if [ -e /opt/webmail/bin/webmail-api ] || [ -e /etc/systemd/system/sendmoro-api.service ]; then
    fail "Sendmoro is already installed on this server."
  fi

  if systemctl is-active --quiet "$UNIT"; then
    if [ -n "$AUTO_HOSTNAME" ]; then
      run_unattended_install
      return
    fi
    print_url || echo "The Sendmoro installer is already running at https://$(hostname -I | awk '{print $1}'):${PORT}/?token=$(installer_token)"
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
  # already on, open port 80 (for Let's Encrypt) and port 8090 only in interactive mode.
  if command -v ufw >/dev/null 2>&1 && ufw status 2>/dev/null | grep -q '^Status: active'; then
    ufw allow 80/tcp >/dev/null || fail "Could not open port 80 in UFW."
    if [ -z "$AUTO_HOSTNAME" ]; then
      ufw allow "${PORT}/tcp" >/dev/null || fail "Could not open port ${PORT} in UFW."
    fi
  fi

  local since bind_env=""
  since=$(date +%s)
  if [ -n "$AUTO_HOSTNAME" ]; then
    bind_env="--setenv=BIND_ADDR=127.0.0.1"
  fi
  # shellcheck disable=SC2086
  systemd-run --quiet --collect --unit="$UNIT" --setenv=HOME=/root $bind_env "$BIN" ||
    fail "Could not start the installer service."

  local _ tok
  for _ in $(seq 30); do
    tok="$(installer_token)"
    if [ -n "$tok" ] && curl -fsk -o /dev/null --max-time 2 -H "X-Setup-Token: ${tok}" "https://127.0.0.1:${PORT}/"; then
      if [ -n "$AUTO_HOSTNAME" ]; then
        run_unattended_install
        return
      fi
      if print_url; then
        return
      fi
    fi
    systemctl is-active --quiet "$UNIT" || break
    sleep 1
  done
  journalctl -u "$UNIT" --since "@${since}" -o cat --no-pager 2>/dev/null | tail -n 25 >&2 || true
  fail "The installer did not start. Its log is shown above."
}

main "$@"
