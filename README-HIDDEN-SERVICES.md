# reconFTW - Hidden Services Edition

## Overview

This is a specialized version of reconFTW optimized for **Ubuntu VPS** environments and specifically designed for reconnaissance of **hidden services** (.onion sites on the Tor network). This edition integrates functionality from:

- **[scan4all](https://github.com/GhostTroops/scan4all)** - Comprehensive vulnerability scanner
- **[Brute](https://github.com/1N3/Brute)** - Brute force attack framework

The tool has been enhanced to work seamlessly with Tor proxy, handle system hardening, and focus solely on functionalities relevant to hidden services reconnaissance.

## Key Features

### Hidden Services Specific
- ✅ **Tor Integration** - Automatic Tor proxy configuration and circuit rotation
- ✅ **.onion Validation** - Validates v2 and v3 onion addresses
- ✅ **Stealth Mode** - Optimized for reconnaissance without detection
- ✅ **System Hardening Bypass** - Works with AppArmor, SELinux, and firewall restrictions
- ✅ **Extended Timeouts** - Configured for slow .onion connections
- ✅ **Conservative Threading** - Reduced thread counts to avoid detection

### Integrated Scanning Capabilities
- ✅ **scan4all Integration** - Deep vulnerability scanning through Tor
- ✅ **Brute Force Attacks** - Login brute forcing for web, SSH, FTP, HTTP Basic Auth
- ✅ **Web Fuzzing** - Directory and file discovery
- ✅ **Nuclei Scanning** - Vulnerability templates through Tor proxy
- ✅ **SQL Injection Testing** - SQLMap integration with Tor
- ✅ **Technology Detection** - Identify web frameworks and technologies

### Removed/Disabled Features
- ❌ DNS enumeration (not applicable to .onion)
- ❌ Subdomain discovery (not applicable to .onion)
- ❌ Certificate transparency (not applicable to .onion)
- ❌ Cloud storage enumeration (not applicable to .onion)
- ❌ WHOIS/GeoIP lookups (not applicable to .onion)
- ❌ External API integrations (most don't support .onion)

## System Requirements

### Operating System
- **Ubuntu 20.04 LTS or later** (tested on Ubuntu 24.04 LTS)
- Debian-based distributions may work but are not officially supported

### Hardware Requirements
- **CPU**: 2+ cores recommended
- **RAM**: 4GB minimum, 8GB recommended
- **Disk**: 20GB free space minimum
- **Network**: Stable internet connection for Tor

### Software Dependencies
- Bash 4.0+
- Tor
- Privoxy
- Python 3.8+
- Golang 1.19+
- Standard reconnaissance tools (installed automatically)

## Installation

### Quick Installation

```bash
# Clone the repository
git clone https://github.com/bitbybit91/reconftw.git
cd reconftw

# Run the hidden services installation script
chmod +x install-hs.sh
./install-hs.sh
```

### Manual Installation

```bash
# Install Tor and Privoxy
sudo apt update
sudo apt install -y tor privoxy

# Configure Tor
sudo nano /etc/tor/torrc
# Add: SocksPort 9050
# Add: ControlPort 9051

# Configure Privoxy
echo "forward-socks5t / 127.0.0.1:9050 ." | sudo tee -a /etc/privoxy/config

# Restart services
sudo systemctl restart tor
sudo systemctl restart privoxy

# Run standard reconftw installation
./install.sh

# Verify Tor connection
curl --socks5 127.0.0.1:9050 https://check.torproject.org/
```

## Configuration

The hidden services edition uses `reconftw-hs.cfg` for configuration. Key settings:

```bash
# Enable hidden services mode
HIDDEN_SERVICES_MODE=true
TOR_ENABLED=true

# Tor proxy settings
TOR_PROXY="socks5://127.0.0.1:9050"
TOR_HTTP_PROXY="http://127.0.0.1:8118"

# Timeouts (longer for .onion)
REQUEST_TIMEOUT=120
HTTPX_TIMEOUT=120
FFUF_MAXTIME=1800

# Conservative threading
HTTPX_THREADS=10
NUCLEI_RATELIMIT=10
FFUF_THREADS=10

# scan4all integration
SCAN4ALL_ENABLED=true
SCAN4ALL_DEEP=true
SCAN4ALL_POC=true

# Brute force settings
BRUTE_ENABLED=true
BRUTE_THREADS=10
BRUTE_DELAY=1
```

## Usage

### Basic Scan

```bash
./reconftw-hs.sh -d example.onion
```

### With Custom Configuration

```bash
./reconftw-hs.sh -d example.onion -c custom-config.cfg
```

### Help

```bash
./reconftw-hs.sh --help
```

## Workflow

The tool follows this reconnaissance workflow:

```
1. Tor Initialization
   ├─ Check Tor service status
   ├─ Start Tor if needed
   ├─ Verify Tor connection
   └─ Setup proxy environment

2. Target Validation
   ├─ Validate .onion format
   └─ Test connectivity to target

3. Web Reconnaissance
   ├─ HTTP/HTTPS probing
   ├─ Technology detection
   ├─ Screenshot capture (if possible)
   └─ Web server fingerprinting

4. Content Discovery
   ├─ Directory fuzzing
   ├─ File enumeration
   └─ Robots.txt analysis

5. Vulnerability Scanning
   ├─ Nuclei template scanning
   ├─ scan4all deep scan
   ├─ SQL injection testing
   ├─ XSS detection
   ├─ SSRF checks
   └─ Other web vulnerabilities

6. Brute Force Attacks
   ├─ Web login forms
   ├─ HTTP Basic Auth
   ├─ FTP (if exposed)
   └─ SSH (if exposed)

7. Report Generation
   └─ Comprehensive HTML/JSON reports
```

## Output Structure

```
reconftw-output/
└── example.onion/
    ├── reconftw.log              # Main log file
    ├── webprobe.json             # Web probing results
    ├── tech_detection.txt        # Technology fingerprinting
    ├── screenshots/              # Website screenshots
    ├── fuzz/                     # Fuzzing results
    │   └── directories.json
    ├── nuclei/                   # Vulnerability scan results
    │   └── results.txt
    ├── scan4all/                 # scan4all integration results
    │   ├── web/
    │   ├── vulns/
    │   └── deep/
    ├── brute/                    # Brute force results
    │   ├── web_login.txt
    │   ├── http_basic.txt
    │   └── ftp.txt
    └── sqli/                     # SQL injection results
        └── sqlmap_output/
```

## Security Considerations

### Stealth and OPSEC

1. **Always use Tor** - The tool enforces Tor proxy for all connections
2. **Circuit Rotation** - Tor circuits are rotated periodically
3. **Rate Limiting** - Conservative rate limits to avoid detection
4. **User Agent Rotation** - Mimics legitimate Tor Browser traffic
5. **No DNS Leaks** - All DNS queries go through Tor

### System Hardening Compatibility

The tool is designed to work with common security hardening:
- AppArmor profiles
- SELinux policies
- UFW/iptables firewall rules
- Restricted file permissions

### Legal Disclaimer

⚠️ **IMPORTANT**: This tool is designed for **authorized security testing only**.

- Accessing hidden services may be illegal in some jurisdictions
- Unauthorized reconnaissance and penetration testing is illegal
- Always obtain proper authorization before testing any system
- The developers assume no liability for misuse of this tool
- Use responsibly and ethically

## Troubleshooting

### Tor Connection Issues

```bash
# Check Tor status
systemctl status tor

# Test Tor connection
curl --socks5 127.0.0.1:9050 https://check.torproject.org/

# View Tor logs
sudo tail -f /var/log/tor/notices.log

# Restart Tor
sudo systemctl restart tor
```

### Proxy Errors

```bash
# Check Privoxy status
systemctl status privoxy

# Test HTTP proxy
curl --proxy http://127.0.0.1:8118 https://check.torproject.org/

# Restart Privoxy
sudo systemctl restart privoxy
```

### Connection Timeouts

Hidden services are often slow. If you experience timeouts:

1. Increase timeout values in config:
   ```bash
   REQUEST_TIMEOUT=180
   HTTPX_TIMEOUT=180
   ```

2. Reduce thread counts:
   ```bash
   HTTPX_THREADS=5
   NUCLEI_RATELIMIT=5
   ```

3. Enable circuit rotation more frequently:
   ```bash
   CIRCUIT_ROTATION_INTERVAL=180
   ```

### Installation Issues

```bash
# Reinstall dependencies
./install-hs.sh

# Check missing tools
./reconftw.sh --check-tools

# Update tools
./install.sh --update
```

## Integration Details

### scan4all Integration

scan4all provides comprehensive vulnerability scanning:
- Port scanning through Tor
- Web application scanning
- Vulnerability detection with POCs
- Deep scanning mode for thorough analysis

Configuration:
```bash
SCAN4ALL_ENABLED=true
SCAN4ALL_DEEP=true      # Enable deep scanning
SCAN4ALL_POC=true       # Run proof-of-concept exploits
```

### Brute Integration

Brute provides brute force capabilities:
- Web login form brute forcing
- HTTP Basic Auth attacks
- FTP credential guessing
- SSH authentication testing (not recommended over Tor)

Configuration:
```bash
BRUTE_ENABLED=true
BRUTE_WORDLIST="${tools}/wordlists/passwords.txt"
BRUTE_USERLIST="${tools}/wordlists/users.txt"
BRUTE_THREADS=10
BRUTE_DELAY=1
```

## Performance Tuning

### For Fast Scanning
```bash
HTTPX_THREADS=20
NUCLEI_RATELIMIT=20
FFUF_THREADS=20
REQUEST_TIMEOUT=60
```

### For Stealth Scanning
```bash
HTTPX_THREADS=5
NUCLEI_RATELIMIT=5
FFUF_THREADS=5
REQUEST_TIMEOUT=180
RATE_LIMIT_DELAY=5
```

### For Tor Stability
```bash
CIRCUIT_ROTATION_INTERVAL=300
MAX_RETRIES=5
REQUEST_TIMEOUT=120
```

## Contributing

Contributions are welcome! Areas of interest:
- Additional hidden services specific modules
- Improved Tor integration
- Better stealth techniques
- System hardening bypass methods
- Bug fixes and optimizations

## License

This project inherits the MIT License from the original reconFTW project.

## Credits

- **Original reconFTW**: [@six2dez](https://github.com/six2dez)
- **scan4all**: [GhostTroops](https://github.com/GhostTroops)
- **Brute**: [1N3](https://github.com/1N3)
- **Tor Project**: [torproject.org](https://www.torproject.org)

## Support

For issues specific to hidden services functionality:
- Open an issue on GitHub
- Include logs from `reconftw.log`
- Describe your environment and configuration
- Do not include actual .onion addresses without permission

## Changelog

### Version 1.0 (Hidden Services Edition)
- Initial release
- Tor proxy integration
- scan4all integration
- Brute integration
- Ubuntu VPS optimization
- System hardening compatibility
- .onion specific configuration
- Extended timeouts and conservative threading
- Comprehensive documentation

---

**Remember**: Use this tool responsibly and legally. Always obtain proper authorization before testing any system.
