#!/bin/bash

###############################################################################################################
# scan4all Integration Module
# Integrates scan4all functionality for comprehensive vulnerability scanning
# Based on https://github.com/GhostTroops/scan4all
###############################################################################################################

# Install scan4all if not present
function install_scan4all() {
    local install_dir="${tools}/scan4all"
    
    if [[ -d "$install_dir" ]]; then
        printf "%b[✓] scan4all is already installed%b\n" "$bgreen" "$reset"
        return 0
    fi
    
    printf "%b[*] Installing scan4all...%b\n" "$bblue" "$reset"
    
    # Clone scan4all repository
    if git clone --depth 1 https://github.com/GhostTroops/scan4all.git "$install_dir" 2>>"$LOGFILE"; then
        printf "%b[✓] scan4all repository cloned%b\n" "$bgreen" "$reset"
    else
        printf "%b[!] Failed to clone scan4all repository%b\n" "$bred" "$reset"
        return 1
    fi
    
    # Build scan4all
    cd "$install_dir" || return 1
    
    if go build -o scan4all cmd/scan4all/main.go 2>>"$LOGFILE"; then
        printf "%b[✓] scan4all built successfully%b\n" "$bgreen" "$reset"
        
        # Make it executable and add to PATH if not already there
        chmod +x scan4all
        if [[ ! -L "$GOPATH/bin/scan4all" ]]; then
            ln -s "$install_dir/scan4all" "$GOPATH/bin/scan4all" 2>/dev/null
        fi
    else
        printf "%b[!] Failed to build scan4all%b\n" "$bred" "$reset"
        cd - >/dev/null
        return 1
    fi
    
    cd - >/dev/null
    printf "%b[✓] scan4all installation complete%b\n" "$bgreen" "$reset"
    return 0
}

# Run scan4all deep scan
function run_scan4all_deep() {
    local target=$1
    local output_dir="${2:-scan4all_results}"
    
    mkdir -p "$output_dir"
    
    if [[ ! "$SCAN4ALL_ENABLED" == true ]]; then
        printf "%b[*] scan4all is disabled in configuration%b\n" "$yellow" "$reset"
        return 0
    fi
    
    if ! command -v scan4all &> /dev/null && [[ ! -x "${tools}/scan4all/scan4all" ]]; then
        printf "%b[!] scan4all not found, installing...%b\n" "$yellow" "$reset"
        install_scan4all || return 1
    fi
    
    local scan4all_bin="scan4all"
    if [[ -x "${tools}/scan4all/scan4all" ]]; then
        scan4all_bin="${tools}/scan4all/scan4all"
    fi
    
    printf "%b[*] Running scan4all deep scan on %s...%b\n" "$bblue" "$target" "$reset"
    
    # Prepare scan4all arguments
    local scan_args="-host $target -o $output_dir"
    
    # Add proxy if Tor is enabled
    if [[ "$TOR_ENABLED" == true ]]; then
        local proxy_flag=$(add_proxy_flags "scan4all")
        scan_args="$scan_args $proxy_flag"
    fi
    
    # Add deep scan flag if enabled
    if [[ "$SCAN4ALL_DEEP" == true ]]; then
        scan_args="$scan_args -deep"
    fi
    
    # Add POC flag if enabled
    if [[ "$SCAN4ALL_POC" == true ]]; then
        scan_args="$scan_args -poc"
    fi
    
    # Run scan4all
    if $scan4all_bin $scan_args 2>>"$LOGFILE"; then
        printf "%b[✓] scan4all scan completed%b\n" "$bgreen" "$reset"
        return 0
    else
        printf "%b[!] scan4all scan failed or found no results%b\n" "$yellow" "$reset"
        return 1
    fi
}

# Run scan4all port scan
function run_scan4all_portscan() {
    local target=$1
    local output_file="${2:-portscan.txt}"
    
    if [[ ! "$SCAN4ALL_ENABLED" == true ]]; then
        return 0
    fi
    
    if ! command -v scan4all &> /dev/null && [[ ! -x "${tools}/scan4all/scan4all" ]]; then
        printf "%b[!] scan4all not found%b\n" "$yellow" "$reset"
        return 1
    fi
    
    local scan4all_bin="scan4all"
    if [[ -x "${tools}/scan4all/scan4all" ]]; then
        scan4all_bin="${tools}/scan4all/scan4all"
    fi
    
    printf "%b[*] Running scan4all port scan on %s...%b\n" "$bblue" "$target" "$reset"
    
    local scan_args="-host $target -portscan -o $output_file"
    
    # Add proxy if Tor is enabled
    if [[ "$TOR_ENABLED" == true ]]; then
        local proxy_flag=$(add_proxy_flags "scan4all")
        scan_args="$scan_args $proxy_flag"
    fi
    
    if $scan4all_bin $scan_args 2>>"$LOGFILE"; then
        printf "%b[✓] Port scan completed%b\n" "$bgreen" "$reset"
        return 0
    else
        printf "%b[!] Port scan failed%b\n" "$yellow" "$reset"
        return 1
    fi
}

