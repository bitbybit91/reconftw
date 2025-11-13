#!/bin/bash

###############################################################################################################
# Test Suite for Hidden Services Edition
# Tests core functionality without requiring actual .onion sites
###############################################################################################################

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Test result function
function test_result() {
    local test_name=$1
    local result=$2
    
    ((TESTS_RUN++))
    
    if [[ $result -eq 0 ]]; then
        echo -e "${GREEN}✓${NC} $test_name"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}✗${NC} $test_name"
        ((TESTS_FAILED++))
    fi
}

# Print header
echo "=========================================="
echo "Hidden Services Edition Test Suite"
echo "=========================================="
echo ""

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
REPO_DIR="$(dirname "$SCRIPT_DIR")"

# Source configuration and libraries
source "$REPO_DIR/reconftw-hs.cfg" 2>/dev/null || {
    echo -e "${RED}Failed to load config${NC}"
    exit 1
}

source "$REPO_DIR/lib/tor-helper.sh" 2>/dev/null || {
    echo -e "${RED}Failed to load tor-helper.sh${NC}"
    exit 1
}

source "$REPO_DIR/lib/scan4all-integration.sh" 2>/dev/null || {
    echo -e "${RED}Failed to load scan4all-integration.sh${NC}"
    exit 1
}

source "$REPO_DIR/lib/brute-integration.sh" 2>/dev/null || {
    echo -e "${RED}Failed to load brute-integration.sh${NC}"
    exit 1
}

echo "Configuration and Libraries Tests:"
echo "------------------------------------------"

# Test 1: Configuration loading
test_result "Configuration file loaded" 0

# Test 2: Check Tor is enabled in config
[[ "$TOR_ENABLED" == true ]]
test_result "Tor is enabled in configuration" $?

# Test 3: Check hidden services mode
[[ "$HIDDEN_SERVICES_MODE" == true ]]
test_result "Hidden services mode enabled" $?

echo ""
echo "Function Availability Tests:"
echo "------------------------------------------"

# Test 4: Tor helper functions available
type check_tor_service &>/dev/null
test_result "check_tor_service function exists" $?

type validate_onion_domain &>/dev/null
test_result "validate_onion_domain function exists" $?

type rotate_tor_circuit &>/dev/null
test_result "rotate_tor_circuit function exists" $?

type add_proxy_flags &>/dev/null
test_result "add_proxy_flags function exists" $?

# Test 5: scan4all integration functions
type install_scan4all &>/dev/null
test_result "install_scan4all function exists" $?

type run_scan4all_deep &>/dev/null
test_result "run_scan4all_deep function exists" $?

# Test 6: Brute integration functions
type install_brute &>/dev/null
test_result "install_brute function exists" $?

type brute_web_login &>/dev/null
test_result "brute_web_login function exists" $?

echo ""
echo "Onion Domain Validation Tests:"
echo "------------------------------------------"

# Test 7: Valid v3 onion address (56 chars + .onion)
validate_onion_domain "thehiddenwiki2345234523452345234523452345234523452abcdef.onion"
test_result "Valid v3 .onion address accepted" $?

# Test 8: Valid v2 onion address
validate_onion_domain "3g2upl4pq6kufc4m.onion"
test_result "Valid v2 .onion address accepted" $?

# Test 9: Invalid domain (not .onion)
validate_onion_domain "example.com"
if [[ $? -ne 0 ]]; then
    result=0
else
    result=1
fi
test_result "Non-.onion domain rejected" $result

# Test 10: Invalid .onion (wrong length)
validate_onion_domain "invalid.onion"
if [[ $? -ne 0 ]]; then
    result=0
else
    result=1
fi
test_result "Invalid .onion format rejected" $result

echo ""
echo "Proxy Configuration Tests:"
echo "------------------------------------------"

# Test 11: Proxy flags for httpx
flags=$(add_proxy_flags "httpx")
[[ "$flags" == *"proxy"* ]]
test_result "httpx proxy flags generated" $?

