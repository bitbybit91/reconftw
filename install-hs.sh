#!/bin/bash

###############################################################################################################
# reconFTW Hidden Services Installation Script
# Ubuntu VPS optimized installation for hidden services reconnaissance
###############################################################################################################

# Detect if the script is being run in MacOS with Homebrew Bash
if [[ "$OSTYPE" == "darwin"* && "$BASH" != "/opt/homebrew/bin/bash" ]]; then
    echo "This installation script is optimized for Ubuntu VPS."
    echo "For macOS, please use the standard install.sh"
    exit 1
fi

# Check if running on Ubuntu
if [[ ! -f /etc/os-release ]] || ! grep -q "Ubuntu" /etc/os-release; then
    echo "Warning: This script is optimized for Ubuntu."
    echo "Continue anyway? (y/n)"
    read -r response
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Load main configuration
CONFIG_FILE="./reconftw-hs.cfg"

if [[ ! -f $CONFIG_FILE ]]; then
    echo "Config file reconftw-hs.cfg not found."
    echo "Falling back to reconftw.cfg"
    CONFIG_FILE="./reconftw.cfg"
fi

source "$CONFIG_FILE"

# Initialize variables
dir="${tools}"
double_check=false

# Check if running as root
if [[ $EUID -eq 0 ]]; then
    echo "This script should NOT be run as root for security reasons."
    echo "However, you will be prompted for sudo password when needed."
    echo "Continue anyway? (y/n)"
    read -r response
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Colors
bred='\033[1;31m'
bblue='\033[1;34m'
bgreen='\033[1;32m'
byellow='\033[1;33m'
reset='\033[0m'

printf "${bgreen}"
cat << "EOF"
╦═╗┌─┐┌─┐┌─┐┌┐┌╔═╗╔╦╗╦ ╦  
╠╦╝├┤ │  │ ││││╠╣  ║ ║║║  
╩╚═└─┘└─┘└─┘┘└┘╚   ╩ ╚╩╝  
Hidden Services Edition
EOF
printf "${reset}\n\n"

printf "${bblue}[*] Starting Hidden Services Installation for Ubuntu VPS${reset}\n\n"

# Update system packages
printf "${bblue}[*] Updating system packages...${reset}\n"
sudo apt update 2>/dev/null

# Install essential packages
printf "${bblue}[*] Installing essential packages...${reset}\n"
sudo apt install -y \
    curl \
    wget \
    git \
    build-essential \
    gcc \
    make \
    libpcap-dev \
    python3 \
    python3-pip \
    python3-venv \
    jq \
    netcat-traditional \
    dnsutils \
    tor \
    privoxy \
    proxychains4 \
    nmap \
    masscan \
    hydra \
    sqlmap \
    nikto \
    dirb \
    gobuster \
    wfuzz \
    whatweb \
    wafw00f 2>/dev/null

printf "${bgreen}[✓] Essential packages installed${reset}\n\n"

# Configure Tor
printf "${bblue}[*] Configuring Tor for hidden services scanning...${reset}\n"

# Backup original torrc
if [[ -f /etc/tor/torrc ]]; then
    sudo cp /etc/tor/torrc /etc/tor/torrc.backup.$(date +%Y%m%d_%H%M%S)
fi

# Configure Tor with optimal settings for reconnaissance
sudo tee /etc/tor/torrc > /dev/null << 'EOF'
# Tor configuration for hidden services reconnaissance

# SOCKS proxy
SocksPort 9050
SocksPolicy accept 127.0.0.1

# Control port
ControlPort 9051
CookieAuthentication 0

# Performance optimizations
NumEntryGuards 8
CircuitBuildTimeout 30
LearnCircuitBuildTimeout 0
MaxCircuitDirtiness 600

# Connection settings
ConnectionPadding 1
ReducedConnectionPadding 0

# Stream isolation
IsolateDestAddr
IsolateDestPort

# Logging
Log notice file /var/log/tor/notices.log

# Directory and exit policies
ExitPolicy reject *:*
EOF

printf "${bgreen}[✓] Tor configured${reset}\n"

# Configure Privoxy for HTTP proxy
printf "${bblue}[*] Configuring Privoxy...${reset}\n"

if [[ -f /etc/privoxy/config ]]; then
    sudo cp /etc/privoxy/config /etc/privoxy/config.backup.$(date +%Y%m%d_%H%M%S)
fi

# Add Tor forwarding to Privoxy
if ! sudo grep -q "forward-socks5t" /etc/privoxy/config; then
    echo "forward-socks5t / 127.0.0.1:9050 ." | sudo tee -a /etc/privoxy/config > /dev/null
fi

printf "${bgreen}[✓] Privoxy configured${reset}\n"

