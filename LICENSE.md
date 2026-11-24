# Sendmoro Software License Agreement & Terms of Use

**Copyright (c) 2024–2027 Sendmoro (SagorWeb). All Rights Reserved.**  
**Licensor:** Sendmoro / SagorWeb (<https://sendmoro.com>, <legal@sendmoro.com>)

IMPORTANT: READ THIS AGREEMENT CAREFULLY BEFORE DOWNLOADING, INSTALLING, COPYING, OR USING THIS SOFTWARE. BY INSTALLING OR USING SENDMORO ("SOFTWARE"), YOU ("LICENSEE", "CUSTOMER", OR "OPERATOR") AGREE TO BE BOUND BY THESE TERMS. IF YOU DO NOT AGREE, DO NOT INSTALL OR USE THE SOFTWARE.

---

### 1. License Grant & Restrictions

1.1 **Self-Hosted License Grant:** Subject to your compliance with this Agreement, Licensor grants you a worldwide, perpetual, non-exclusive, non-transferable, royalty-free license to download, install, and execute the compiled binary distributions of the Software on servers, virtual machines, cloud instances, or hardware owned, leased, or controlled by you ("Self-Hosted Infrastructure") for personal, internal organizational, or commercial email and collaboration operations, with no per-user licensing fees or mandatory cloud subscription.

1.2 **Restrictions:** Except as expressly permitted by applicable mandatory law or a separate written commercial agreement with Licensor, you shall not:
- Redistribute, sublicense, sell, rent, lease, or offer the Software as a rebranded white-label standalone product;
- Remove, obscure, or alter copyright, attribution, or third-party license notices bundled with the Software (including `THIRD-PARTY-NOTICES.txt` and Office/font license notices);
- Reverse-engineer, decompile, or modify proprietary portions of the Software except to the extent permitted by applicable mandatory law or for open-source third-party components under their respective licenses.

1.3 **Ownership:** Licensor retains all right, title, and interest in and to the Software, trademarks ("Sendmoro"), and documentation, excluding third-party open-source components governed by their respective upstream licenses.

---

### 2. Self-Hosted Model & Role of the Parties

2.1 **On-Premise Software:** Sendmoro is licensed strictly as self-hosted software installed and executed exclusively on infrastructure owned, leased, or controlled by Customer.

2.2 **Independent Operation:** Licensor does not operate, host, control, or monitor Customer's mail servers, networks, domain names, IP addresses, mailboxes, or user accounts.

2.3 **Data Sovereignty & Data Controller Role:** Customer is the sole **Data Controller** and **Service Operator** of its deployment. Licensor has no custody, possession, access, or visibility into Customer's emails, passwords, contacts, files, calendar entries, encryption keys, or database contents. Optional external endpoints (such as the Web Push relay, holiday calendar feed, or administrator-configured third-party AI APIs) are disclosed in [`PRIVACY_AND_SUBPROCESSORS.md`](./PRIVACY_AND_SUBPROCESSORS.md) and may be disabled or self-hosted by Customer.

---

### 3. Disclaimer of Warranties ("AS-IS")

3.1 **EXPRESS DISCLAIMER:** TO THE MAXIMUM EXTENT PERMITTED BY APPLICABLE LAW, THE SOFTWARE IS PROVIDED **"AS IS"** AND **"AS AVAILABLE"**, WITH ALL FAULTS AND WITHOUT WARRANTY OF ANY KIND.

3.2 LICENSOR DISCLAIMS ALL WARRANTIES AND CONDITIONS, WHETHER EXPRESS, IMPLIED, STATUTORY, OR COLLATERAL, INCLUDING THE IMPLIED WARRANTIES OF **MERCHANTABILITY**, **FITNESS FOR A PARTICULAR PURPOSE**, **SATISFACTORY QUALITY**, **QUIET ENJOYMENT**, **TITLE**, AND **NON-INFRINGEMENT**.

3.3 LICENSOR DOES NOT WARRANT THAT:
- THE SOFTWARE WILL OPERATE UNINTERRUPTED, SECURELY, OR ERROR-FREE;
- THE SOFTWARE WILL SATISFY CUSTOMER'S SPECIFIC LEGAL, REGULATORY, OR COMPLIANCE REQUIREMENTS;
- EMAILS SENT THROUGH THE SOFTWARE WILL ACHIEVE INBOX DELIVERABILITY OR AVOID SPAM FILTERING OR IP BLOCKLISTING BY THIRD-PARTY PROVIDERS;
- LOST OR FORGOTTEN USER-MANAGED CRYPTOGRAPHIC KEYS, OPENPGP PASSPHRASES, OR ENCRYPTED VAULT RECOVERY KEYS CAN BE RECOVERED;
- THE SOFTWARE WILL BE IMMUNE FROM SECURITY VULNERABILITIES OR THIRD-PARTY ATTACKS.

3.4 **Mandatory Law:** Nothing in this Agreement excludes or limits any warranty or statutory right that cannot lawfully be excluded or limited under applicable mandatory law.

---

### 4. Limitation of Liability

4.1 **NO INDIRECT OR CONSEQUENTIAL DAMAGES:** TO THE MAXIMUM EXTENT PERMITTED BY APPLICABLE LAW, LICENSOR AND ITS DIRECTORS, EMPLOYEES, AFFILIATES, AND AGENTS SHALL NOT BE LIABLE TO CUSTOMER OR ANY THIRD PARTY FOR ANY INDIRECT, INCIDENTAL, CONSEQUENTIAL, SPECIAL, PUNITIVE, OR EXEMPLARY DAMAGES (INCLUDING LOSS OF PROFITS, BUSINESS INTERRUPTION, DATA LOSS, MESSAGE CORRUPTION, DOWNTIME, SECURITY BREACHES, SERVER COMPROMISE, OR IP REPUTATION DAMAGE) ARISING OUT OF OR RELATED TO THE SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGES.

4.2 **LIABILITY CAP:** TO THE MAXIMUM EXTENT PERMITTED BY APPLICABLE LAW, LICENSOR'S TOTAL AGGREGATE LIABILITY ARISING OUT OF OR RELATED TO THIS AGREEMENT OR THE SOFTWARE SHALL NOT EXCEED THE AMOUNT ACTUALLY PAID BY CUSTOMER TO LICENSOR FOR THE SOFTWARE IN THE TWELVE (12) MONTHS PRECEDING THE CLAIM, OR ONE HUNDRED UNITED STATES DOLLARS (USD $100.00), WHICHEVER IS LESS.

4.3 **Mandatory-Law Carve-Out:** Nothing in this Agreement excludes or limits liability for death or personal injury caused by negligence, fraud, willful misconduct, gross negligence, or any other liability that cannot lawfully be excluded or limited under applicable mandatory law.

---

### 5. Customer Compliance, Optional Features & Acceptable Use

5.1 **Legal Compliance:** Customer agrees to operate its deployment in compliance with all applicable local, national, and international laws, including:
- **Anti-Spam Laws:** US CAN-SPAM Act (15 U.S.C. § 7701 et seq.), Canadian Anti-Spam Legislation (CASL), Australian Spam Act 2003, Singapore Spam Control Act, and UK PECR;
- **Privacy & Data Protection:** EU General Data Protection Regulation (GDPR), EU ePrivacy Directive, UK GDPR and Data Protection Act 2018, California Consumer Privacy Act (CCPA/CPRA), and applicable national data protection and cybersecurity laws;
- **Communications & Interception:** US Electronic Communications Privacy Act (ECPA) and applicable domestic communications laws.

5.2 **Optional Administrator-Controlled Features:** Certain optional capabilities — including **Read Receipts**, **Same-Server Read Receipts**, **Remote AI APIs**, **Archive BCC**, **Legal Hold**, and the **Web Push Relay** — are disabled or operator-configurable by default. Customer is solely responsible for deciding whether to enable or configure any optional feature, establishing a lawful basis, providing required privacy notices or obtaining end-user or recipient consent under applicable law, and keeping restricted features disabled in jurisdictions where their use is prohibited.

5.3 **Prohibited Uses:** Customer shall not use, or permit others to use, the Software to:
- Transmit unsolicited bulk email ("spam"), unlawful commercial solicitations, or deceptive messages;
- Forge or spoof email envelope headers or sender identities;
- Distribute malware, ransomware, phishing kits, or malicious attachments;
- Host, store, or transmit unlawful content, child sexual abuse material (CSAM), or material infringing third-party intellectual property rights;
- Operate an unauthenticated open mail relay or open proxy.

5.4 **Indemnification:** Customer agrees to defend, indemnify, and hold harmless Licensor from and against any claims, liabilities, damages, fines, penalties, costs, and expenses (including reasonable attorneys' fees) arising out of or related to: (a) Customer's deployment, configuration, or operation of the Software, including any optional features enabled by Customer; (b) content, emails, or attachments transmitted or stored on Customer's server; or (c) Customer's violation of applicable law or third-party rights.

---

### 6. Third-Party & Open-Source Components

6.1 The Software incorporates and orchestrates third-party open-source components (including Go and JavaScript libraries, WordCraft and GridCraft WebAssembly office engines under MIT / Apache-2.0, web fonts under SIL OFL 1.1 and Apache-2.0, and system services such as Postfix, Dovecot, Rspamd, PostgreSQL, Valkey, and Nginx). Full attribution and license notices are provided in [`THIRD-PARTY-NOTICES.txt`](./THIRD-PARTY-NOTICES.txt).

6.2 ClamAV, where optionally installed, runs as an independent external system daemon under the GNU General Public License v2 (GPLv2). The Software does not statically or dynamically link to ClamAV libraries.

---

### 7. Law Enforcement & Legal Process Notice

7.1 Because Sendmoro is self-hosted software and Licensor has no custody, access, or decryption keys for Customer infrastructure, **all law enforcement requests, subpoenas, warrants, civil discovery demands, and court orders must be directed exclusively to the Customer operating the relevant server and IP address**. Licensor cannot produce Customer communications data because Licensor does not possess it.

---

### 8. Export Control & Sanctions

8.1 The Software includes standard cryptographic functionality (including AES-256-GCM, TLS 1.3, Argon2id, Ed25519, and OpenPGP Curve25519/RSA) subject to applicable export control laws, including the US Export Administration Regulations (EAR) and equivalent international dual-use regulations.

8.2 Customer represents and warrants that it is not located in, controlled by, or a national or resident of any embargoed or sanctioned jurisdiction, nor listed on any restricted party list maintained by the UN, US, EU, or UK authorities, and will not export or use the Software in violation of applicable export or sanctions laws.

---

### 9. Governing Law & Jurisdiction

9.1 Subject to non-waivable mandatory local laws, this Agreement is governed by and construed in accordance with the laws of the People's Republic of Bangladesh, without regard to conflict-of-law principles, and the courts of Dhaka, Bangladesh shall have exclusive jurisdiction over disputes arising hereunder. The United Nations Convention on Contracts for the International Sale of Goods (CISG) does not apply.

---

### 10. Severability, No Waiver & Entire Agreement

10.1 **Severability:** If any provision of this Agreement is held invalid or unenforceable in any jurisdiction, that provision shall be enforced to the maximum extent permissible and the remaining provisions shall remain in full force and effect.

10.2 **No Waiver:** Failure by Licensor to enforce any right or provision does not constitute a waiver of that right or provision.

10.3 **Entire Agreement:** This Agreement, together with [`PRIVACY_AND_SUBPROCESSORS.md`](./PRIVACY_AND_SUBPROCESSORS.md) and [`THIRD-PARTY-NOTICES.txt`](./THIRD-PARTY-NOTICES.txt), constitutes the entire agreement between Customer and Licensor regarding the self-hosted Software and supersedes prior understandings on the same subject, unless superseded by a separate signed written agreement.
