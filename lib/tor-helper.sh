#!/bin/bash

###############################################################################################################
# Tor Helper Functions for Hidden Services Reconnaissance
# Provides Tor management, circuit rotation, and proxy support
###############################################################################################################

# Check if Tor is installed and running
function check_tor_service() {
    if ! command -v tor &> /dev/null; then
        printf "%b[!] Tor is not installed. Installing...%b\n" "$bred" "$reset"
        return 1
    fi
    
    if ! systemctl is-active --quiet tor 2>/dev/null && ! pgrep -x "tor" > /dev/null; then
        printf "%b[!] Tor service is not running. Starting...%b\n" "$yellow" "$reset"
        return 1
    fi
    
    printf "%b[✓] Tor service is running%b\n" "$bgreen" "$reset"
    return 0
}

# Start Tor service
function start_tor_service() {
    printf "%b[*] Starting Tor service...%b\n" "$bblue" "$reset"
    
    if systemctl start tor 2>/dev/null; then
        printf "%b[✓] Tor service started successfully%b\n" "$bgreen" "$reset"
    elif tor &>/dev/null & then
        printf "%b[✓] Tor started in background%b\n" "$bgreen" "$reset"
        sleep 5
    else
        printf "%b[!] Failed to start Tor service%b\n" "$bred" "$reset"
        return 1
    fi
    
    # Wait for Tor to be ready
    local max_wait=30
    local count=0
    while [ $count -lt $max_wait ]; do
        if curl --socks5 127.0.0.1:9050 -s https://check.torproject.org/ | grep -q "Congratulations"; then
            printf "%b[✓] Tor connection verified%b\n" "$bgreen" "$reset"
            return 0
        fi
        sleep 1
        ((count++))
    done
    
    printf "%b[!] Tor connection could not be verified%b\n" "$yellow" "$reset"
    return 0
}

# Rotate Tor circuit to get new exit node
function rotate_tor_circuit() {
    if [[ -z "$TOR_CONTROL_PORT" ]]; then
        TOR_CONTROL_PORT=9051
    fi
    
    if command -v nc &> /dev/null; then
        echo -e 'AUTHENTICATE ""\r\nSIGNAL NEWNYM\r\nQUIT' | nc 127.0.0.1 "$TOR_CONTROL_PORT" &>/dev/null
        if [[ $? -eq 0 ]]; then
            printf "%b[✓] Tor circuit rotated%b\n" "$bgreen" "$reset"
            sleep 2
            return 0
        fi
    fi
    
    return 1
}

# Validate if a domain is a valid .onion address
function validate_onion_domain() {
    local domain=$1
    
    # Check if domain ends with .onion
    if [[ ! "$domain" =~ \.onion$ ]]; then
        return 1
    fi
    
    # Extract the onion address (remove http/https)
    local onion_addr=$(echo "$domain" | sed -e 's|^https\?://||' -e 's|/.*||')
    
    # Check v3 onion address (56 chars + .onion)
    if [[ "$onion_addr" =~ ^[a-z2-7]{56}\.onion$ ]]; then
        return 0
    fi
    
    # Check v2 onion address (16 chars + .onion) - deprecated but still in use
    if [[ "$onion_addr" =~ ^[a-z2-7]{16}\.onion$ ]]; then
        return 0
    fi
    
    return 1
}

# Test connection to .onion site through Tor
function test_onion_connection() {
    local target=$1
    local proxy="${TOR_PROXY:-socks5://127.0.0.1:9050}"
    
    if [[ ! "$target" =~ ^https?:// ]]; then
        target="http://$target"
    fi
    
    printf "%b[*] Testing connection to %s%b\n" "$bblue" "$target" "$reset"
    
    local response=$(curl --socks5 "${proxy#socks5://}" \
        --socks5-hostname "${proxy#socks5://}" \
        -s -o /dev/null -w "%{http_code}" \
        --max-time "${REQUEST_TIMEOUT:-120}" \
        "$target" 2>/dev/null)
    
    if [[ -n "$response" && "$response" != "000" ]]; then
        printf "%b[✓] Connection successful (HTTP %s)%b\n" "$bgreen" "$response" "$reset"
        return 0
    else
        printf "%b[!] Connection failed%b\n" "$yellow" "$reset"
        return 1
    fi
}

# Setup proxy environment variables for Tor
function setup_tor_proxy() {
    local socks_proxy="${TOR_PROXY:-socks5://127.0.0.1:9050}"
    local http_proxy="${TOR_HTTP_PROXY:-http://127.0.0.1:8118}"
    
    export http_proxy="$http_proxy"
    export https_proxy="$http_proxy"
    export HTTP_PROXY="$http_proxy"
    export HTTPS_PROXY="$http_proxy"
    export SOCKS_PROXY="$socks_proxy"
    
    printf "%b[✓] Proxy environment variables set%b\n" "$bgreen" "$reset"
    printf "%b    HTTP Proxy: %s%b\n" "$blue" "$http_proxy" "$reset"
    printf "%b    SOCKS Proxy: %s%b\n" "$blue" "$socks_proxy" "$reset"
}

# Get current Tor IP
function get_tor_ip() {
    local ip=$(curl --socks5 127.0.0.1:9050 -s https://api.ipify.org 2>/dev/null)
    if [[ -n "$ip" ]]; then
        printf "%b[✓] Current Tor IP: %s%b\n" "$bgreen" "$ip" "$reset"
        echo "$ip"
    else
        printf "%b[!] Could not retrieve Tor IP%b\n" "$yellow" "$reset"
        return 1
    fi
}

# Add proxy flags to command
function add_proxy_flags() {
    local tool=$1
    local proxy="${TOR_PROXY:-socks5://127.0.0.1:9050}"
    local http_proxy="${TOR_HTTP_PROXY:-http://127.0.0.1:8118}"
    
    case "$tool" in
        curl)
            echo "--socks5 ${proxy#socks5://} --socks5-hostname ${proxy#socks5://}"
            ;;
        wget)
            echo "-e use_proxy=yes -e http_proxy=$http_proxy -e https_proxy=$http_proxy"
            ;;
        httpx)
            echo "-http-proxy $http_proxy"
            ;;
        nuclei)
            echo "-proxy $http_proxy"
            ;;
        ffuf)
            echo "-x $http_proxy"
            ;;
        sqlmap)
            echo "--proxy=$http_proxy --tor --check-tor"
            ;;
        nikto)
            echo "-useproxy $http_proxy"
            ;;
        nmap)
            echo "--proxies $socks_proxy"
            ;;
        *)
            echo "-proxy $http_proxy"
            ;;
    esac
}

