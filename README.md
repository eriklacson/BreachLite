# BreachLite 🚀

*One-command bootstrap for a lightweight red-team, threat‑intel & password‑cracking workstation.*

## Quick start

```bash
curl -O https://raw.githubusercontent.com/YOURUSER/BreachLite/main/breachlite.sh
sudo bash breachlite.sh
```

### Feature highlights

* 🛠  Offensive: nmap, Metasploit, Burp, **Sliver**, Responder, ffuf
* 🔑  **Cracking:** hashcat, john, hydra + rockyou & SecLists
* 🔎  Intel/OSINT: yara, IOC Parser, threatfox, subfinder, amass, gobuster
* 🐳  Docker + Compose for C2 & payload infra
* 🔌  OpenVPN plugin for instant CTF connectivity
* ⚡  auto‑cpufreq, swap tuning, XFCE‑minimal for battery‑friendly laptops
* 🔐  UFW, Fail2Ban, unattended‑upgrades harden the host

Full usage & troubleshooting → **docs/usage.md**

---

## Install from a tagged release

```bash
curl -O https://raw.githubusercontent.com/YOURUSER/BreachLite/breachlite.sh
sudo bash breachlite.sh
```


---

## Contributing

1. **Fork** the repo & create a feature branch: `git checkout -b feat/your-change`
2. Lint the script: `shellcheck breachlite.sh && shfmt -d breachlite.sh`
3. Commit and open a **pull request** with a clear, descriptive message.

---

## Reporting Issues

Please open an issue in the [GitHub tracker](https://github.com/eriklacson/BreachLite/issues) for bugs, feature requests, or questions. Include:

* **Steps to reproduce** (commands, inputs, environment)
* **Expected vs. actual behaviour**
* Relevant logs, error messages, or screenshots

---

## License

BreachLite is released under the **GNU General Public License v3.0**. See the [LICENSE](LICENSE) file for the full license text.

## Disclaimer

For educational & lawful security testing **only**.  You are responsible for complying with all applicable laws.
