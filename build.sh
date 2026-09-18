#!/usr/bin/env bash
# =============================================================================
# Sendmoro / Binary Build & Release Packaging Script
# =============================================================================
# Compiles both:
#   1. Sendmoro Webmail Backend (sendmoro-linux-amd64)
#   2. Sendmoro Server Installer (sendmoro-installer-linux-amd64)
# Packages them into .tar.gz archives, computes SHA-256 checksums, and
# updates github/build/release.json.
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
BUILD_DIR="${SCRIPT_DIR}/build"

mkdir -p "${BUILD_DIR}"

VERSION="v1.0.0"
BUILD_NUMBER=$(date +%s | tail -c 6)
RELEASE_DATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

echo "╔══════════════════════════════════════════════════════════════════╗"
echo "║          Sendmoro Binary Build & Release Packager                ║"
echo "╠══════════════════════════════════════════════════════════════════╣"
echo "║  Version: ${VERSION} (Build ${BUILD_NUMBER})                     ║"
echo "║  Target:  Linux x86_64 (amd64) Static Binaries                   ║"
echo "╚══════════════════════════════════════════════════════════════════╝"

# 1. Compile Main Application Backend
echo ">>> [1/4] Compiling Sendmoro Webmail API (sendmoro-linux-amd64)..."
(
  cd "${ROOT_DIR}/backend"
  CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build \
    -ldflags="-s -w -X 'github.com/webmail/backend/internal/buildinfo.Version=${VERSION}'" \
    -o "${BUILD_DIR}/sendmoro-linux-amd64" \
    ./cmd/server
)
chmod +x "${BUILD_DIR}/sendmoro-linux-amd64"
echo "    ✓ Compiled: ${BUILD_DIR}/sendmoro-linux-amd64 ($(du -h "${BUILD_DIR}/sendmoro-linux-amd64" | awk '{print $1}'))"

# 2. Package Main Application Archive
echo ">>> [2/4] Packaging sendmoro-linux-amd64.tar.gz..."
(
  cd "${BUILD_DIR}"
  tar -czf "sendmoro-linux-amd64.tar.gz" "sendmoro-linux-amd64"
)
echo "    ✓ Packaged: ${BUILD_DIR}/sendmoro-linux-amd64.tar.gz ($(du -h "${BUILD_DIR}/sendmoro-linux-amd64.tar.gz" | awk '{print $1}'))"

# 3. Compile Installer Binary
echo ">>> [3/4] Compiling Sendmoro Server Installer (sendmoro-installer-linux-amd64)..."
(
  cd "${ROOT_DIR}/sendmoro-installer"
  CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build \
    -ldflags="-s -w" \
    -o "${BUILD_DIR}/sendmoro-installer-linux-amd64" \
    .
)
chmod +x "${BUILD_DIR}/sendmoro-installer-linux-amd64"
echo "    ✓ Compiled: ${BUILD_DIR}/sendmoro-installer-linux-amd64 ($(du -h "${BUILD_DIR}/sendmoro-installer-linux-amd64" | awk '{print $1}'))"

# 4. Package Installer Archive
echo ">>> [4/4] Packaging sendmoro-installer-linux-amd64.tar.gz..."
(
  cd "${BUILD_DIR}"
  tar -czf "sendmoro-installer-linux-amd64.tar.gz" "sendmoro-installer-linux-amd64"
)
echo "    ✓ Packaged: ${BUILD_DIR}/sendmoro-installer-linux-amd64.tar.gz ($(du -h "${BUILD_DIR}/sendmoro-installer-linux-amd64.tar.gz" | awk '{print $1}'))"

# 5. Calculate SHA256 Checksums
calc_sha256() {
  local file="$1"
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$file" | awk '{print $1}'
  elif command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$file" | awk '{print $1}'
  else
    echo "unknown"
  fi
}

APP_SHA256=$(calc_sha256 "${BUILD_DIR}/sendmoro-linux-amd64.tar.gz")
INSTALLER_SHA256=$(calc_sha256 "${BUILD_DIR}/sendmoro-installer-linux-amd64.tar.gz")

# 6. Generate release.json
cat <<EOF > "${BUILD_DIR}/release.json"
{
  "version": "${VERSION}",
  "build_number": ${BUILD_NUMBER},
  "released_at": "${RELEASE_DATE}",
  "min_webmail_version": "${VERSION}",
  "changelog": "https://github.com/SagorWeb/sendmoro/releases/tag/${VERSION}",
  "mandatory": false,
  "download": {
    "linux_amd64": {
      "url": "https://raw.githubusercontent.com/SagorWeb/sendmoro/main/build/sendmoro-linux-amd64.tar.gz",
      "sha256": "${APP_SHA256}"
    },
    "installer_linux_amd64": {
      "url": "https://raw.githubusercontent.com/SagorWeb/sendmoro/main/build/sendmoro-installer-linux-amd64.tar.gz",
      "sha256": "${INSTALLER_SHA256}"
    }
  },
  "sha256": {
    "sendmoro-linux-amd64.tar.gz": "${APP_SHA256}",
    "sendmoro-installer-linux-amd64.tar.gz": "${INSTALLER_SHA256}"
  }
}
EOF

echo ""
echo "══════════════════════════════════════════════════════════════════"
echo "  Build & Packaging Complete!"
echo "══════════════════════════════════════════════════════════════════"
echo "  App Archive:       sendmoro-linux-amd64.tar.gz"
echo "  App SHA256:        ${APP_SHA256}"
echo "  Installer Archive: sendmoro-installer-linux-amd64.tar.gz"
echo "  Installer SHA256:  ${INSTALLER_SHA256}"
echo "  Manifest:          ${BUILD_DIR}/release.json"
echo "══════════════════════════════════════════════════════════════════"
