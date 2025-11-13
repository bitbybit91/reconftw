#!/bin/bash

###############################################################################################################
# reconFTW Hidden Services Systemd Service Installer
# Installs and configures systemd service for automated scanning
###############################################################################################################

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}This script must be run as root (use sudo)${NC}" 
   exit 1
fi

# Get the reconftw directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
RECONFTW_DIR="$(dirname "$SCRIPT_DIR")"

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}reconFTW Hidden Services Systemd Service Installer${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Installation directory
INSTALL_DIR="/opt/reconftw"
CONFIG_DIR="/etc/reconftw"
LOG_DIR="/var/log/reconftw"

echo -e "${BLUE}[1/8] Creating user and directories...${NC}"

# Create reconftw user if it doesn't exist
if ! id -u reconftw >/dev/null 2>&1; then
    useradd -r -s /bin/bash -d /home/reconftw -m reconftw
    echo -e "${GREEN}✓ Created user: reconftw${NC}"
else
    echo -e "${YELLOW}⚠ User reconftw already exists${NC}"
fi

# Create directories
mkdir -p "$CONFIG_DIR"
mkdir -p "$LOG_DIR"
mkdir -p "/var/run/reconftw"

# Set ownership
chown -R reconftw:reconftw "$LOG_DIR"
chown -R reconftw:reconftw "/var/run/reconftw"

echo -e "${GREEN}✓ Directories created${NC}"
echo ""

echo -e "${BLUE}[2/8] Installing reconftw to ${INSTALL_DIR}...${NC}"

# Copy or symlink reconftw directory
if [[ "$RECONFTW_DIR" != "$INSTALL_DIR" ]]; then
    if [[ -d "$INSTALL_DIR" ]]; then
        echo -e "${YELLOW}⚠ $INSTALL_DIR already exists. Updating...${NC}"
        rsync -a --delete "$RECONFTW_DIR/" "$INSTALL_DIR/"
    else
        cp -r "$RECONFTW_DIR" "$INSTALL_DIR"
    fi
    chown -R reconftw:reconftw "$INSTALL_DIR"
    echo -e "${GREEN}✓ reconftw installed to $INSTALL_DIR${NC}"
else
    echo -e "${YELLOW}⚠ Already running from $INSTALL_DIR${NC}"
fi
echo ""

echo -e "${BLUE}[3/8] Installing systemd service files...${NC}"

# Copy service files
cp "$RECONFTW_DIR/systemd/reconftw-hs.service" /etc/systemd/system/
cp "$RECONFTW_DIR/systemd/reconftw-hs.timer" /etc/systemd/system/
cp "$RECONFTW_DIR/systemd/reconftw-hs-multi.service" /etc/systemd/system/
cp "$RECONFTW_DIR/systemd/reconftw-hs-multi.timer" /etc/systemd/system/

echo -e "${GREEN}✓ Service files installed${NC}"
echo ""

echo -e "${BLUE}[4/8] Setting up configuration files...${NC}"

# Copy example configuration files if they don't exist
if [[ ! -f "$CONFIG_DIR/targets.conf" ]]; then
    cp "$RECONFTW_DIR/systemd/targets.conf.example" "$CONFIG_DIR/targets.conf"
    echo -e "${GREEN}✓ Created $CONFIG_DIR/targets.conf${NC}"
    echo -e "${YELLOW}⚠ Edit $CONFIG_DIR/targets.conf to set your target${NC}"
else
    echo -e "${YELLOW}⚠ $CONFIG_DIR/targets.conf already exists (not overwriting)${NC}"
fi

if [[ ! -f "$CONFIG_DIR/targets.txt" ]]; then
    cp "$RECONFTW_DIR/systemd/targets.txt.example" "$CONFIG_DIR/targets.txt"
    echo -e "${GREEN}✓ Created $CONFIG_DIR/targets.txt${NC}"
    echo -e "${YELLOW}⚠ Edit $CONFIG_DIR/targets.txt to add your targets${NC}"
else
    echo -e "${YELLOW}⚠ $CONFIG_DIR/targets.txt already exists (not overwriting)${NC}"
fi

# Set permissions
chmod 600 "$CONFIG_DIR/targets.conf" 2>/dev/null
chmod 600 "$CONFIG_DIR/targets.txt" 2>/dev/null
chown reconftw:reconftw "$CONFIG_DIR/"* 2>/dev/null

echo ""

echo -e "${BLUE}[5/8] Reloading systemd daemon...${NC}"
systemctl daemon-reload
echo -e "${GREEN}✓ Systemd daemon reloaded${NC}"
echo ""

echo -e "${BLUE}[6/8] Service installation complete!${NC}"
echo ""
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}Configuration Steps:${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "1. ${BLUE}Edit configuration files:${NC}"
echo -e "   Single target: ${GREEN}sudo nano $CONFIG_DIR/targets.conf${NC}"
echo -e "   Multi target:  ${GREEN}sudo nano $CONFIG_DIR/targets.txt${NC}"
echo ""
echo -e "2. ${BLUE}Choose your scanning mode:${NC}"
echo ""
echo -e "   ${GREEN}Option A: Single Target (scans one .onion every 2 hours)${NC}"
echo -e "   sudo systemctl enable reconftw-hs.timer"
echo -e "   sudo systemctl start reconftw-hs.timer"
echo ""
echo -e "   ${GREEN}Option B: Multi Target (scans all .onion sites every 2 hours)${NC}"
echo -e "   sudo systemctl enable reconftw-hs-multi.timer"
echo -e "   sudo systemctl start reconftw-hs-multi.timer"
echo ""
echo -e "3. ${BLUE}Monitor the service:${NC}"
echo -e "   ${GREEN}sudo systemctl status reconftw-hs.timer${NC}"
echo -e "   ${GREEN}sudo journalctl -u reconftw-hs -f${NC}"
echo ""
echo -e "4. ${BLUE}View logs:${NC}"
echo -e "   ${GREEN}sudo tail -f $LOG_DIR/multi-scan.log${NC}"
echo -e "   ${GREEN}sudo tail -f $INSTALL_DIR/reports/*/reconftw.log${NC}"
echo ""
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}Useful Commands:${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "Check timer status:     ${GREEN}sudo systemctl status reconftw-hs.timer${NC}"
echo -e "Check next run time:    ${GREEN}sudo systemctl list-timers reconftw-hs*${NC}"
echo -e "Run scan manually:      ${GREEN}sudo systemctl start reconftw-hs.service${NC}"
echo -e "Stop timer:             ${GREEN}sudo systemctl stop reconftw-hs.timer${NC}"
echo -e "Disable timer:          ${GREEN}sudo systemctl disable reconftw-hs.timer${NC}"
echo -e "View logs:              ${GREEN}sudo journalctl -u reconftw-hs -n 100${NC}"
echo ""
echo -e "${GREEN}Installation complete!${NC}"
echo ""
