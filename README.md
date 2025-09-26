# BreachLite 🚀

*One-command bootstrap for a lightweight red-team, threat‑intel, vulnerability‑management, & password‑cracking workstation.*

## Quick start

```bash
curl -O https://raw.githubusercontent.com/eriklacson/BreachLite/main/breachlite.sh
sudo bash breachlite.sh
```
> **Go toolchain:** On Ubuntu 22.04 the bootstrapper pulls the latest Go release from go.dev so ProjectDiscovery tooling builds with a current compiler.
> **Security note:** Trivy is pulled from Ubuntu's archive when available. If the package is missing, the script enables Aqua Security's signed APT repository only after verifying the publishing key fingerprint.


### Feature highlights

- 🛠  **Offensive**: nmap, Metasploit, Burp, **Sliver**, Responder, ffuf
- 🔑  **Cracking:** hashcat, john, hydra + rockyou & SecLists
- 🔎  Intel/OSINT: yara, IOC Parser, threatfox, subfinder, amass, gobuster
- 🧪  **Vulnerability management:** **Nuclei** (templated CVE/misconfig scanner), Nikto, **Trivy** (images/repos/SBOM), **searchsploit** (Exploit‑DB), **Lynis** (host audit) — plus optional **httpx**/**naabu** companions
- 🐳  Docker + Compose for C2 & payload infra
- 🔌  OpenVPN plugin for instant CTF connectivity
- ⚡  auto‑cpufreq, swap tuning, XFCE‑minimal for battery‑friendly laptops
- 🔐  UFW, Fail2Ban, unattended‑upgrades harden the host

Full usage & troubleshooting → **docs/usage.md**

---

### Vulnerability scan quick start

```bash
nuclei -update-templates
echo https://example.com > targets.txt
nuclei -l targets.txt -severity high,critical -o nuclei-findings.txt
```

---

## Install from a tagged release

```bash
curl -O https://raw.githubusercontent.com/eriklacson/BreachLite/v1.2.0/breachlite.sh
sudo bash breachlite.sh
```

> **Tip:** Replace `v1.2.0` with the tag of your choice to pin to a specific build.

---

## Contributing

1. **Fork** the repo & create a feature branch: `git checkout -b feat/your-change`
2. Lint the script: `shellcheck breachlite.sh && shfmt -d breachlite.sh`
3. Commit and open a **pull request** with a clear, descriptive message.

---

## Reporting Issues

Please open an issue in the [GitHub tracker](https://github.com/eriklacson/BreachLite/issues) for bugs, feature requests, or questions. Include:

- **Steps to reproduce** (commands, inputs, environment)
- **Expected vs. actual behaviour**
- Relevant logs, error messages, or screenshots

---

## License

BreachLite is released under the **GNU General Public License v3.0**. See the [LICENSE](LICENSE) file for the full license text.

## Disclaimer

For educational & lawful security testing **only**.  You are responsible for complying with all applicable laws.