# Restart services
printf "${bblue}[*] Starting Tor and Privoxy services...${reset}\n"
sudo systemctl restart tor
sudo systemctl restart privoxy
sudo systemctl enable tor
sudo systemctl enable privoxy

sleep 3

# Verify Tor is working
printf "${bblue}[*] Verifying Tor connection...${reset}\n"
if curl --socks5 127.0.0.1:9050 -s https://check.torproject.org/ | grep -q "Congratulations"; then
    printf "${bgreen}[✓] Tor is working correctly${reset}\n"
    TOR_IP=$(curl --socks5 127.0.0.1:9050 -s https://api.ipify.org)
    printf "${bgreen}[*] Current Tor IP: ${TOR_IP}${reset}\n"
else
    printf "${byellow}[!] Tor connection could not be verified${reset}\n"
    printf "${byellow}[!] Please check Tor configuration manually${reset}\n"
fi

# Install Golang if needed
if [[ "$install_golang" == true ]]; then
    if ! command -v go &> /dev/null; then
        printf "${bblue}[*] Installing Golang...${reset}\n"
        
        GO_VERSION="1.21.5"
        wget -q "https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz" -O /tmp/go.tar.gz
        sudo rm -rf /usr/local/go
        sudo tar -C /usr/local -xzf /tmp/go.tar.gz
        rm /tmp/go.tar.gz
        
        # Add to PATH
        export GOROOT=/usr/local/go
        export GOPATH=$HOME/go
        export PATH=$GOPATH/bin:$GOROOT/bin:$PATH
        
        # Add to shell profile
        if [[ -f "$HOME/.bashrc" ]]; then
            if ! grep -q "GOROOT" "$HOME/.bashrc"; then
                cat >> "$HOME/.bashrc" << 'GOEOF'
# Golang
export GOROOT=/usr/local/go
export GOPATH=$HOME/go
export PATH=$GOPATH/bin:$GOROOT/bin:$PATH
GOEOF
            fi
        fi
        
        printf "${bgreen}[✓] Golang installed${reset}\n"
    else
        printf "${bgreen}[✓] Golang already installed${reset}\n"
    fi
fi

# Create tools directory
mkdir -p "$dir"
mkdir -p "$dir/wordlists"

# Now run the standard installation
printf "\n${bblue}[*] Running standard reconftw installation...${reset}\n\n"

if [[ -f "./install.sh" ]]; then
    bash ./install.sh
else
    printf "${bred}[!] Standard install.sh not found${reset}\n"
fi

# Install additional hidden services tools
printf "\n${bblue}[*] Installing hidden services specific tools...${reset}\n"

# Install onionscan
if ! command -v onionscan &> /dev/null; then
    printf "${bblue}[*] Installing onionscan...${reset}\n"
    go install github.com/s-rah/onionscan@latest 2>/dev/null
    printf "${bgreen}[✓] onionscan installed${reset}\n"
fi

# Install tor-router tools
printf "${bblue}[*] Setting up additional Tor tools...${reset}\n"
pip3 install --user stem 2>/dev/null
pip3 install --user requests[socks] 2>/dev/null
pip3 install --user pysocks 2>/dev/null

# Setup brute force wordlists
source "${SCRIPTPATH}/lib/brute-integration.sh" 2>/dev/null || true
setup_brute_wordlists 2>/dev/null || {
    mkdir -p "${dir}/wordlists"
    # Create minimal wordlists
    cat > "${dir}/wordlists/users.txt" << 'USERSEOF'
admin
administrator
root
user
USERSEOF
    
    cat > "${dir}/wordlists/passwords.txt" << 'PASSEOF'
admin
password
123456
PASSEOF
}

# Make library scripts executable
chmod +x "${SCRIPTPATH}/lib/"*.sh 2>/dev/null

printf "\n${bgreen}"
cat << "EOF"
╔═══════════════════════════════════════════════════════╗
║                                                       ║
║   Installation Complete!                             ║
║                                                       ║
║   reconFTW Hidden Services Edition                   ║
║   Optimized for Ubuntu VPS                          ║
║                                                       ║
╚═══════════════════════════════════════════════════════╝
EOF
printf "${reset}\n\n"

printf "${bgreen}[✓] Installation completed successfully!${reset}\n\n"

printf "${bblue}Next steps:${reset}\n"
printf "  1. Review configuration: ${byellow}reconftw-hs.cfg${reset}\n"
printf "  2. Test Tor connection: ${byellow}curl --socks5 127.0.0.1:9050 https://check.torproject.org/${reset}\n"
printf "  3. Run reconftw: ${byellow}./reconftw.sh -d example.onion -c reconftw-hs.cfg${reset}\n\n"

printf "${byellow}[*] Please restart your terminal or run: source ~/.bashrc${reset}\n\n"
