#!/usr/bin/env bash
# breachlite.sh
# BreachLite bootstrapper – One‑command setup for a lean red‑team, threat‑intel, vuln‑management & password‑cracking workstation on Ubuntu 22.04 / 24.04
# https://github.com/YOURUSER/BreachLite
set -euo pipefail

########## 0. Detect distro ##########
if [[ $(id -u) -ne 0 ]]; then
  echo "Run this script as root (sudo)." >&2; exit 1
fi
REL=$(lsb_release -rs)
echo "[*] Detected Ubuntu $REL"

########## 1. Base system update ##########
echo "[*] Updating system & installing base packages…"
apt update && apt -y upgrade
apt install -y --no-install-recommends \
  build-essential git curl wget unzip jq \
  ca-certificates gnupg lsb-release software-properties-common \
  python3 python3-pip golang-go net-tools ufw fail2ban \
  apt-transport-https

########## 2. Minimal GUI (XFCE) ##########
echo "[*] Installing minimal XFCE environment…"
apt install -y xubuntu-desktop-minimal lightdm
# Disable compositor for performance
sudo -u "$SUDO_USER" xfconf-query -c xfwm4 -p /general/use_compositing -s false || true
systemctl set-default graphical.target

########## 3. Power optimisation ##########
echo "[*] Enabling auto-cpufreq daemon…"
snap install auto-cpufreq --classic
auto-cpufreq --install

########## 4. Swap tuning ##########
echo "[*] Creating 4 GiB swapfile & lowering swappiness…"
swapoff -a || true
fallocate -l 4G /swapfile
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile
grep -q /swapfile /etc/fstab || echo '/swapfile none swap sw 0 0' >> /etc/fstab
sysctl -w vm.swappiness=10
grep -q vm.swappiness /etc/sysctl.conf || echo 'vm.swappiness=10' >> /etc/sysctl.conf

########## 5. Docker ##########
echo "[*] Installing Docker & Compose…"
apt install -y docker.io docker-compose-plugin
systemctl enable --now docker
usermod -aG docker "$SUDO_USER"

########## 6. Core Red‑Team & Cracking tools ##########
echo "[*] Installing core red‑team & password‑cracking tools…"
apt install -y nmap metasploit-framework responder yara yara-python ffuf \
  hashcat john hydra seclists wordlists
# Latest ffuf (optional)
sudo -u "$SUDO_USER" GO111MODULE=on go install github.com/ffuf/ffuf/v2@latest
# Sliver C2
snap install sliver
# Burp Suite (community) – silent unattended installer
BURP_URL="https://portswigger-cdn.net/burp/releases/download?product=community&version=latest&type=Linux"
mkdir -p /opt/burpsuite && cd /opt/burpsuite
wget -qO burp.sh "$BURP_URL"
chmod +x burp.sh
./burp.sh -q || echo "Burp installer returned non‑zero exit code — check logs."
# Decompress rockyou wordlist for convenience
ROCKYOU="/usr/share/wordlists/rockyou.txt.gz"
if [[ -f "$ROCKYOU" ]]; then
  gzip -d -kf "$ROCKYOU"
fi

########## 7. Threat‑Intel / OSINT tools ##########
echo "[*] Installing threat‑intel & OSINT helpers…"
pip install --upgrade threatfox ioc_parser
# Popular OSINT Go tools
sudo -u "$SUDO_USER" go install github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest
sudo -u "$SUDO_USER" go install github.com/OJ/gobuster/v3@latest
sudo -u "$SUDO_USER" go install github.com/caffix/amass/v3/...@latest

########## 7.1 Vulnerability scanners ##########
echo "[*] Installing vulnerability scanners…"

# Determine user's GOPATH for Go tools
GOPATH_DIR=$(sudo -u "$SUDO_USER" bash -lc 'go env GOPATH' 2>/dev/null || true)
if [[ -z "$GOPATH_DIR" ]]; then
  GOPATH_DIR="/home/$SUDO_USER/go"
fi

# Nuclei (ProjectDiscovery) — install as non-root user
sudo -u "$SUDO_USER" bash -lc 'GO111MODULE=on go install github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest'
# First-time templates update via absolute path (avoid PATH race)
if [[ -x "$GOPATH_DIR/bin/nuclei" ]]; then
  sudo -u "$SUDO_USER" "$GOPATH_DIR/bin/nuclei" -update-templates || true
fi

# Nikto & Exploit-DB (searchsploit)
apt install -y nikto exploitdb

# Trivy (prefer apt; fallback to installer if repo missing)
if ! apt -y install trivy 2>/dev/null; then
  curl -sSfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin
fi

# Lynis (host audit)
apt install -y lynis

# Optional ProjectDiscovery companions
sudo -u "$SUDO_USER" bash -lc 'GO111MODULE=on go install github.com/projectdiscovery/httpx/cmd/httpx@latest'
sudo -u "$SUDO_USER" bash -lc 'GO111MODULE=on go install github.com/projectdiscovery/naabu/v2/cmd/naabu@latest'

########## 8. Hardening ##########
echo "[*] Enabling UFW & Fail2Ban…"
ufw default deny incoming
ufw default allow outgoing
ufw allow ssh
ufw --force enable
systemctl enable --now fail2ban
apt install -y unattended-upgrades
dpkg-reconfigure --priority=low unattended-upgrades

########## 9. Productivity aliases ##########
ALIASES=/etc/profile.d/99-breachlite-aliases.sh
echo "[*] Adding handy aliases to $ALIASES"
cat <<'EOF' > "$ALIASES"
# Ensure Go user bin is on PATH for tools like nuclei/httpx/naabu
export PATH="$PATH:$HOME/go/bin"

alias ll='ls -alF'
alias grep='grep --color=auto'
alias nse='nmap --script'
alias msf='msfconsole -q'
alias ff='ffuf -t 50 -fs 424242'
alias hash='hashcat'
alias johnny='john --format=dynamic'
alias hyd='hydra'
alias rockyou='/usr/share/wordlists/rockyou.txt'
# Vuln management helpers
alias nucleiupdate='nuclei -update-templates'
alias vulnscan='nuclei -l targets.txt -severity critical,high -rl 100 -c 50 -o nuclei-findings.txt'
alias imgscan='trivy image'
alias hostaudit='lynis audit system'
# Optional PD companions
alias httpprobe='httpx -silent -status-code -tech-detect -title -follow-redirects'
alias fastports='naabu -top-ports 1000 -rate 1000 -c 200'
# Docker QoL
alias dockerkill='docker ps -q | xargs -r docker kill'
alias dockerclean='docker system prune -f --volumes'
EOF
chmod +x "$ALIASES"

########## 10. VPN / CTF connectivity ##########
echo "[*] Installing OpenVPN client & NetworkManager plugin…"
apt install -y openvpn openvpn-systemd-resolved network-manager-openvpn-gnome
mkdir -p /home/"$SUDO_USER"/vpn
chown "$SUDO_USER":"$SUDO_USER" /home/"$SUDO_USER"/vpn
cat <<'EOT' > /home/"$SUDO_USER"/vpn/README.txt
Place your .ovpn files in this directory and import them with:
  nmcli connection import type openvpn file <file.ovpn>
Or launch the NetworkManager GUI (Settings ▸ Network ▸ + ▸ VPN ▸ Import).
EOT
chown "$SUDO_USER":"$SUDO_USER" /home/"$SUDO_USER"/vpn/README.txt

########## 11. Finish ##########
echo "[+] BreachLite installation complete! Reboot, log back in, and enjoy your optimised red‑team, TI, vuln‑management, cracking & CTF workstation."
