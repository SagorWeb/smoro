# Sendmoro — Privacy & Optional Services Notice

Sendmoro is **self-hosted software**. By default, all email, contacts, calendars, notes, Cloud Drive files, Office documents (WebAssembly Docs & Sheets), search indexes, and credentials stay exclusively on infrastructure operated by the server administrator ("Operator"). Sendmoro does not operate a hosted cloud mail service, run analytics trackers, or collect user telemetry.

This notice discloses every optional external endpoint and privacy-sensitive feature Sendmoro supports, together with how Operators can configure or disable each one.

---

## 1. Data Controller Responsibility

The organization or individual deploying Sendmoro is the sole **Data Controller** under GDPR, UK GDPR, CCPA/CPRA, and equivalent data protection laws. Operators are responsible for configuring optional features lawfully and documenting any enabled external services in their own privacy notice and Data Processing Agreements (DPAs).

---

## 2. Optional External Services

### 2.1 Web Push Notification Relay (`push.sendmoro.com`) — *Optional / Self-Hostable*
- **Purpose:** Bridges browser/mobile Web Push notifications (`RFC 8291` / `RFC 8292` VAPID) where direct push delivery requires an HTTPS relay edge.
- **Data Transmitted:** Push subscription endpoint, sender-encrypted Web Push ciphertext (RFC 8291), and routing metadata. Payloads are end-to-end encrypted to the recipient's browser keys; the relay cannot read notification content.
- **Operator Control:** Contacted only when a user enables browser push notifications. Operators can self-host the included Cloudflare Worker in [`scripts/cloudflare-push-relay/`](./scripts/cloudflare-push-relay/) via `PUSH_RELAY_URL`, or disable push notifications.

### 2.2 External / Remote AI Providers — *Disabled by Default (Admin Opt-In)*
- **Default Behavior (Local AI):** Disabled by default. In **Local mode** (self-hosted Ollama on `127.0.0.1:11434`), no email text or prompts leave the Operator's server.
- **Remote AI Mode (`ai.remote_enabled = true`):** If an administrator configures a third-party AI API (e.g., OpenAI, Google Gemini, OpenRouter, or a remote OpenAI-compatible host), text submitted to AI Summarize, Compose, Optimize, Smart Reply, or Translate is sent to that configured endpoint.
- **End-User Disclosure:** When Remote AI mode is enabled, Sendmoro displays an in-app notice identifying the external AI host before users invoke AI features.

### 2.3 Public Holiday Calendar Feed (`holiday.sendmoro.com`) — *Optional / Configurable*
- **Purpose:** Fetches public holiday dates (non-PII country/year JSON) when a user subscribes to a country holiday calendar.
- **Operator Control:** Configurable via `holiday.api_url` in Admin Settings (leave blank to disable or point to an internal mirror).

### 2.4 OpenPGP Web Key Directory (WKD) Lookups — *User-Initiated*
- **Purpose:** When a user enables OpenPGP encryption in Compose, Sendmoro queries standard HTTPS WKD endpoints (`/.well-known/openpgpkey/...`) on recipient domains to discover recipient public keys, and optionally publishes the user's own public key on the Operator's server when the user enables WKD publishing.

### 2.5 Anti-Spam & Threat Reputation Lookups (Rspamd / DNSBL / Optional Spamhaus DQS)
- **Purpose:** Standard SMTP/email spam and phishing filtering (DNSBL, URIBL, optional Spamhaus DQS configured locally in `/etc/rspamd/local.d/`).

### 2.6 Software Update Manifest & ACME TLS Certificates
- **Update Checks:** Checks `raw.githubusercontent.com` / `github.com` for signed Sendmoro release manifests (`release.json`). No mailbox or user data is transmitted.
- **ACME TLS Certificates:** Let's Encrypt / ZeroSSL receives only public server domain names for TLS certificate issuance.

---

## 3. Optional Administrator-Controlled Features (Disabled by Default)

- **External Read Receipts (`feature.read_receipts`, default `false`):** Off globally by default (and off per user by default). When enabled by the Operator and requested by a sender in Compose, Sendmoro serves the sender's visible signature image—or adds the site/custom favicon in the email footer when no signature is selected—from the Operator's mail server to record Delivered/Read status (no recipient IP address or device fingerprint is stored). Operators who enable this feature are solely responsible for compliance with local e-privacy and notice/consent laws (e.g., EU ePrivacy Directive, GDPR, UK PECR).
- **Same-Server Read Receipts (`feature.read_receipts_same_server`, default `false`):** Off globally by default. When enabled by the Operator, senders who request a receipt can see Delivered/Read status for emails opened by other mailboxes on the same server without adding a footer image. When both settings are disabled, all read-receipt UI, badges, and tracking are disabled globally.
- **Archive BCC (`mail.archive_bcc`) & Legal Hold:** Optional compliance archival tools disabled by default and configured solely by the Operator.

---

## 4. Built-In End-User Privacy Protections

- **Tracker Blocking & External Image Proxy:** Hidden 1×1 tracking pixels are stripped and remote images in incoming emails are blocked by default; when loaded, remote images are fetched through Sendmoro's SSRF-hardened server-side proxy with per-user cache isolation so external senders do not see the recipient's IP address or User-Agent.
- **GDPR Art. 15/20 Data Portability:** Users can export their full account data (MBOX mailboxes, `.vcf` contacts, `.ics` calendars, notes, Drive files, and settings) via **Settings → Import & Export → Download My Data** (`GET /api/account/export`).
- **GDPR Art. 17 Right to Erasure:** Deleting a mailbox atomically removes user records across database tables, deletes local Maildir/avatar/signature files, and queues remote object-storage blobs for deletion (`storage_deletion_queue`). Append-only administrative security audit entries (`admin_audit`) are retained for the configured compliance window (`audit.retention_days`, default 365 days).
