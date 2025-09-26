#!/usr/bin/env bash
# breachlite.sh
# BreachLite bootstrapper – One‑command setup for a lean red‑team, threat‑intel, vuln‑management & password‑cracking workstation on Ubuntu 22.04 / 24.04
# https://github.com/eriklacson/BreachLite

# Ensure the script is always executed with Bash so helper functions are available
if [ -z "${BASH_VERSION:-}" ]; then
    exec /usr/bin/env bash "$0" "$@"
fi

set -euo pipefail

# Helper to resolve and optionally install Go-based tools for the target user
go_tool_path() {
    local binary="$1"
    sudo -u "$TARGET_USER" bash -lc "command -v \"$binary\" 2>/dev/null" || true
}

ensure_go_tool() {
    local binary="$1"
    local package="$2"
    local label="${3:-$binary}"
    local bin_path
    bin_path=$(go_tool_path "$binary")
    if [[ -n "$bin_path" ]]; then
        echo "[*] $label already installed at $bin_path — installing/updating via go install…"
    else
        echo "[*] Installing $label via go install…"
    fi
    sudo -u "$TARGET_USER" bash -lc "GO111MODULE=on go install $package"
}

# Ensure apt packages are installed only when missing
ensure_apt_packages() {
    local opts=()
    local packages=()
    local arg
    for arg in "$@"; do
        if [[ "$arg" == --* ]]; then
            opts+=("$arg")
        else
            packages+=("$arg")
        fi
    done

    if ((${#packages[@]} == 0)); then
        echo "[!] ensure_apt_packages: no packages provided." >&2
        return 1
    fi

    local missing=()
    local pkg
    for pkg in "${packages[@]}"; do
        if dpkg -s "$pkg" >/dev/null 2>&1; then
            echo "[*] $pkg already installed — skipping apt install."
        else
            missing+=("$pkg")
        fi
    done

    if ((${#missing[@]})); then
        echo "[*] Installing packages via apt: ${missing[*]}"
        if ! apt install -y "${opts[@]}" "${missing[@]}"; then
            return $?
        fi
    else
        echo "[*] All requested packages already present."
    fi

    return 0
}

ensure_snap() {
    local snap_name="$1"
    shift || true
    if snap list "$snap_name" >/dev/null 2>&1; then
        echo "[*] Snap $snap_name already installed — skipping snap install."
    else
        echo "[*] Installing snap $snap_name…"
        snap install "$snap_name" "$@"
    fi
}

# Ensure all apt/dpkg operations run non-interactively
export DEBIAN_FRONTEND=noninteractive

########## 0. Detect distro ##########
if [[ $(id -u) -ne 0 ]]; then
    echo "Run this script as root (sudo)." >&2
    exit 1
fi

TARGET_USER=${SUDO_USER:-$(logname 2>/dev/null || printf '')}
if [[ -z "$TARGET_USER" ]]; then
    echo "Unable to determine target user (check SUDO_USER or active login)." >&2
    exit 1
fi

REL=$(lsb_release -rs)
echo "[*] Detected Ubuntu $REL"

########## 1. Base system update ##########
echo "[*] Updating system & installing base packages…"
apt update && apt -y upgrade
ensure_apt_packages --no-install-recommends \
    build-essential git curl wget unzip jq \
    ca-certificates gnupg lsb-release software-properties-common \
    python3 python3-pip golang-go net-tools ufw fail2ban \
    apt-transport-https

########## 2. Minimal GUI (XFCE) ##########
echo "[*] Installing minimal XFCE environment…"
ensure_apt_packages xubuntu-desktop-minimal lightdm
# Disable compositor for performance
sudo -u "$TARGET_USER" xfconf-query -c xfwm4 -p /general/use_compositing -s false || true
systemctl set-default graphical.target

########## 3. Power optimisation ##########
echo "[*] Enabling auto-cpufreq daemon…"
ensure_snap auto-cpufreq --classic
auto-cpufreq --install

########## 4. Swap tuning ##########
echo "[*] Creating 4 GiB swapfile & lowering swappiness…"
swapoff -a || true
fallocate -l 4G /swapfile
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile
grep -q /swapfile /etc/fstab || echo '/swapfile none swap sw 0 0' >>/etc/fstab
sysctl -w vm.swappiness=10
grep -q vm.swappiness /etc/sysctl.conf || echo 'vm.swappiness=10' >>/etc/sysctl.conf

########## 5. Docker ##########
echo "[*] Installing Docker & Compose…"
ensure_apt_packages docker.io docker-compose-plugin
systemctl enable --now docker
usermod -aG docker "$TARGET_USER"

########## 6. Core Red‑Team & Cracking tools ##########
echo "[*] Installing core red‑team & password‑cracking tools…"
ensure_apt_packages nmap metasploit-framework responder yara yara-python \
    hashcat john hydra seclists wordlists
# Latest ffuf (optional)
ensure_go_tool "ffuf" "github.com/ffuf/ffuf/v2@latest" "ffuf"
# Sliver C2
SLIVER_ARCH=$(dpkg --print-architecture 2>/dev/null || echo unknown)
if [[ "$SLIVER_ARCH" == "amd64" ]]; then
    ensure_snap sliver
else
    echo "[!] Skipping Sliver snap install — unsupported architecture: $SLIVER_ARCH"
    echo "    Use the Docker image instead, for example:"
    echo "    docker run -it --rm --name sliver ghcr.io/bishopfox/sliver:latest server"
fi

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
pep668_detected=false
if compgen -G "/usr/lib/python*/EXTERNALLY-MANAGED" >/dev/null; then
    pep668_detected=true
elif [[ -r /etc/os-release ]]; then
    # shellcheck source=/dev/null
    . /etc/os-release
    if [[ "${ID:-}" == "ubuntu" && "${VERSION_ID:-}" =~ ^([0-9]+)\.([0-9]+)$ ]]; then
        major=${BASH_REMATCH[1]}
        minor=${BASH_REMATCH[2]}
        if ((10#$major > 23 || (10#$major == 23 && 10#$minor >= 4))); then
            pep668_detected=true
        fi
    fi
fi

if [[ "$pep668_detected" == true ]]; then
    echo "[*] Detected externally managed Python packages – installing user-local threat-intel helpers."
    sudo -u "$TARGET_USER" python3 -m pip install --upgrade --user threatfox ioc_parser
else
    python3 -m pip install --upgrade threatfox ioc_parser
fi

# Popular OSINT Go tools
ensure_go_tool "subfinder" "github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest" "subfinder"
ensure_go_tool "gobuster" "github.com/OJ/gobuster/v3@latest" "gobuster"
ensure_go_tool "amass" "github.com/caffix/amass/v3/...@latest" "amass"

########## 7.1 Vulnerability scanners ##########
echo "[*] Installing vulnerability scanners…"

# Determine user's GOPATH for Go tools
GOPATH_DIR=$(sudo -u "$TARGET_USER" bash -lc 'go env GOPATH' 2>/dev/null || true)
if [[ -z "$GOPATH_DIR" ]]; then
    if [[ "$TARGET_USER" == "root" ]]; then
        GOPATH_DIR="/root/go"
    else
        GOPATH_DIR="/home/${TARGET_USER}/go"
    fi
fi

# Nuclei (ProjectDiscovery) — install as non-root user unless already present
ensure_go_tool "nuclei" "github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest" "nuclei"
NUCLEI_BIN=$(go_tool_path nuclei)
if [[ -z "$NUCLEI_BIN" && -x "$GOPATH_DIR/bin/nuclei" ]]; then
    NUCLEI_BIN="$GOPATH_DIR/bin/nuclei"
fi
# First-time templates update via detected binary
if [[ -n "$NUCLEI_BIN" ]]; then
    sudo -u "$TARGET_USER" "$NUCLEI_BIN" -update-templates || true
fi

# Nikto & Exploit-DB (searchsploit)
ensure_apt_packages nikto exploitdb

# Trivy (prefer Ubuntu archive; fallback to Aqua Security's signed repo)
if ! apt -y install trivy 2>/dev/null; then
    echo "[*] Ubuntu archive lacks Trivy – adding Aqua Security's signed repository…"
    TRIVY_KEYRING="/usr/share/keyrings/trivy-archive-keyring.gpg"
    TRIVY_LIST="/etc/apt/sources.list.d/trivy.list"
    TMP_KEY=$(mktemp)
    TMP_GNUPGHOME=$(mktemp -d)
    chmod 700 "$TMP_GNUPGHOME"

    cleanup_trivy_tmp() {
        rm -f "$TMP_KEY"
        rm -rf "$TMP_GNUPGHOME"
    }
    trap cleanup_trivy_tmp EXIT

    curl -fsSL https://aquasecurity.github.io/trivy-repo/deb/public.key -o "$TMP_KEY"

    EXPECTED_FPR="44C6B1B898686F4BD8C02B08F6BC81736B062A3A"
    ACTUAL_FPR=$(GNUPGHOME="$TMP_GNUPGHOME" gpg --batch --with-colons --import-options show-only --import "$TMP_KEY" 2>/dev/null | awk -F: '/^fpr:/ {print $10; exit}')
    if [[ "$ACTUAL_FPR" != "$EXPECTED_FPR" ]]; then
        echo "[!] ERROR: Unexpected Trivy signing key fingerprint: ${ACTUAL_FPR:-unknown}" >&2
        exit 1
    fi

    gpg --dearmor --yes "$TMP_KEY" >"$TRIVY_KEYRING"
    chmod go+r "$TRIVY_KEYRING"

    cat <<'EOF_TRIVY' >"$TRIVY_LIST"
deb [signed-by=/usr/share/keyrings/trivy-archive-keyring.gpg] https://aquasecurity.github.io/trivy-repo/deb stable main
EOF_TRIVY

    apt update
    ensure_apt_packages trivy

    trap - EXIT
    cleanup_trivy_tmp
    unset -f cleanup_trivy_tmp
fi

# Lynis (host audit)
ensure_apt_packages lynis

# Optional ProjectDiscovery companions
ensure_go_tool "httpx" "github.com/projectdiscovery/httpx/cmd/httpx@latest" "httpx"
ensure_go_tool "naabu" "github.com/projectdiscovery/naabu/v2/cmd/naabu@latest" "naabu"

########## 8. Hardening ##########
echo "[*] Enabling UFW & Fail2Ban…"
ufw default deny incoming
ufw default allow outgoing
ufw allow ssh
ufw --force enable
systemctl enable --now fail2ban
DEBIAN_FRONTEND=noninteractive dpkg-reconfigure -f noninteractive -p low unattended-upgrades

########## 9. Productivity aliases ##########
ALIASES=/etc/profile.d/99-breachlite-aliases.sh
echo "[*] Adding handy aliases to $ALIASES"
cat <<'EOF' >"$ALIASES"
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
ensure_apt_packages openvpn openvpn-systemd-resolved network-manager-openvpn-gnome
mkdir -p /home/"$TARGET_USER"/vpn
chown "$TARGET_USER":"$TARGET_USER" /home/"$TARGET_USER"/vpn
cat <<'EOT' >/home/"$TARGET_USER"/vpn/README.txt
Place your .ovpn files in this directory and import them with:
  nmcli connection import type openvpn file <file.ovpn>
Or launch the NetworkManager GUI (Settings ▸ Network ▸ + ▸ VPN ▸ Import).
EOT
chown "$TARGET_USER":"$TARGET_USER" /home/"$TARGET_USER"/vpn/README.txt

########## 11. Finish ##########
echo "[+] BreachLite installation complete! Reboot, log back in, and enjoy your optimised red‑team, TI, vuln‑management, cracking & CTF workstation."
