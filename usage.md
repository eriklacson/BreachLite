# BreachLite — Usage & FAQ

> **Version tested:** v1.2.0\
> **Target OS:** Ubuntu 22.04 / 24.04 (x86-64 or ARM64)

---

## 1  Install or upgrade

### Fresh install (main branch)

```bash
curl -O https://raw.githubusercontent.com/eriklacson/BreachLite/main/breachlite.sh
sudo bash breachlite.sh
```
### Pin to a tagged release

```bash
curl -O https://raw.githubusercontent.com/eriklacson/BreachLite/v1.2.0/breachlite.sh
sudo bash breachlite.sh
```

> **Tip:** Replace `v1.2.0` with any published tag to lock onto a specific version.

> **Sliver on ARM64:** The installer checks `dpkg --print-architecture` near the Sliver step. If you're on `amd64`, the Sliver snap is installed. Other architectures (e.g. `arm64`) automatically skip the snap and print Docker usage instructions instead.
### Upgrade an existing install

```bash
---

## 2  First-run checklist

| Task                       | Command                                                      |
| -------------------------- | ------------------------------------------------------------ |
| Update Nuclei templates    | `nuclei -update-templates`                                   |
| Verify Docker works        | `docker run hello-world`                                     |
| Enable auto-cpufreq daemon | `sudo auto-cpufreq --status`                                 |
| Import VPN profile         | `nmcli connection import type openvpn file ~/vpn/mylab.ovpn` |

> **Note:** First-time Nuclei template sync may download a few hundred MB. On low-RAM systems, start with `-rl 100 -c 50` (as wired into the `vulnscan` alias) and tune upward.

---

## 3  Quick-start recipes

### 3.1  Recon & vulnerability scanning

| Scenario                  | Command                                                                                                    |
| ------------------------- | ---------------------------------------------------------------------------------------------------------- |
| **Tuned HTTP fuzzing**    | `ffuf -w /usr/share/seclists/Discovery/Web-Content/common.txt -u http://target/FUZZ -of html -o ffuf.html` |
| **CVE sweep with Nuclei** | `nuclei -l targets.txt -severity critical,high -o nuclei-findings.txt`                                     |
| **Container image scan**  | `trivy image mycorp/api:latest`                                                                            |
| **Host hardening audit**  | `sudo lynis audit system`                                                                                  |
| **Search exploit-db**     | `searchsploit apache 2.4.58`                                                                               |

### 3.2  Password cracking

| Tool                  | Sample command                                               |
| --------------------- | ------------------------------------------------------------ |
| **Hashcat**           | `hashcat -m 1800 -a 0 hashes.txt rockyou.txt -O --force`     |
| **John the Ripper**   | `john --wordlist=rockyou.txt --format=raw-sha256 hashes.txt` |
| **Hydra (SSH brute)** | `hydra -L users.txt -P rockyou.txt ssh://10.10.10.10`        |

### 3.3  Dockerised C2 / payload infra

```bash
# Example: run Sliver C2 container
docker run -it --rm --name sliver \
  ghcr.io/bishopfox/sliver:latest server
```

---

## 4  Handy aliases

| Alias           | Expands to                                                      | Purpose                               |
| --------------- | --------------------------------------------------------------- | ------------------------------------- |
| `ll`            | `ls -alF`                                                       | Detailed directory listing            |
| `grep`          | `grep --color=auto`                                             | Highlighted search results            |
| `nse`           | `nmap --script`                                                 | Quick NSE invocation                  |
| `msf`           | `msfconsole -q`                                                 | Launch Metasploit quietly             |
| `ff`            | `ffuf -t 50 -fs 424242`                                         | Fast web fuzz baseline                |
| `hash`          | `hashcat`                                                       | Shorter typing                        |
| `johnny`        | `john --format=dynamic`                                         | Quick John launch                     |
| `hyd`           | `hydra`                                                         | Hydra shortcut                        |
| `rockyou`       | `/usr/share/wordlists/rockyou.txt`                              | Wordlist path convenience             |
| `nucleiupdate`  | `nuclei -update-templates`                                      | Refresh Nuclei templates              |
| `vulnscan`      | `nuclei -l targets.txt -severity critical,high -rl 100 -c 50 -o nuclei-findings.txt` | Batch CVE sweep tuned for stability |
| `imgscan`       | `trivy image`                                                   | Container image vulnerability scan    |
| `hostaudit`     | `lynis audit system`                                            | One-shot host audit                   |
| `httpprobe`     | `httpx -silent -status-code -tech-detect -title -follow-redirects` | Probe and fingerprint HTTP services |
| `fastports`     | `naabu -top-ports 1000 -rate 1000 -c 200`                       | Quick top-port scan                   |
| `dockerkill`    | <code>docker ps -q &#124; xargs -r docker kill</code>            | Stop all running containers           |
| `dockerclean`   | `docker system prune -f --volumes`                              | Prune containers, images, and volumes |
---

## 5  Troubleshooting

| Symptom                          | Fix                                                                 |
| -------------------------------- | ------------------------------------------------------------------- |
| **Docker needs sudo**            | `sudo usermod -aG docker $USER && newgrp docker`                    |
| **Sliver snap won’t run on ARM** | Use Docker image instead (`docker pull ghcr.io/bishopfox/sliver`)   |
| **hashcat “No devices found”**   | Install GPU drivers / OpenCL headers appropriate for your hardware. |
| **Nuclei TLS errors**            | `export GODEBUG=x509ignoreCN=0` for legacy endpoints.               |
| **auto-cpufreq status inactive** | `sudo systemctl enable --now auto-cpufreq`                          |

---

## 6  Reporting issues

1. Search existing tickets in the [issue tracker](https://github.com/eriklacson/BreachLite/issues).
2. Open a **new issue** with:\
   • Steps to reproduce\
   • Expected vs actual behaviour\
   • Relevant logs / screenshots

---

## 7  Uninstall

BreachLite is additive and does not replace system packages.\
To revert:

```bash
sudo apt remove --purge \
  xubuntu-desktop-minimal lightdm \
  docker.io docker-compose-plugin \
  nmap metasploit-framework responder yara yara-python ffuf \
  hashcat john hydra seclists wordlists nuclei nikto exploitdb \
  trivy lynis openvpn openvpn-systemd-resolved network-manager-openvpn-gnome
```

---

Happy hunting ☠️