# Test 12: Proxy flags for nuclei
flags=$(add_proxy_flags "nuclei")
[[ "$flags" == *"proxy"* ]]
test_result "nuclei proxy flags generated" $?

# Test 13: Proxy flags for ffuf
flags=$(add_proxy_flags "ffuf")
[[ "$flags" == *"-x"* ]]
test_result "ffuf proxy flags generated" $?

# Test 14: Proxy flags for sqlmap
flags=$(add_proxy_flags "sqlmap")
[[ "$flags" == *"--proxy"* ]] && [[ "$flags" == *"--tor"* ]]
test_result "sqlmap proxy flags generated" $?

echo ""
echo "File and Script Tests:"
echo "------------------------------------------"

# Test 15: Main hidden services script exists
[[ -f "$REPO_DIR/reconftw-hs.sh" ]]
test_result "reconftw-hs.sh exists" $?

# Test 16: Installation script exists
[[ -f "$REPO_DIR/install-hs.sh" ]]
test_result "install-hs.sh exists" $?

# Test 17: Scripts are executable
[[ -x "$REPO_DIR/reconftw-hs.sh" ]]
test_result "reconftw-hs.sh is executable" $?

[[ -x "$REPO_DIR/install-hs.sh" ]]
test_result "install-hs.sh is executable" $?

# Test 18: Library scripts are executable
[[ -x "$REPO_DIR/lib/tor-helper.sh" ]]
test_result "lib/tor-helper.sh is executable" $?

[[ -x "$REPO_DIR/lib/scan4all-integration.sh" ]]
test_result "lib/scan4all-integration.sh is executable" $?

[[ -x "$REPO_DIR/lib/brute-integration.sh" ]]
test_result "lib/brute-integration.sh is executable" $?

echo ""
echo "Documentation Tests:"
echo "------------------------------------------"

# Test 19: README exists
[[ -f "$REPO_DIR/README-HIDDEN-SERVICES.md" ]]
test_result "README-HIDDEN-SERVICES.md exists" $?

# Test 20: README has content
[[ -s "$REPO_DIR/README-HIDDEN-SERVICES.md" ]]
test_result "README-HIDDEN-SERVICES.md has content" $?

echo ""
echo "Configuration Validation Tests:"
echo "------------------------------------------"

# Test 21: Timeout values are appropriate for .onion
[[ ${REQUEST_TIMEOUT:-0} -ge 60 ]]
test_result "REQUEST_TIMEOUT is suitable for .onion (>=60s)" $?

# Test 22: Thread counts are conservative
[[ ${HTTPX_THREADS:-100} -le 50 ]]
test_result "HTTPX_THREADS is conservative (<=50)" $?

# Test 23: Rate limiting is configured
[[ ${NUCLEI_RATELIMIT:-0} -gt 0 ]]
test_result "NUCLEI_RATELIMIT is configured" $?

# Test 24: Deep mode is enabled
[[ "$DEEP" == true ]]
test_result "DEEP mode is enabled" $?

# Test 25: Irrelevant modules are disabled
[[ "$SUBDOMAINS_GENERAL" == false ]]
test_result "Subdomain enumeration is disabled" $?

[[ "$GOOGLE_DORKS" == false ]]
test_result "Google dorks are disabled" $?

echo ""
echo "=========================================="
echo "Test Results Summary"
echo "=========================================="
echo -e "Total Tests Run:    ${YELLOW}${TESTS_RUN}${NC}"
echo -e "Tests Passed:       ${GREEN}${TESTS_PASSED}${NC}"
echo -e "Tests Failed:       ${RED}${TESTS_FAILED}${NC}"
echo ""

if [[ $TESTS_FAILED -eq 0 ]]; then
    echo -e "${GREEN}✓ All tests passed!${NC}"
    exit 0
else
    echo -e "${RED}✗ Some tests failed${NC}"
    exit 1
fi