# Run scan4all vulnerability scan
function run_scan4all_vulnscan() {
    local target=$1
    local output_dir="${2:-vulns}"
    
    mkdir -p "$output_dir"
    
    if [[ ! "$SCAN4ALL_ENABLED" == true ]]; then
        return 0
    fi
    
    if ! command -v scan4all &> /dev/null && [[ ! -x "${tools}/scan4all/scan4all" ]]; then
        printf "%b[!] scan4all not found%b\n" "$yellow" "$reset"
        return 1
    fi
    
    local scan4all_bin="scan4all"
    if [[ -x "${tools}/scan4all/scan4all" ]]; then
        scan4all_bin="${tools}/scan4all/scan4all"
    fi
    
    printf "%b[*] Running scan4all vulnerability scan on %s...%b\n" "$bblue" "$target" "$reset"
    
    local scan_args="-host $target -vulnerability -o $output_dir"
    
    # Add proxy if Tor is enabled
    if [[ "$TOR_ENABLED" == true ]]; then
        local proxy_flag=$(add_proxy_flags "scan4all")
        scan_args="$scan_args $proxy_flag"
    fi
    
    if $scan4all_bin $scan_args 2>>"$LOGFILE"; then
        printf "%b[✓] Vulnerability scan completed%b\n" "$bgreen" "$reset"
        
        # Parse and format results
        if [[ -f "$output_dir/vulnerabilities.json" ]]; then
            printf "%b[*] Found vulnerabilities:%b\n" "$bgreen" "$reset"
            jq -r '.[] | "\(.name) - \(.severity)"' "$output_dir/vulnerabilities.json" 2>/dev/null | head -20
        fi
        
        return 0
    else
        printf "%b[!] Vulnerability scan failed%b\n" "$yellow" "$reset"
        return 1
    fi
}

# Run scan4all web scan
function run_scan4all_webscan() {
    local target=$1
    local output_dir="${2:-webscan}"
    
    mkdir -p "$output_dir"
    
    if [[ ! "$SCAN4ALL_ENABLED" == true ]]; then
        return 0
    fi
    
    if ! command -v scan4all &> /dev/null && [[ ! -x "${tools}/scan4all/scan4all" ]]; then
        printf "%b[!] scan4all not found%b\n" "$yellow" "$reset"
        return 1
    fi
    
    local scan4all_bin="scan4all"
    if [[ -x "${tools}/scan4all/scan4all" ]]; then
        scan4all_bin="${tools}/scan4all/scan4all"
    fi
    
    printf "%b[*] Running scan4all web scan on %s...%b\n" "$bblue" "$target" "$reset"
    
    local scan_args="-host $target -webscan -o $output_dir"
    
    # Add proxy if Tor is enabled
    if [[ "$TOR_ENABLED" == true ]]; then
        local proxy_flag=$(add_proxy_flags "scan4all")
        scan_args="$scan_args $proxy_flag"
    fi
    
    if $scan4all_bin $scan_args 2>>"$LOGFILE"; then
        printf "%b[✓] Web scan completed%b\n" "$bgreen" "$reset"
        return 0
    else
        printf "%b[!] Web scan failed%b\n" "$yellow" "$reset"
        return 1
    fi
}

# Main scan4all integration function
function scan4all_full_scan() {
    local target=$1
    local output_base="${2:-.}"
    
    if { [[ ! -f "$called_fn_dir/.${FUNCNAME[0]}" ]] || [[ $DIFF == true ]]; } && [[ $SCAN4ALL_ENABLED == true ]]; then
        start_func "${FUNCNAME[0]}" "Running scan4all comprehensive scan"
        
        mkdir -p "$output_base/scan4all"
        
        # Run different scan types
        run_scan4all_webscan "$target" "$output_base/scan4all/web"
        run_scan4all_vulnscan "$target" "$output_base/scan4all/vulns"
        
        if [[ "$SCAN4ALL_DEEP" == true ]]; then
            run_scan4all_deep "$target" "$output_base/scan4all/deep"
        fi
        
        end_func "scan4all results saved in $output_base/scan4all/" "${FUNCNAME[0]}"
    else
        if [[ $SCAN4ALL_ENABLED == false ]]; then
            printf "\n%b[%s] %s skipped due to configuration settings.%b\n" "$yellow" "$(date +'%Y-%m-%d %H:%M:%S')" "${FUNCNAME[0]}" "$reset"
        else
            printf "%b[%s] %s has already been processed. To force execution, delete:\n    %s/.%s %b\n\n" "$yellow" "$(date +'%Y-%m-%d %H:%M:%S')" "${FUNCNAME[0]}" "$called_fn_dir" "${FUNCNAME[0]}" "$reset"
        fi
    fi
}

# Export functions
export -f install_scan4all
export -f run_scan4all_deep
export -f run_scan4all_portscan
export -f run_scan4all_vulnscan
export -f run_scan4all_webscan
export -f scan4all_full_scan
