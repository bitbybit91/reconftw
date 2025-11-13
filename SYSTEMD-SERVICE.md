# Systemd Service Configuration Guide

This guide explains how to set up reconFTW Hidden Services Edition to run automatically every 2 hours using systemd.

## Overview

The systemd integration provides:
- ⏰ **Automated scanning** every 2 hours
- 🔄 **Multi-target support** - scan multiple .onion sites
- 📊 **Logging and monitoring** through systemd journal
- 🔒 **Security hardening** with systemd protections
- 🚀 **Auto-start on boot** with recovery on failure
- 📈 **Resource limits** to prevent system overload

## Quick Start

### Installation

```bash
# Run the installer (requires sudo)
sudo ./scripts/install-systemd-service.sh
```

This will:
1. Create a `reconftw` system user
2. Install reconftw to `/opt/reconftw`
3. Copy systemd service files
4. Create configuration directories
5. Set up logging

### Configuration

**Option A: Single Target Mode**

Edit `/etc/reconftw/targets.conf`:
```bash
sudo nano /etc/reconftw/targets.conf
```

Set your target:
```bash
TARGET=example.onion
```

Enable and start:
```bash
sudo systemctl enable reconftw-hs.timer
sudo systemctl start reconftw-hs.timer
```

**Option B: Multi-Target Mode**

Edit `/etc/reconftw/targets.txt`:
```bash
sudo nano /etc/reconftw/targets.txt
```

Add your targets (one per line):
```
# My hidden services targets
marketplace1.onion
forum1.onion
service1.onion
```

Enable and start:
```bash
sudo systemctl enable reconftw-hs-multi.timer
sudo systemctl start reconftw-hs-multi.timer
```

## Service Files

### reconftw-hs.service
Single-target service that scans one .onion domain.

**Features:**
- Scans one target defined in `/etc/reconftw/targets.conf`
- 4GB memory limit
- 200% CPU quota (2 cores)
- Automatic restart on failure

### reconftw-hs.timer
Timer unit that triggers the service every 2 hours.

**Schedule:**
- Runs every 2 hours: `*-*-* */2:00:00`
- First run: 5 minutes after boot
- Randomized delay: up to 5 minutes

### reconftw-hs-multi.service
Multi-target service that scans multiple .onion domains.

**Features:**
- Reads targets from `/etc/reconftw/targets.txt`
- 8GB memory limit
- 300% CPU quota (3 cores)
- 12-hour timeout (for large target lists)
- 30-second delay between targets

### reconftw-hs-multi.timer
Timer unit for multi-target scanning every 2 hours.

## Directory Structure

```
/opt/reconftw/              # Installation directory
├── reconftw-hs.sh          # Main script
├── reconftw-hs.cfg         # Configuration
├── lib/                    # Libraries
├── scripts/                # Helper scripts
└── reports/                # Scan results

/etc/reconftw/              # Configuration
├── targets.conf            # Single target config
└── targets.txt             # Multi-target list

/var/log/reconftw/          # Logs
└── multi-scan.log          # Multi-target scan log

/var/run/reconftw/          # Runtime files
└── multi-scan.lock         # Lock file
```

## Usage

### Check Timer Status

```bash
# View all reconftw timers
sudo systemctl list-timers reconftw-hs*

# Check specific timer
sudo systemctl status reconftw-hs.timer
sudo systemctl status reconftw-hs-multi.timer
```

### Manual Execution

Run a scan immediately without waiting for the timer:

```bash
# Single target
sudo systemctl start reconftw-hs.service

# Multi target
sudo systemctl start reconftw-hs-multi.service
```

### View Logs

**System journal:**
```bash
# Follow logs in real-time
sudo journalctl -u reconftw-hs -f
sudo journalctl -u reconftw-hs-multi -f

# View last 100 lines
sudo journalctl -u reconftw-hs -n 100

# View logs since boot
sudo journalctl -u reconftw-hs -b
```

