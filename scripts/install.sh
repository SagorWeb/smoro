#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════════════
# Sendmoro — Server Bootstrap & Automated Web Installer
# ═══════════════════════════════════════════════════════════════════════════════
# Single universal command to install on any cloud VPS:
#
#   sudo bash -c 'curl -fsSL https://raw.githubusercontent.com/SagorWeb/sendmoro/main/scripts/install.sh | bash'
# ═══════════════════════════════════════════════════════════════════════════════

set -euo pipefail

REPO_RAW="https://raw.githubusercontent.com/SagorWeb/sendmoro/main"
SCRIPT_URL="${REPO_RAW}/scripts/install.sh"
INSTALLER_PORT="8090"
UNIVERSAL_CMD="sudo bash -c 'curl -fsSL ${SCRIPT_URL} | bash'"

fail() {
  echo ""
  echo "Sendmoro cannot install on this server."
  echo "  $1"
  echo ""
  echo "Required: fresh Ubuntu 22.04 / 24.04 / 26.04 LTS or Debian 11/12, x86_64/arm64,"
  echo "a real KVM/dedicated host with systemd, at least 2 GB RAM, and root (UID 0)."
  echo ""
  echo "Install command:"
  echo "  ${UNIVERSAL_CMD}"
  exit 1
}

is_root() {
  [ "$(id -u)" -eq 0 ]
}

ensure_root() {
  if is_root; then
    return 0
  fi

  local login_name uid
  login_name="$(id -un 2>/dev/null || echo unknown)"
  uid="$(id -u)"

  echo "Logged in as '${login_name}' (UID ${uid})."
  echo "Need real root (UID 0). Account name does not matter."
  echo ""

  if [ "${SENDMORO_INSTALL_ESCALATED:-}" = "1" ]; then
    fail "sudo ran, but this process is still UID ${uid}. This account cannot become root."
  fi

  if ! command -v sudo >/dev/null 2>&1; then
    fail "sudo is not installed. Log in as root, or install sudo, then run: ${UNIVERSAL_CMD}"
  fi

  if sudo -n true 2>/dev/null; then
    echo ">>> Re-running as root via sudo..."
    export SENDMORO_INSTALL_ESCALATED=1
    exec sudo -E bash -c "curl -fsSL '${SCRIPT_URL}' | bash"
  fi

  echo "This account can use sudo. Run this one command (enter your password if asked):"
  echo ""
  echo "  ${UNIVERSAL_CMD}"
  echo ""
  exit 1
}

ensure_supported_server() {
  [ "$(uname -s)" = "Linux" ] || fail "Not Linux ($(uname -s)). Sendmoro requires Linux."

  local arch
  arch="$(uname -m)"
  case "$arch" in
    x86_64|amd64|aarch64|arm64) ;;
    *) fail "Unsupported CPU (${arch}). Need x86_64 or arm64." ;;
  esac

  if [ ! -d /run/systemd/system ] || [ "$(ps -p 1 -o comm= 2>/dev/null || true)" != "systemd" ]; then
    fail "systemd is not PID 1. Need a standard Linux VPS, not a container without systemd."
  fi

  if [ -f /proc/sys/fs/binfmt_misc/WSLInterop ] || grep -qi microsoft /proc/version 2>/dev/null; then
    fail "WSL is not supported. Use a cloud VPS or dedicated server."
  fi

  local ram_mb disk_gb
  ram_mb="$(awk '/^MemTotal:/{print int($2/1024)}' /proc/meminfo 2>/dev/null || echo 0)"
  disk_gb="$(df -B1G --output=size / 2>/dev/null | tail -1 | tr -d ' ' || echo 0)"
  [ "${ram_mb}" -ge 1500 ] || fail "Not enough RAM (${ram_mb} MB). Need at least 2 GB RAM."
  [ "${disk_gb}" -ge 15 ] || fail "Not enough disk (${disk_gb} GB). Need at least 15 GB on /."
}

ensure_root
ensure_supported_server

if [ -f /opt/webmail/bin/webmail-api ] || [ -f /etc/systemd/system/sendmoro-api.service ]; then
  fail "Sendmoro is already installed. Use a clean Ubuntu/Debian server."
fi

