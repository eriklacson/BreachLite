# BreachLite — Usage & FAQ

> **Version tested:** v1.1.0
> **Target OS:** Ubuntu 22.04 / 24.04 (x86‑64 or ARM64)

---

## 1 Install or upgrade

### Fresh install (main branch)

```bash
curl -O https://raw.githubusercontent.com/YOURUSER/BreachLite/main/breachlite.sh
sudo bash breachlite.sh
```

### Pin to a tagged release

```bash
curl -O https://raw.githubusercontent.com/YOURUSER/BreachLite/v1.1.0/breachlite.sh
sudo bash breachlite.sh
```

> **Tip:** Run the script again any time—apt, snap, `go install`, and pip steps are all idempotent.

---

## 2 First‑run checklist

| Task                       | Command                                                      |
| -------------------------- | ------------------------------------------------------------ |
| Update Nuclei templates    | `nuclei -update-templates`                                   |
| Verify Docker works        | `docker run hello-world`                                     |
| Enable auto‑cpufreq daemon | `sudo auto-cpufreq --status`                                 |
| Import VPN profile         | `nmcli connection import type openvpn file ~/vpn/mylab.ovpn` |

---

## 3 Quick‑start recipes

### 3.1 Recon & vulnerability scanning

| Scenario                  | Command                                                                                                    |
| ------------------------- | ---------------------------------------------------------------------------------------------------------- |
| **Tuned HTTP fuzzing**    | `ffuf -w /usr/share/seclists/Discovery/Web-Content/common.txt -u http://target/FUZZ -of html -o ffuf.html` |
| **CVE sweep with Nuclei** | `nuclei -l targets.txt -severity critical,high -o nuclei-findings.txt`                                     |
| **Container image scan**  | `trivy image mycorp/api:latest`                                                                            |
| **Host hardening audit**  | `sudo lynis audit system`                                                                                  |
| **Search exploit-db**     | `searchsploit apache 2.4.58`                                                                               |

### 3.2 Password cracking

| Tool                  | Sample command                                               |
| --------------------- | ------------------------------------------------------------ |
| **Hashcat**           | `hashcat -m 1800 -a 0 hashes.txt rockyou.txt -O --force`     |
| **John the Ripper**   | `john --wordlist=rockyou.txt --format=raw-sha256 hashes.txt` |
| **Hydra (SSH brute)** | `hydra -L users.txt -P rockyou.txt ssh://10.10.10.10`        |

### 3.3 Dockerised C2 / payload infra

```bash
# Example: run Sliver C2 container
docker run -it --rm --name sliver \
  ghcr.io/bishopfox/sliver:latest server
```

---

## 4 Handy aliases

| Alias       | Expands to                              | Purpose                       |
| ----------- | --------------------------------------- | ----------------------------- |
| `ff`        | `ffuf -t 50 -fs 424242`                 | Fast web fuzz baseline        |
| `hash`      | `hashcat`                               | Shorter typing                |
| `johnny`    | `john --format=dynamic`                 | Quick John launch             |
| `rockyou`   | `/usr/share/wordlists/rockyou.txt`      | Path convenience              |
| `vulnscan`  | `nuclei -l targets.txt -o findings.txt` | (add to `.bashrc` if desired) |
| `hostaudit` | `lynis audit system`                    | One‑shot host audit           |

---

## 5 Troubleshooting

| Symptom                          | Fix                                                                 |
| -------------------------------- | ------------------------------------------------------------------- |
| **Docker needs sudo**            | `sudo usermod -aG docker $USER && newgrp docker`                    |
| **Sliver snap won’t run on ARM** | Use Docker image instead (`docker pull ghcr.io/bishopfox/sliver`)   |
| **hashcat “No devices found”**   | Install GPU drivers / OpenCL headers appropriate for your hardware. |
| **Nuclei TLS errors**            | `export GODEBUG=x509ignoreCN=0` for legacy endpoints.               |
| **auto‑cpufreq status inactive** | `sudo systemctl enable --now auto-cpufreq`                          |

---

## 6 Reporting issues

1. Search existing tickets in the [issue tracker](https://github.com/eriklacson/BreachLite/issues).
2. Open a **new issue** with:
   • Steps to reproduce
   • Expected vs actual behaviour
   • Relevant logs / screenshots

---

## 7  Uninstall

BreachLite is additive and does not replace system packages.
To revert:

```bash
# Remove major stacks (example)
sudo apt remove --purge hashcat john hydra sliver* nuclei trivy lynis nikto
sudo snap remove sliver auto-cpufreq
sudo rm -rf /opt/burpsuite ~/nuclei-templates ~/.cache/trivy
```

---

Happy hunting ☠️
