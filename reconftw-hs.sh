#!/bin/bash

###############################################################################################################
# reconFTW Hidden Services Edition
# Specialized reconnaissance tool for .onion hidden services
# Integrates scan4all and Brute with Tor proxy support
###############################################################################################################

# Detect if the script is being run in MacOS with Homebrew Bash
if [[ $OSTYPE == "darwin"* && $BASH != "/opt/homebrew/bin/bash" ]]; then
    exec /opt/homebrew/bin/bash "$0" "$@"
fi

# Get script directory
SCRIPTPATH="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

# Load hidden services configuration
CONFIG_FILE="${SCRIPTPATH}/reconftw-hs.cfg"

if [[ ! -f $CONFIG_FILE ]]; then
    printf "\n\033[1;31m[!] Hidden Services config file not found: %s\033[0m\n" "$CONFIG_FILE"
    printf "\033[1;33m[*] Falling back to standard config\033[0m\n\n"
    CONFIG_FILE="${SCRIPTPATH}/reconftw.cfg"
fi

# Source configuration
source "$CONFIG_FILE"

# Load Tor helper functions
if [[ -f "${SCRIPTPATH}/lib/tor-helper.sh" ]]; then
    source "${SCRIPTPATH}/lib/tor-helper.sh"
else
    printf "\n\033[1;31m[!] Tor helper library not found\033[0m\n\n"
    exit 1
fi

# Load scan4all integration
if [[ -f "${SCRIPTPATH}/lib/scan4all-integration.sh" ]]; then
    source "${SCRIPTPATH}/lib/scan4all-integration.sh"
fi

# Load brute integration
if [[ -f "${SCRIPTPATH}/lib/brute-integration.sh" ]]; then
    source "${SCRIPTPATH}/lib/brute-integration.sh"
fi

# Display banner
function hs_banner() {
    printf "\n%b" "$bgreen"
    cat << "EOF"
    ██░ ██ ▓█████  ▄████▄   ▒█████   ███▄    █   █████▒▄▄▄█████▓ █     █░
   ▓██░ ██▒▓█   ▀ ▒██▀ ▀█  ▒██▒  ██▒ ██ ▀█   █ ▓██   ▒ ▓  ██▒ ▓▒▓█░ █ ░█░
   ▒██▀▀██░▒███   ▒▓█    ▄ ▒██░  ██▒▓██  ▀█ ██▒▒████ ░ ▒ ▓██░ ▒░▒█░ █ ░█ 
   ░▓█ ░██ ▒▓█  ▄ ▒▓▓▄ ▄██▒▒██   ██░▓██▒  ▐▌██▒░▓█▒  ░ ░ ▓██▓ ░ ░█░ █ ░█ 
   ░▓█▒░██▓░▒████▒▒ ▓███▀ ░░ ████▓▒░▒██░   ▓██░░▒█░      ▒██▒ ░ ░░██▒██▓
    ▒ ░░▒░▒░░ ▒░ ░░ ░▒ ▒  ░░ ▒░▒░▒░ ░ ▒░   ▒ ▒  ▒ ░      ▒ ░░   ░ ▓░▒ ▒ 
    ▒ ░▒░ ░ ░ ░  ░  ░  ▒     ░ ▒ ▒░ ░ ░░   ░ ▒░ ░          ░      ▒ ░ ░ 
    ░  ░░ ░   ░   ░        ░ ░ ░ ▒     ░   ░ ░  ░ ░      ░        ░   ░ 
    ░  ░  ░   ░  ░░ ░          ░ ░           ░                      ░   
                                                                         
         Hidden Services Edition - Tor Reconnaissance Tool
                    by @six2dez - Enhanced for .onion
EOF
    printf "%b\n\n" "$reset"
}

# Parse command line arguments
function parse_args() {
    local domain=""
    local config=""
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            -d|--domain)
                domain="$2"
                shift 2
                ;;
            -c|--config)
                config="$2"
                shift 2
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                printf "%b[!] Unknown option: %s%b\n" "$bred" "$1" "$reset"
                show_help
                exit 1
                ;;
        esac
    done
    
    if [[ -z "$domain" ]]; then
        printf "%b[!] Domain is required%b\n" "$bred" "$reset"
        show_help
        exit 1
    fi
    
    echo "$domain"
}

# Show help
function show_help() {
    cat << EOF

Usage: $0 -d <domain> [-c <config>]

Options:
    -d, --domain    Target domain (e.g., example.onion)
    -c, --config    Configuration file (default: reconftw-hs.cfg)
    -h, --help      Show this help message

Examples:
    $0 -d example.onion
    $0 -d example.onion -c custom-config.cfg

EOF
}

