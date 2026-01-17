#!/bin/bash

# Health Check Script for Linux Hosts
# Checks basic system resources: uptime, load, memory, disk, network

set -euo pipefail

# Default thresholds
DISK_WARNING=${DISK_WARNING:-50}
DISK_CRITICAL=${DISK_CRITICAL:-80}
MEMORY_WARNING=${MEMORY_WARNING:-70}
MEMORY_CRITICAL=${MEMORY_CRITICAL:-90}
CPU_LOAD_WARNING=${CPU_LOAD_WARNING:-200}   # Using integer (2.0 * 100)
CPU_LOAD_CRITICAL=${CPU_LOAD_CRITICAL:-500} # Using integer (5.0 * 100)

# Colors for output
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Function to check status
check_status() {
    local value=$1
    local warning=$2
    local critical=$3

    if [ "$value" -ge "$critical" ]; then
        echo -e "${RED}CRITICAL${NC}"
    elif [ "$value" -ge "$warning" ]; then
        echo -e "${YELLOW}WARNING${NC}"
    else
        echo -e "${GREEN}OK${NC}"
    fi
}

# Start output
echo "# System Health Check Report"
echo ""
echo "**Check Time**: $(date '+%Y-%m-%d %H:%M:%S')"
echo "**Host**: $(hostname)"
echo "**IP**: $(hostname -I | awk '{print $1}')"
echo ""

# 1. System Uptime and Load
echo "## 💻 System Overview"
echo ""
echo "### Uptime & Load"
uptime_output=$(uptime)
uptime_clean=$(echo "$uptime_output" | sed 's/^ *//g')
echo "- **Uptime**: $(uptime -p 2>/dev/null || echo "$uptime_clean" | awk -F'up ' '{print $2}' | awk -F',' '{print $1}')"
echo "- **Load Average**: $(echo "$uptime_clean" | awk -F'load average:' '{print $2}' | sed 's/^ *//g')"
echo ""

# 2. Memory Check
echo "### Memory Usage"
memory_info=$(free -m | grep Mem)
mem_total=$(echo $memory_info | awk '{print $2}')
mem_used=$(echo $memory_info | awk '{print $3}')
mem_avail=$(echo $memory_info | awk '{print $7}')
mem_percent=$(awk "BEGIN {printf \"%.1f\", $mem_used * 100 / $mem_total}")

swap_info=$(free -m | grep Swap)
swap_total=$(echo $swap_info | awk '{print $2}')
swap_used=$(echo $swap_info | awk '{print $3}')

if [ "$swap_total" -gt 0 ]; then
    swap_percent=$(awk "BEGIN {printf \"%.1f\", $swap_used * 100 / $swap_total}")
else
    swap_percent=0
fi

mem_status=$(check_status ${mem_percent%.*} $MEMORY_WARNING $MEMORY_CRITICAL)
echo "- **Memory**: ${mem_used}MB / ${mem_total}MB (${mem_percent}%) - $mem_status"
echo "- **Swap**: ${swap_used}MB / ${swap_total}MB (${swap_percent}%)"
echo ""

# 3. Disk Check
echo "### Disk Space"
echo ""
echo "| Filesystem | Size | Used | Available | Use% | Mount Point | Status |"
echo "|------------|------|------|-----------|-----|-------------|--------|"

df -h | grep -vE '^Filesystem|tmpfs|overlay|none' | while read line; do
    filesystem=$(echo $line | awk '{print $1}')
    size=$(echo $line | awk '{print $2}')
    used=$(echo $line | awk '{print $3}')
    avail=$(echo $line | awk '{print $4}')
    use_percent=$(echo $line | awk '{print $5}' | sed 's/%//')
    mount=$(echo $line | awk '{print $6}')

    status=$(check_status $use_percent $DISK_WARNING $DISK_CRITICAL)
    echo "| $filesystem | $size | $used | $avail | ${use_percent}% | $mount | $status |"
done
echo ""

# 4. Network Connections
echo "### Network"
echo ""
conn_count=$(ss -tun 2>/dev/null | wc -l)
listening_count=$(ss -tln 2>/dev/null | grep LISTEN | wc -l)
echo "- **Active Connections**: $conn_count"
echo "- **Listening Ports**: $listening_count"
echo ""

# 5. Running Services Summary
echo "## 🔧 Services Summary"
echo ""
if command -v systemctl &> /dev/null; then
    failed_count=$(systemctl list-units --type=service --state=failed 2>/dev/null | grep -c "loaded" || echo 0)
    running_count=$(systemctl list-units --type=service --state=running 2>/dev/null | grep -c "loaded" || echo 0)
    echo "- **Running Services**: $running_count"
    echo "- **Failed Services**: $failed_count"
else
    echo "Service status not available (systemd not found)"
fi
echo ""

# 6. Security Quick Check
echo "## 🔒 Quick Security Check"
echo ""

# Check for suspicious processes
mining_procs=$(ps aux 2>/dev/null | grep -E 'xmrig|minerd|cpuminer' | grep -v grep || true)
if [ -n "$mining_procs" ]; then
    echo "⚠️ **WARNING**: Potential mining processes detected"
else
    echo "✅ **OK**: No mining processes detected"
fi

# Check for executables in /tmp
tmp_exec=$(find /tmp -type f -executable 2>/dev/null | wc -l)
if [ "$tmp_exec" -gt 0 ]; then
    echo "⚠️ **WARNING**: $tmp_exec executable files in /tmp"
else
    echo "✅ **OK**: No executable files in /tmp"
fi

# Check recent failed logins
if [ -f /var/log/auth.log ]; then
    failed_logins=$(grep "Failed password" /var/log/auth.log 2>/dev/null | tail -10 | wc -l || echo 0)
    echo "- **Recent Failed Logins**: $failed_logins (last 10 in auth.log)"
elif [ -f /var/log/secure ]; then
    failed_logins=$(grep "Failed password" /var/log/secure 2>/dev/null | tail -10 | wc -l || echo 0)
    echo "- **Recent Failed Logins**: $failed_logins (last 10 in secure)"
fi
echo ""

# Footer
echo "---"
echo ""
echo "**Report Generated**: $(date '+%Y-%m-%d %H:%M:%S')"
echo "**Check Tool**: ops-health-check v1.0 (MVP)"