**Application logs:**
```bash
# Multi-scan log
sudo tail -f /var/log/reconftw/multi-scan.log

# Individual scan logs
sudo tail -f /opt/reconftw/reports/example.onion/reconftw.log
```

### Stop/Disable Service

```bash
# Stop the timer (prevents new scans)
sudo systemctl stop reconftw-hs.timer
sudo systemctl stop reconftw-hs-multi.timer

# Disable timer (won't start on boot)
sudo systemctl disable reconftw-hs.timer
sudo systemctl disable reconftw-hs-multi.timer

# Stop a running scan
sudo systemctl stop reconftw-hs.service
sudo systemctl stop reconftw-hs-multi.service
```

### Restart Service

```bash
# Restart timer
sudo systemctl restart reconftw-hs.timer

# Reload configuration
sudo systemctl daemon-reload
sudo systemctl restart reconftw-hs.timer
```

## Configuration Files

### /etc/reconftw/targets.conf

Single target configuration for `reconftw-hs.service`:

```bash
# Target .onion domain
TARGET=example.onion

# Optional: Override environment variables
# TELEGRAM_ENABLED=true
# SCAN_MODE=deep
```

### /etc/reconftw/targets.txt

Multi-target list for `reconftw-hs-multi.service`:

```
# Lines starting with # are comments
# One .onion domain per line

# Marketplaces
marketplace1.onion
marketplace2.onion

# Forums
forum1.onion
forum2.onion

# Services
service1.onion
```

## Customization

### Change Schedule

Edit the timer file to change the schedule:

```bash
sudo nano /etc/systemd/system/reconftw-hs.timer
```

Examples:

**Every hour:**
```ini
OnCalendar=*-*-* *:00:00
```

**Every 4 hours:**
```ini
OnCalendar=*-*-* */4:00:00
```

**Daily at 2 AM:**
```ini
OnCalendar=*-*-* 02:00:00
```

**Every Monday at 9 AM:**
```ini
OnCalendar=Mon *-*-* 09:00:00
```

After editing, reload systemd:
```bash
sudo systemctl daemon-reload
sudo systemctl restart reconftw-hs.timer
```

### Adjust Resource Limits

Edit the service file:

```bash
sudo nano /etc/systemd/system/reconftw-hs-multi.service
```

Modify these lines:

```ini
MemoryMax=8G          # Maximum RAM usage
CPUQuota=300%         # CPU usage (300% = 3 cores)
TimeoutStartSec=12h   # Maximum runtime
```

Reload after changes:
```bash
sudo systemctl daemon-reload
sudo systemctl restart reconftw-hs-multi.service
```

## Monitoring

### View Next Scheduled Run

```bash
sudo systemctl list-timers reconftw-hs*
```

Output example:
```
NEXT                        LEFT          LAST                        PASSED  UNIT
Wed 2025-11-13 14:00:00 UTC 1h 23min left Wed 2025-11-13 12:00:00 UTC 36min ago reconftw-hs.timer
```

### Check Service Status

```bash
sudo systemctl status reconftw-hs.service
```

Output shows:
- ✓ Active/Inactive status
- Last run time
- Exit status
- Recent log entries

### Monitor Resource Usage

```bash
# Show resource usage
sudo systemctl show reconftw-hs.service -p MemoryCurrent -p CPUUsageNSec

# Watch in real-time
watch -n 1 'sudo systemctl show reconftw-hs.service -p MemoryCurrent'
```

## Troubleshooting

### Service Fails to Start

**Check logs:**
```bash
sudo journalctl -u reconftw-hs -n 50
```

**Common issues:**
- Tor not running: `sudo systemctl start tor`
- Missing configuration: Check `/etc/reconftw/targets.conf`
- Permission errors: Check ownership of `/opt/reconftw/reports`
- Missing dependencies: Run `./install-hs.sh`

### Timer Not Triggering