# Main execution function
function main() {
    hs_banner
    
    # Parse arguments
    if [[ $# -eq 0 ]]; then
        show_help
        exit 1
    fi
    
    local target=$(parse_args "$@")
    
    # Validate .onion domain
    if [[ "$ONION_VALIDATION" == true ]]; then
        if validate_onion_domain "$target"; then
            printf "%b[✓] Valid .onion domain: %s%b\n" "$bgreen" "$target" "$reset"
        else
            printf "%b[!] Warning: %s does not appear to be a valid .onion domain%b\n" "$yellow" "$target" "$reset"
            printf "%b[*] Continuing anyway...%b\n" "$yellow" "$reset"
        fi
    fi
    
    # Initialize Tor
    if [[ "$TOR_ENABLED" == true ]]; then
        init_tor_for_recon || {
            printf "%b[!] Failed to initialize Tor%b\n" "$bred" "$reset"
            printf "%b[*] Please install and configure Tor before running this tool%b\n" "$yellow" "$reset"
            printf "%b[*] Run: ./install-hs.sh%b\n" "$yellow" "$reset"
            exit 1
        }
        
        # Test connection to target
        test_onion_connection "$target"
    fi
    
    # Create output directory
    local output_dir="${dir_output:-$HOME/reconftw-output}/${target}"
    mkdir -p "$output_dir"
    cd "$output_dir" || exit 1
    
    # Set up logging
    export LOGFILE="${output_dir}/reconftw.log"
    touch "$LOGFILE"
    
    # Create .called_fn directory for tracking
    export called_fn_dir="${output_dir}/.called_fn"
    mkdir -p "$called_fn_dir"
    
    printf "\n%b#######################################################################%b\n" "$bgreen" "$reset"
    printf "%b[%s] Starting Hidden Services Reconnaissance%b\n" "$bblue" "$(date +'%Y-%m-%d %H:%M:%S')" "$reset"
    printf "%b[*] Target: %s%b\n" "$bblue" "$target" "$reset"
    printf "%b[*] Output: %s%b\n" "$bblue" "$output_dir" "$reset"
    printf "%b#######################################################################%b\n\n" "$bgreen" "$reset"
    
    # Export domain for use in functions
    export domain="$target"
    
    # Run reconnaissance modules
    
    # 1. Web probing with Tor proxy
    if [[ "$WEBPROBESIMPLE" == true ]]; then
        printf "%b[*] Probing web service...%b\n" "$bblue" "$reset"
        
        local proxy_flag=""
        if [[ "$TOR_ENABLED" == true ]]; then
            proxy_flag=$(add_proxy_flags "httpx")
        fi
        
        echo "$target" | httpx $proxy_flag $HTTPX_FLAGS -json -o webprobe.json 2>>"$LOGFILE"
        
        if [[ -f "webprobe.json" ]]; then
            printf "%b[✓] Web probe complete%b\n" "$bgreen" "$reset"
            jq -r '. | "\(.url) [\(.status_code)] \(.title)"' webprobe.json 2>/dev/null
        fi
    fi
    
    # 2. Web screenshot
    if [[ "$WEBSCREENSHOT" == true ]]; then
        printf "%b[*] Taking screenshot...%b\n" "$bblue" "$reset"
        mkdir -p screenshots
        
        # Note: Screenshots through Tor require special setup
        printf "%b[!] Screenshot functionality may not work through Tor%b\n" "$yellow" "$reset"
    fi
    
    # 3. Technology detection
    printf "%b[*] Detecting technologies...%b\n" "$bblue" "$reset"
    
    if command -v whatweb &> /dev/null; then
        local proxy_opts=""
        if [[ "$TOR_ENABLED" == true ]]; then
            proxy_opts="--proxy 127.0.0.1:8118"
        fi
        
        whatweb $proxy_opts -a 3 "$target" | tee tech_detection.txt 2>>"$LOGFILE"
    fi
    
    # 4. Directory fuzzing with Tor
    if [[ "$FUZZ" == true ]]; then
        printf "%b[*] Starting directory fuzzing...%b\n" "$bblue" "$reset"
        mkdir -p fuzz
        
        local proxy_flag=""
        if [[ "$TOR_ENABLED" == true ]]; then
            proxy_flag=$(add_proxy_flags "ffuf")
        fi
        
        if [[ -f "$fuzz_wordlist" ]]; then
            timeout 1800 ffuf -u "http://${target}/FUZZ" -w "$fuzz_wordlist" \
                $proxy_flag \
                $FFUF_FLAGS \
                -t "${FFUF_THREADS:-10}" \
                -rate "${FFUF_RATELIMIT:-10}" \
                -o fuzz/directories.json \
                2>>"$LOGFILE"
            
            if [[ -f "fuzz/directories.json" ]]; then
                printf "%b[✓] Fuzzing complete%b\n" "$bgreen" "$reset"
            fi
        else
            printf "%b[!] Fuzz wordlist not found: %s%b\n" "$yellow" "$fuzz_wordlist" "$reset"
        fi
    fi
    
    # 5. Nuclei vulnerability scanning with Tor
    if [[ "$NUCLEICHECK" == true ]]; then
        printf "%b[*] Running Nuclei vulnerability scan...%b\n" "$bblue" "$reset"
        mkdir -p nuclei
        
        local proxy_flag=""
        if [[ "$TOR_ENABLED" == true ]]; then
            proxy_flag=$(add_proxy_flags "nuclei")
        fi
        
        echo "$target" | nuclei \
            -t "$NUCLEI_TEMPLATES_PATH" \
            $proxy_flag \
            -severity "$NUCLEI_SEVERITY" \
            $NUCLEI_FLAGS \
            -rate-limit "${NUCLEI_RATELIMIT:-10}" \
            -timeout "${REQUEST_TIMEOUT:-120}" \
            -o nuclei/results.txt \
            2>>"$LOGFILE"
        
        if [[ -f "nuclei/results.txt" ]]; then
            printf "%b[✓] Nuclei scan complete%b\n" "$bgreen" "$reset"
            printf "%b[*] Vulnerabilities found:%b\n" "$bgreen" "$reset"
            cat nuclei/results.txt | head -20
        fi
    fi
    
    # 6. scan4all integration
    if [[ "$SCAN4ALL_ENABLED" == true ]]; then
        scan4all_full_scan "$target" "$output_dir"
    fi
    
    # 7. Brute force attacks
    if [[ "$BRUTE_ENABLED" == true ]] && [[ "$SPRAY" == true ]]; then
        brute_full_attack "$target" "$output_dir"
    fi
    
    # 8. SQLMap testing
    if [[ "$SQLMAP" == true ]] && [[ -f "fuzz/directories.json" ]]; then
        printf "%b[*] Testing for SQL injection...%b\n" "$bblue" "$reset"
        mkdir -p sqli
        
        # Extract URLs from fuzzing results
        jq -r '.results[].url' fuzz/directories.json 2>/dev/null | head -10 | while read -r url; do
            if [[ -n "$url" ]]; then
                printf "%b[*] Testing: %s%b\n" "$bblue" "$url" "$reset"
                
                timeout 600 sqlmap -u "$url" \
                    --batch \
                    --random-agent \
                    --level 1 \
                    --risk 1 \
                    $(add_proxy_flags "sqlmap") \
                    --output-dir="sqli/" \
                    2>>"$LOGFILE" || true
            fi
        done
    fi
    
    # Rotate Tor circuit periodically
    if [[ "$TOR_ENABLED" == true ]]; then
        rotate_tor_circuit
    fi
    
    # Generate summary report
    printf "\n%b#######################################################################%b\n" "$bgreen" "$reset"
    printf "%b[%s] Reconnaissance Complete%b\n\n" "$bblue" "$(date +'%Y-%m-%d %H:%M:%S')" "$reset"
    
    printf "%b[*] Results Summary:%b\n" "$bgreen" "$reset"
    printf "  - Output directory: %s\n" "$output_dir"
    [[ -f "webprobe.json" ]] && printf "  - Web probe results: webprobe.json\n"
    [[ -f "tech_detection.txt" ]] && printf "  - Technology detection: tech_detection.txt\n"
    [[ -d "fuzz" ]] && printf "  - Fuzzing results: fuzz/\n"
    [[ -d "nuclei" ]] && printf "  - Nuclei results: nuclei/\n"
    [[ -d "scan4all" ]] && printf "  - scan4all results: scan4all/\n"
    [[ -d "brute" ]] && printf "  - Brute force results: brute/\n"
    [[ -d "sqli" ]] && printf "  - SQL injection results: sqli/\n"
    
    printf "\n%b[✓] All scans completed successfully!%b\n" "$bgreen" "$reset"
    printf "%b#######################################################################%b\n\n" "$bgreen" "$reset"
    
    # Cleanup
    if [[ "$TOR_ENABLED" == true ]]; then
        cleanup_tor
    fi
}

# Trap to cleanup on exit
trap cleanup_tor EXIT INT TERM

# Run main function
main "$@"
