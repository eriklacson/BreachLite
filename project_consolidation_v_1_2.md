# BreachLite – Project Consolidation (v1.2.0)

> A single-stop reference for the entire repository layout, with file contents bundled below.\
> **Clone‑ready:** Copy each block verbatim into the indicated path, commit, tag, push – done.

---

## 1  Directory tree

```
BreachLite/
├── breachlite.sh                     # Installer script (bash)
├── README.md                         # Landing page
├── LICENSE                           # GPL-3.0 license
├── .gitignore                        # Untracked clutter
├── docs/
│   └── usage.md                      # Extended usage & FAQ
└── .github/
    ├── workflows/
    │   └── lint.yml                  # GitHub Actions CI
    └── ISSUE_TEMPLATE/
        ├── bug_report.yml            # (optional) Bug template
        └── feature_request.yml       # (optional) Feature template
```

---

## 2  File contents

### 2.1  `breachlite.sh`

Key sections:

- **6. Core Red‑Team & Cracking tools** (nmap, Metasploit, Burp, Sliver, ffuf, hashcat, john, hydra, SecLists)
- **7. Threat‑Intel / OSINT tools** (threatfox, IOC Parser, subfinder, gobuster, amass)
- **7.1 Vulnerability scanners** (**Nuclei** + templates, Nikto, **Trivy** (with fallback installer), **Lynis**; optional **httpx/naabu**)
- **9. Aliases** (adds `nucleiupdate`, `vulnscan`, `imgscan`, `hostaudit`, plus `httpprobe`, `fastports`)

*(See the **`breachlite.sh v1.2.0`** canvas for the full script.)*

### 2.2  `README.md`

````markdown
# BreachLite 🚀
*One‑command bootstrap for a lightweight red‑team, threat‑intel, **vulnerability‑management** & password‑cracking workstation.*

## Quick start
```bash
curl -O https://raw.githubusercontent.com/YOURUSER/BreachLite/main/breachlite.sh
sudo bash breachlite.sh
```

### Feature highlights
- 🛠 Offensive: nmap, Metasploit, Burp, **Sliver**, Responder, ffuf
- 🔑 **Cracking:** hashcat, john, hydra + rockyou & SecLists
- 🔎 Intel/OSINT: yara, IOC Parser, threatfox, subfinder, amass, gobuster
- 🧪 **Vulnerability management:** **Nuclei**, Nikto, **Trivy**, **searchsploit**, **Lynis** (plus optional **httpx/naabu**)
- 🐳 Docker + Compose for C2 & payload infra
- 🔌 OpenVPN plugin for instant CTF connectivity
- ⚡ auto‑cpufreq, swap tuning, XFCE‑minimal for battery‑friendly laptops
- 🔐 UFW, Fail2Ban, unattended‑upgrades harden the host

### Vulnerability scan quick start
```bash
nuclei -update-templates
echo https://example.com > targets.txt
nuclei -l targets.txt -severity high,critical -o nuclei-findings.txt
```

## Install from a tagged release
```bash
curl -O https://raw.githubusercontent.com/YOURUSER/BreachLite/v1.2.0/breachlite.sh
sudo bash breachlite.sh
```
````

### 2.3  `docs/usage.md`

Highlights:

- Adds alias table rows for `vulnscan`, `imgscan`, `hostaudit`, `httpprobe`, `fastports`.
- First‑run **Note** about initial Nuclei template size & conservative defaults (`-rl 100 -c 50`).

*(See the **`usage.md (updated)`** canvas for full content.)*

### 2.4  `.gitignore`

```gitignore
*.log
*.swp
*~
.DS_Store
```

### 2.5  `LICENSE` (GPL‑3.0)

Refer to the top‑level `LICENSE` file in the repo with GPL‑3.0 text.

### 2.6  `.github/workflows/lint.yml`

```yaml
name: shell-lint
on: [push, pull_request]
jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: sudo apt-get update && sudo apt-get install -y shellcheck shfmt
      - run: shellcheck breachlite.sh
      - run: shfmt -d -i 2 -ci breachlite.sh
```

---

## 3  Release workflow (TL;DR)

```bash
# one‑time
chmod +x breachlite.sh

# commit everything
git add .
git commit -m "feat: BreachLite v1.2.0 — add Nuclei + vuln‑management"
git tag v1.2.0
git push -u origin main --tags
# create GitHub Release from tag v1.2.0
```

**Stable install one‑liner**

```bash
curl -O https://raw.githubusercontent.com/YOURUSER/BreachLite/v1.2.0/breachlite.sh && sudo bash breachlite.sh
```

---

📦  *BreachLite project is now fully consolidated—happy hacking!*