**Verify timer is enabled:**
```bash
sudo systemctl is-enabled reconftw-hs.timer
```

**Check timer status:**
```bash
sudo systemctl list-timers --all reconftw-hs*
```

**Enable if needed:**
```bash
sudo systemctl enable reconftw-hs.timer
sudo systemctl start reconftw-hs.timer
```

### Lock File Issues

If multi-scan won't start due to stale lock:

```bash
sudo rm /var/run/reconftw/multi-scan.lock
sudo systemctl start reconftw-hs-multi.service
```

### High Resource Usage

**Reduce resource limits:**
```bash
sudo nano /etc/systemd/system/reconftw-hs-multi.service
```

Change to:
```ini
MemoryMax=4G
CPUQuota=150%
```

**Reduce parallelism in config:**
Edit `/opt/reconftw/reconftw-hs.cfg`:
```bash
HTTPX_THREADS=5
NUCLEI_RATELIMIT=5
```

### View Failed Service Runs

```bash
# Show failed units
sudo systemctl --failed

# View specific failure details
sudo journalctl -u reconftw-hs -p err -n 50
```

## Security Considerations

### Systemd Security Features

The service includes these security hardening options:

```ini
NoNewPrivileges=true    # Prevent privilege escalation
PrivateTmp=true         # Private /tmp directory
ProtectSystem=strict    # Read-only system directories
ProtectHome=true        # Hide other users' home dirs
```

### User Isolation

- Runs as dedicated `reconftw` user (not root)
- Limited write access to `/opt/reconftw/reports` only
- No network file system access
- Resource limits prevent DoS

### Logs Security

```bash
# Restrict log file permissions
sudo chmod 640 /var/log/reconftw/*.log
sudo chown reconftw:adm /var/log/reconftw/*.log

# Set up log rotation
sudo nano /etc/logrotate.d/reconftw
```

Add:
```
/var/log/reconftw/*.log {
    daily
    rotate 7
    compress
    delaycompress
    missingok
    notifempty
    create 0640 reconftw adm
}
```

## Integration with Telegram

Telegram notifications work automatically if configured in `reconftw-hs.cfg`:

```bash
sudo -u reconftw nano /opt/reconftw/reconftw-hs.cfg
```

Set:
```bash
TELEGRAM_ENABLED=true
TELEGRAM_BOT_TOKEN="your_token"
TELEGRAM_CHAT_ID="your_chat_id"
```

Notifications will be sent for:
- Scan start/completion
- Credentials found
- Vulnerabilities discovered

## Best Practices

1. **Start with single target** to test the setup
2. **Monitor first few runs** to ensure everything works
3. **Set up log rotation** to prevent disk space issues
4. **Configure Telegram** for remote monitoring
5. **Use resource limits** to protect your system
6. **Regular backups** of `/opt/reconftw/reports`
7. **Keep targets.txt updated** with active services only
8. **Review logs weekly** for issues or findings

## Uninstallation

To remove the systemd service:

```bash
# Stop and disable services
sudo systemctl stop reconftw-hs.timer reconftw-hs-multi.timer
sudo systemctl disable reconftw-hs.timer reconftw-hs-multi.timer

# Remove service files
sudo rm /etc/systemd/system/reconftw-hs.*

# Remove configuration
sudo rm -rf /etc/reconftw

# Remove logs
sudo rm -rf /var/log/reconftw
sudo rm -rf /var/run/reconftw

# Remove installation (optional - backup reports first!)
# sudo rm -rf /opt/reconftw

# Remove user (optional)
# sudo userdel -r reconftw

# Reload systemd
sudo systemctl daemon-reload
```

## Support

For issues or questions:
- Check logs: `sudo journalctl -u reconftw-hs -f`
- Review documentation: `README-HIDDEN-SERVICES.md`
- Test manually: `sudo -u reconftw /opt/reconftw/reconftw-hs.sh -d test.onion`

---

**Remember**: Use responsibly and only scan services you have authorization to test.
