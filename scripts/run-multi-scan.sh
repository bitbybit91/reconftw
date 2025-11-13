#!/bin/bash

###############################################################################################################
# reconFTW Hidden Services Multi-Target Scanner
# Runs reconnaissance on multiple .onion sites from a targets list
###############################################################################################################

# Set script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
RECONFTW_DIR="$(dirname "$SCRIPT_DIR")"

# Configuration
TARGETS_FILE="${TARGETS_FILE:-/etc/reconftw/targets.txt}"
LOGFILE="/var/log/reconftw/multi-scan.log"
LOCKFILE="/var/run/reconftw/multi-scan.lock"

# Colors for logging
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    local level=$1
    shift
    local message="$@"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${timestamp} [${level}] ${message}" | tee -a "$LOGFILE"
}

# Create necessary directories
mkdir -p "$(dirname "$LOGFILE")"
mkdir -p "$(dirname "$LOCKFILE")"

# Check if already running
if [[ -f "$LOCKFILE" ]]; then
    pid=$(cat "$LOCKFILE")
    if ps -p "$pid" > /dev/null 2>&1; then
        log "WARN" "${YELLOW}Another instance is already running (PID: $pid)${NC}"
        exit 0
    else
        log "INFO" "Removing stale lock file"
        rm -f "$LOCKFILE"
    fi
fi

# Create lock file
echo $$ > "$LOCKFILE"

# Cleanup function
cleanup() {
    rm -f "$LOCKFILE"
    log "INFO" "${GREEN}Scan cycle completed${NC}"
}
trap cleanup EXIT INT TERM

# Check if targets file exists
if [[ ! -f "$TARGETS_FILE" ]]; then
    log "ERROR" "${RED}Targets file not found: $TARGETS_FILE${NC}"
    log "INFO" "Create $TARGETS_FILE with one .onion domain per line"
    exit 1
fi

# Count targets
target_count=$(grep -v '^#' "$TARGETS_FILE" | grep -v '^[[:space:]]*$' | wc -l)
if [[ $target_count -eq 0 ]]; then
    log "WARN" "${YELLOW}No targets found in $TARGETS_FILE${NC}"
    exit 0
fi

log "INFO" "${BLUE}Starting multi-target scan${NC}"
log "INFO" "Targets file: $TARGETS_FILE"
log "INFO" "Total targets: $target_count"

# Scan statistics
scanned=0
successful=0
failed=0
start_time=$(date +%s)

# Read and process targets
while IFS= read -r line || [[ -n "$line" ]]; do
    # Skip comments and empty lines
    [[ "$line" =~ ^#.*$ ]] && continue
    [[ -z "$line" ]] && continue
    
    # Trim whitespace
    target=$(echo "$line" | xargs)
    
    # Skip if empty after trimming
    [[ -z "$target" ]] && continue
    
    ((scanned++))
    
    log "INFO" "${BLUE}[${scanned}/${target_count}] Scanning: ${target}${NC}"
    
    # Run the scan
    if cd "$RECONFTW_DIR" && ./reconftw-hs.sh -d "$target" >> "$LOGFILE" 2>&1; then
        ((successful++))
        log "INFO" "${GREEN}✓ Successfully scanned: ${target}${NC}"
    else
        ((failed++))
        log "ERROR" "${RED}✗ Failed to scan: ${target}${NC}"
    fi
    
    # Small delay between scans to avoid overwhelming the system
    if [[ $scanned -lt $target_count ]]; then
        log "INFO" "Waiting 30 seconds before next scan..."
        sleep 30
    fi
    
done < "$TARGETS_FILE"

# Calculate duration
end_time=$(date +%s)
duration=$((end_time - start_time))
duration_formatted=$(printf '%02d:%02d:%02d' $((duration/3600)) $((duration%3600/60)) $((duration%60)))

# Final summary
log "INFO" "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
log "INFO" "${GREEN}Multi-Target Scan Summary${NC}"
log "INFO" "Total targets: $target_count"
log "INFO" "Successfully scanned: $successful"
log "INFO" "Failed scans: $failed"
log "INFO" "Duration: $duration_formatted"
log "INFO" "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

exit 0