# Check system hardening and attempt bypasses
function check_system_hardening() {
    printf "%b[*] Checking for system hardening...%b\n" "$bblue" "$reset"
    
    local hardening_detected=false
    
    # Check for common security tools
    if command -v apparmor_status &> /dev/null; then
        printf "%b[*] AppArmor detected%b\n" "$yellow" "$reset"
        hardening_detected=true
    fi
    
    if command -v aa-status &> /dev/null; then
        printf "%b[*] AppArmor detected%b\n" "$yellow" "$reset"
        hardening_detected=true
    fi
    
    if command -v getenforce &> /dev/null; then
        printf "%b[*] SELinux detected%b\n" "$yellow" "$reset"
        hardening_detected=true
    fi
    
    # Check for firewall
    if command -v ufw &> /dev/null; then
        if ufw status 2>/dev/null | grep -q "Status: active"; then
            printf "%b[*] UFW firewall active%b\n" "$yellow" "$reset"
            hardening_detected=true
        fi
    fi
    
    if command -v iptables &> /dev/null; then
        if iptables -L 2>/dev/null | grep -q "Chain"; then
            printf "%b[*] iptables rules detected%b\n" "$yellow" "$reset"
            hardening_detected=true
        fi
    fi
    
    if [[ "$hardening_detected" == true ]]; then
        printf "%b[!] System hardening detected. Using stealth techniques...%b\n" "$yellow" "$reset"
        return 1
    else
        printf "%b[✓] No major system hardening detected%b\n" "$bgreen" "$reset"
        return 0
    fi
}

# Initialize Tor for hidden services reconnaissance
function init_tor_for_recon() {
    printf "\n%b#######################################################################%b\n" "$bgreen" "$reset"
    printf "%b[%s] Initializing Tor for Hidden Services Reconnaissance%b\n\n" "$bblue" "$(date +'%Y-%m-%d %H:%M:%S')" "$reset"
    
    # Check and start Tor if needed
    if ! check_tor_service; then
        start_tor_service || {
            printf "%b[!] Failed to start Tor. Please install and configure Tor manually.%b\n" "$bred" "$reset"
            printf "%b[*] Install: sudo apt install tor%b\n" "$yellow" "$reset"
            return 1
        }
    fi
    
    # Setup proxy
    setup_tor_proxy
    
    # Get current IP
    get_tor_ip
    
    # Check system hardening
    check_system_hardening
    
    printf "\n%b[✓] Tor initialization complete%b\n" "$bgreen" "$reset"
    printf "%b#######################################################################%b\n\n" "$bgreen" "$reset"
    
    return 0
}

# Cleanup Tor on exit
function cleanup_tor() {
    printf "\n%b[*] Cleaning up Tor resources...%b\n" "$bblue" "$reset"
    
    # Unset proxy environment variables
    unset http_proxy
    unset https_proxy
    unset HTTP_PROXY
    unset HTTPS_PROXY
    unset SOCKS_PROXY
    
    printf "%b[✓] Cleanup complete%b\n" "$bgreen" "$reset"
}

# Export functions
export -f check_tor_service
export -f start_tor_service
export -f rotate_tor_circuit
export -f validate_onion_domain
export -f test_onion_connection
export -f setup_tor_proxy
export -f get_tor_ip
export -f add_proxy_flags
export -f check_system_hardening
export -f init_tor_for_recon
export -f cleanup_tor
