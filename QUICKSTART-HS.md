# Quick Start Guide - Hidden Services Edition

This guide will help you get started with reconFTW Hidden Services Edition in under 5 minutes.

## Prerequisites

- Ubuntu 20.04 LTS or later
- Root/sudo access
- Stable internet connection

## Installation (5 minutes)

```bash
# 1. Clone the repository
git clone https://github.com/bitbybit91/reconftw.git
cd reconftw

# 2. Run the hidden services installer
chmod +x install-hs.sh
./install-hs.sh

# 3. Wait for installation to complete (~5 minutes)
# The script will:
# - Install Tor and configure it
# - Install Privoxy for HTTP proxy
# - Install all reconnaissance tools
# - Configure the system for .onion scanning

# 4. Verify Tor is working
curl --socks5 127.0.0.1:9050 https://check.torproject.org/
```

## Basic Usage

### Scan a hidden service

```bash
# Basic scan
./reconftw-hs.sh -d example.onion

# The scan will:
# ✓ Initialize Tor connection
# ✓ Validate the .onion address
# ✓ Test connectivity
# ✓ Probe web service
# ✓ Detect technologies
# ✓ Fuzz directories
# ✓ Scan for vulnerabilities
# ✓ Run brute force attacks
# ✓ Generate reports
```

### Output Location

Results are saved in:
```
~/reconftw-output/example.onion/
```

### View Results

```bash
cd ~/reconftw-output/example.onion/

# View vulnerability scan results
cat nuclei/results.txt

# View discovered directories
cat fuzz/directories.json | jq

# View technology detection
cat tech_detection.txt

# View brute force results
cat brute/web_login.txt
```

## Configuration

Edit `reconftw-hs.cfg` to customize:

```bash
# Enable/disable modules
NUCLEICHECK=true
FUZZ=true
BRUTE_ENABLED=true
SCAN4ALL_ENABLED=true

# Adjust timeouts for slow .onion sites
REQUEST_TIMEOUT=180
HTTPX_TIMEOUT=180

# Adjust threading for stealth/speed
HTTPX_THREADS=5    # Stealth (slower)
HTTPX_THREADS=20   # Speed (faster, more detectable)
```

## Testing Your Setup

```bash
# Run the test suite
./tests/test-hidden-services.sh

# Should show: "✓ All tests passed!"
```

## Common Commands

### Check Tor Status
```bash
systemctl status tor
```

### Restart Tor
```bash
sudo systemctl restart tor
```

### View Tor IP
```bash
curl --socks5 127.0.0.1:9050 https://api.ipify.org
```

### Test .onion Connectivity
```bash
curl --socks5 127.0.0.1:9050 --socks5-hostname 127.0.0.1:9050 http://example.onion
```

## Troubleshooting

### Tor Not Working
```bash
# Check Tor logs
sudo tail -f /var/log/tor/notices.log

# Restart Tor
sudo systemctl restart tor

# Wait 10 seconds, then test
curl --socks5 127.0.0.1:9050 https://check.torproject.org/
```

### Connection Timeouts
Increase timeouts in config:
```bash
REQUEST_TIMEOUT=300
HTTPX_TIMEOUT=300
```

### Scan Too Slow
Increase threads (less stealthy):
```bash
HTTPX_THREADS=20
NUCLEI_RATELIMIT=20
```

### Scan Too Fast (Getting Blocked)
Decrease threads:
```bash
HTTPX_THREADS=5
NUCLEI_RATELIMIT=5
RATE_LIMIT_DELAY=5
```

## Important Notes

⚠️ **Legal Warning**: Only scan services you have permission to test.

⚠️ **Stealth**: Lower thread counts = more stealthy but slower scans

⚠️ **Timeouts**: .onion sites are slow, be patient with timeouts

✅ **Circuit Rotation**: Tor circuits rotate automatically every 5 minutes

✅ **No DNS Leaks**: All traffic goes through Tor

## Example Workflow

```bash
# 1. Install (first time only)
./install-hs.sh

# 2. Verify Tor works
curl --socks5 127.0.0.1:9050 https://check.torproject.org/

# 3. Run scan
./reconftw-hs.sh -d example.onion

# 4. Wait for completion (can take 30-60 minutes)

# 5. Review results
cd ~/reconftw-output/example.onion/
ls -la

# 6. Check vulnerabilities
cat nuclei/results.txt | grep -i critical
```

## Next Steps

- Read the full [README-HIDDEN-SERVICES.md](README-HIDDEN-SERVICES.md)
- Customize your `reconftw-hs.cfg`
- Learn about scan4all and Brute integration
- Understand OPSEC and stealth considerations

## Getting Help

- Check logs: `tail -f ~/reconftw-output/example.onion/reconftw.log`
- Run tests: `./tests/test-hidden-services.sh`
- Review docs: `README-HIDDEN-SERVICES.md`
- Open an issue on GitHub

---

**Happy hunting! Use responsibly and legally.**
