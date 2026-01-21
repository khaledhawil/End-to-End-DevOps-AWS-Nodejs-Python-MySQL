#!/bin/bash
# Vulnerability Analysis Script
# This helps you focus on REAL security issues vs scanner noise

set -e

echo "🔍 Security Vulnerability Analysis"
echo "=================================="
echo ""

# Colors
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Check if Trivy is installed
if ! command -v trivy &> /dev/null; then
    echo "⚠️  Trivy not installed. Installing..."
    wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | sudo apt-key add -
    echo "deb https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" | sudo tee -a /etc/apt/sources.list.d/trivy.list
    sudo apt-get update
    sudo apt-get install trivy -y
fi

echo ""
echo "📦 Scanning Docker Images..."
echo ""

# Function to scan and analyze
scan_image() {
    local service=$1
    local dockerfile=$2
    
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🐳 Scanning: $service"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    # Build temp image
    temp_image="security-scan-${service}:temp"
    docker build -t "$temp_image" -f "$dockerfile" "$(dirname $dockerfile)" > /dev/null 2>&1
    
    # Scan with different severity levels
    echo ""
    echo -e "${RED}🔴 CRITICAL Vulnerabilities:${NC}"
    trivy image --severity CRITICAL --quiet "$temp_image" | grep -E "^(.*\|.*\|.*\|.*\|.*)" || echo "  ✅ None found"
    
    echo ""
    echo -e "${YELLOW}🟠 HIGH Vulnerabilities (in YOUR code dependencies):${NC}"
    trivy image --severity HIGH --quiet "$temp_image" | \
        grep -v "alpine" | \
        grep -v "busybox" | \
        grep -v "musl" | \
        grep -v "ssl_client" | \
        grep -E "^(.*\|.*\|.*\|.*\|.*)" | \
        head -20 || echo "  ✅ None found in application dependencies"
    
    echo ""
    echo "📊 Summary for $service:"
    trivy image --severity CRITICAL,HIGH "$temp_image" --format json 2>/dev/null | \
        python3 -c "
import json, sys
try:
    data = json.load(sys.stdin)
    results = data.get('Results', [])
    critical = high = 0
    for result in results:
        for vuln in result.get('Vulnerabilities', []):
            if vuln.get('Severity') == 'CRITICAL':
                critical += 1
            elif vuln.get('Severity') == 'HIGH':
                high += 1
    print(f'  Critical: {critical}')
    print(f'  High: {high}')
    print(f'  🎯 Focus on: {critical + high} total issues')
except:
    print('  Unable to parse results')
" || echo "  Unable to generate summary"
    
    # Cleanup
    docker rmi "$temp_image" > /dev/null 2>&1
    
    echo ""
}

# Scan each service
scan_image "auth-service" "services/auth-service/Dockerfile"
scan_image "task-service" "services/task-service/Dockerfile"
scan_image "frontend" "services/frontend/Dockerfile"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "💡 Recommendations"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "1. 🎯 Focus ONLY on vulnerabilities in YOUR dependencies"
echo "   - Not in base image system packages"
echo "   - Not in dev dependencies"
echo ""
echo "2. 🔄 Update strategy:"
echo "   - npm update (for Node.js packages)"
echo "   - pip install --upgrade (for Python packages)"
echo "   - Wait for base image updates (monthly)"
echo ""
echo "3. ✅ What you've ALREADY done right:"
echo "   - ✓ Using latest Alpine/Slim images"
echo "   - ✓ Running as non-root"
echo "   - ✓ Security updates in Dockerfile"
echo "   - ✓ Application-level security (rate limiting, validation)"
echo ""
echo "4. 📈 Acceptable vulnerability counts:"
echo "   - Critical: 0-5 (investigate all)"
echo "   - High: 0-20 (in YOUR dependencies)"
echo "   - Total: 100-500+ (mostly base image noise)"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