PRETTY_NAME=$(cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2 2>/dev/null || echo "Linux")

echo "════════════════════════════════════════════════════════════════"
echo "        Sendmoro — Server Bootstrap"
echo "════════════════════════════════════════════════════════════════"
echo "  User      : $(id -un) (UID $(id -u), root)"
echo "  Target OS : ${PRETTY_NAME}"
echo "  CPU       : $(uname -m)"
echo "  RAM       : $(awk '/^MemTotal:/{print int($2/1024)}' /proc/meminfo 2>/dev/null || echo 2048) MB"
echo "  Date      : $(date -u)"
echo "════════════════════════════════════════════════════════════════"
echo ""
echo "Server checks passed. Host is ready for Sendmoro mail server."
echo ""

export DEBIAN_FRONTEND=noninteractive
echo ">>> Installing prerequisite packages..."
apt-get update -qq >/dev/null 2>&1 || true
apt-get install -y -qq curl tar ca-certificates ufw >/dev/null 2>&1 || true

ufw allow 22/tcp >/dev/null 2>&1 || true
ufw allow 80/tcp >/dev/null 2>&1 || true
ufw allow 443/tcp >/dev/null 2>&1 || true
ufw allow 8090/tcp >/dev/null 2>&1 || true

SERVER_IP=$(curl -s4 https://api.ipify.org 2>/dev/null || curl -s4 https://ifconfig.me 2>/dev/null || hostname -I | awk '{print $1}')
if [ -z "$SERVER_IP" ]; then
  SERVER_IP="YOUR_SERVER_IP"
fi

INSTALLER_URL="${SENDMORO_INSTALLER_URL:-${REPO_RAW}/build/sendmoro-installer-linux-amd64.tar.gz}"
MANIFEST_URL="${SENDMORO_MANIFEST_URL:-${REPO_RAW}/build/release.json}"

WORKDIR=/tmp/sendmoro-install-tmp
rm -rf "$WORKDIR"
mkdir -p "$WORKDIR"

echo ">>> Fetching Sendmoro web installer..."
if ! curl -fsSL "$INSTALLER_URL" -o "$WORKDIR/installer.tar.gz"; then
  echo "Error: Failed to download installer from $INSTALLER_URL"
  exit 1
fi

if curl -fsSL "$MANIFEST_URL" -o "$WORKDIR/release.json" 2>/dev/null; then
  EXPECTED=$(sed -n '/installer_linux_amd64/,/sha256/s/.*"sha256": *"\([^"]*\)".*/\1/p' "$WORKDIR/release.json" | head -1)
  GOT=$(sha256sum "$WORKDIR/installer.tar.gz" 2>/dev/null | awk '{print $1}' || echo "")
  if [ -n "$EXPECTED" ] && [ -n "$GOT" ] && [ "$EXPECTED" != "$GOT" ]; then
    echo "Error: installer checksum mismatch."
    echo "  expected: $EXPECTED"
    echo "  got:      $GOT"
    exit 1
  fi
fi

tar -xzf "$WORKDIR/installer.tar.gz" -C "$WORKDIR"
if [ -f "$WORKDIR/sendmoro-installer-linux-amd64" ]; then
  cp "$WORKDIR/sendmoro-installer-linux-amd64" /tmp/sendmoro-installer
elif [ -f "$WORKDIR/sendmoro-installer" ]; then
  cp "$WORKDIR/sendmoro-installer" /tmp/sendmoro-installer
else
  find "$WORKDIR" -maxdepth 2 -type f -perm -111 -exec cp {} /tmp/sendmoro-installer \;
fi
chmod +x /tmp/sendmoro-installer
rm -rf "$WORKDIR"

pkill -f sendmoro-installer 2>/dev/null || true
nohup /tmp/sendmoro-installer > /tmp/sendmoro-installer.log 2>&1 &
sleep 2

echo ""
echo "════════════════════════════════════════════════════════════════"
echo "  Sendmoro web installer is running"
echo "════════════════════════════════════════════════════════════════"
echo ""
echo "  Open your browser to complete setup:"
echo ""
echo "      http://${SERVER_IP}:${INSTALLER_PORT}"
echo ""
echo "════════════════════════════════════════════════════════════════"
