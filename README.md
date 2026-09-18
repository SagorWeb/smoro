# Sendmoro (SagorWeb Mail Server & Webmail)

Modern, hyper-scalable, high-performance Enterprise Mail Server & Webmail Suite engineered with Go, PostgreSQL 18, Valkey, Postfix, Dovecot, Rspamd, Lego TLS, and React.

---

## 🚀 Quick Install (1-Line Command)

Run this single command on any clean **Ubuntu 22.04 / 24.04 LTS** or **Debian 12** server as root:

```bash
curl -fsSL https://raw.githubusercontent.com/SagorWeb/smoro/main/scripts/install.sh | sudo bash
```

Once executed, open your browser and navigate to:
```
http://YOUR_SERVER_IP:8080
```
Follow the interactive Web Setup Wizard to configure your primary mail domain, administrator credentials, and automated SSL.

---

## ⚡ What Gets Provisioned

1. **Kernel & Network Sysctl Tuning**:
   - Dynamic file descriptor limits (`fs.file-max = 2097152`, `nofile = 1048576`).
   - TCP BBR congestion control, buffer scaling, and backlog optimizations.
2. **PostgreSQL 18 Dynamic Auto-Tuning**:
   - `shared_buffers` dynamically scaled to 25% of server RAM (min 256MB, max 8GB).
   - `effective_cache_size` scaled to 65% of RAM.
   - Dynamic `work_mem`, `maintenance_work_mem`, `max_connections`, and `random_page_cost = 1.1` optimized for NVMe/SSD.
3. **Valkey (High-Performance Redis Alternative)**:
   - Dynamic `maxmemory` capped at 10% of server RAM (max 2GB).
   - `allkeys-lru` memory eviction policy.
4. **Dovecot IMAP / LMTP Engine**:
   - PostgreSQL authentication and quota dictionaries.
   - SSL/TLS IMAP on port 993 & STARTTLS on port 143.
   - High-throughput LMTP delivery on unix socket.
5. **Postfix SMTP Submission Engine**:
   - Ports 25 (SMTP), 587 (Submission STARTTLS), and 465 (SMTPS SSL).
   - Direct Dovecot SASL authentication and PostgreSQL virtual maps.
6. **Rspamd Spam Filtering & DKIM**:
   - Automated 2048-bit DKIM private key and DNS record generation.
   - Bayesian filtering, SPF, and DMARC verification.
7. **Nginx Reverse Proxy & Lego SSL**:
   - Automated ACME TLS certificate issuance via Let's Encrypt or ZeroSSL.
   - HTTP/2 reverse proxy with Server-Sent Events (SSE) live streaming support.
8. **Sendmoro Core Application**:
   - Unified Go daemon (`/opt/sendmoro/bin/sendmoro-linux-amd64`) serving the REST API and embedded responsive React webmail interface.
   - Automated systemd service management (`sendmoro.service`).

---

## 📦 Binary Architecture & Distribution

| Artifact | Description | Target Arch |
|---|---|---|
| `build/sendmoro-installer-linux-amd64.tar.gz` | Web-based visual installer & automated provisioning engine | Linux x86_64 |
| `build/sendmoro-linux-amd64.tar.gz` | Unified Sendmoro application daemon (API + Webmail UI) | Linux x86_64 |
| `build/release.json` | Release manifest containing version tags and SHA-256 integrity hashes | All |
| `scripts/install.sh` | Universal bootstrap script for 1-line installation | Bash / POSIX |

---

## 🛡️ Integrity Verification

All builds are accompanied by cryptographic SHA-256 checksums documented in `build/release.json`. Verify your download integrity using:

```bash
sha256sum -c <(grep -E 'sendmoro' build/release.json | awk -F'"' '{print $4 "  " $2}')
```

---

## 📄 License
Proprietary & Confidential © SagorWeb. All rights reserved.
