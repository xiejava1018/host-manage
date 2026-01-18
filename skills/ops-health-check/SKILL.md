---
name: ops-health-check
description: "Comprehensive system health monitoring for Linux hosts. Use for: system resources check (CPU, memory, disk, network), Docker monitoring (containers, images, volumes), service status verification, security checks (mining, malware, intrusions), deep security analysis, health report generation. Triggers: health check, system status, check host, monitor server, docker status, container check, security check"
---

# Ops Health Check

## Overview

Perform automated health checks on Linux hosts to monitor system resources, Docker containers, service status, and security indicators. Generate **Markdown** and **JSON** format reports with status indicators (✅正常/⚠️警告/❌严重) based on configurable thresholds.

Includes **basic health check**, **deep security check**, and **Docker monitoring** capabilities with dual-format output (Markdown + JSON).

## Quick Start

### Basic Health Check

```bash
# Remote host check via SSH
ssh <host-ip> 'bash -s' < scripts/health-check.sh

# Example
ssh 192.168.0.42 'bash -s' < scripts/ops-health-check/scripts/health-check.sh
```

### Deep Security Check

```bash
# Run comprehensive security analysis
ssh <host-ip> 'bash -s' < scripts/security-check.sh

# Example
ssh 192.168.0.42 'bash -s' < scripts/ops-health-check/scripts/security-check.sh
```

### Docker Monitoring

```bash
# Check Docker containers, images, volumes
ssh <host-ip> 'bash -s' < scripts/docker-check.sh

# Example
ssh 192.168.0.42 'bash -s' < scripts/ops-health-check/scripts/docker-check.sh
```

### Local Host Check

```bash
# Basic check
bash scripts/ops-health-check/scripts/health-check.sh

# Security check
bash scripts/ops-health-check/scripts/security-check.sh

# Docker check
bash scripts/ops-health-check/scripts/docker-check.sh
```

## What Gets Checked

### System Resources
- **Uptime & Load**: System uptime and 1/5/15 minute load averages
- **Memory**: RAM usage (total/used/available) and swap usage with percentage
- **Disk**: All mounted filesystems with usage percentages
- **Network**: Active connections and listening ports

### Services
- Running systemd services count
- Failed services count
- (Requires systemd)

### Docker Monitoring
Run `scripts/docker-check.sh` for comprehensive Docker monitoring:

**Docker Service**
- Service status and version
- Root directory and system info

**容器状态概览 (Container Status)**
- Total, running, and stopped container counts
- Detailed container list with status
- Resource usage Top 5 (CPU, memory)

**镜像信息 (Image Information)**
- Total image count
- Dangling (unused) image detection
- Image list with sizes

**网络和卷 (Networks and Volumes)**
- Network list and count
- Volume list and count
- Unused volume detection

**存储空间 (Storage)**
- System storage usage (images, containers, volumes, build cache)
- Cleanup recommendations

### Security (Basic)
- Mining process detection (xmrig, minerd, cpuminer)
- Executable files in /tmp
- Recent failed login attempts

### Deep Security Check

Run `scripts/security-check.sh` for comprehensive security analysis:

**异常进程检测 (Anomalous Process Detection)**
- High CPU/memory usage processes
- Mining processes (extended detection list)
- Suspicious process names
- Processes running from /tmp or /dev/shm

**网络连接安全 (Network Security)**
- Reverse shell detection
- High-risk port monitoring
- External connection statistics

**文件系统安全 (File System Security)**
- Recently modified files (configurable time range)
- SUID/SGID executable files
- Executable files in temp directories
- Ransomware indicators (.encrypted, .locked, .crypto)

**账户和登录安全 (Account & Login Security)**
- Recent login history (last 10 logins)
- Failed login statistics
- Current logged-in users
- New user detection (last 30 days)
- Sudo usage logs

**系统完整性 (System Integrity)**
- Recent /etc directory changes (last 7 days)
- Critical config file permissions
- Key file ownership verification

## Report Format

### Dual Format Output

Each check generates **two** report files automatically:

1. **Markdown** (.md) - Human-readable format with emoji status indicators
2. **JSON** (.json) - Machine-processable format for APIs and monitoring systems

Example output files:
```
health-reports/
├── health-check-192.168.0.42-20250118-162008.md
└── health-check-192.168.0.42-20250118-162008.json
```

### Status Indicators

Both formats use consistent status indicators:
- **✅正常** (OK) - All metrics within normal thresholds
- **⚠️警告** (WARNING) - Exceeds warning threshold, needs attention
- **❌严重** (CRITICAL) - Exceeds critical threshold, immediate action required

### JSON Structure

```json
{
  "summary": {
    "host": {
      "hostname": "server-01",
      "ip": "192.168.0.42",
      "check_time": "2025-01-18T16:20:08+0800"
    },
    "overall_status": "ok",
    "status_counts": {
      "ok": 15,
      "warning": 2,
      "critical": 0
    }
  },
  "details": {
    "system": { ... },
    "memory": { ... },
    "disk": [ ... ],
    "services": { ... }
  },
  "metadata": {
    "check_version": "1.0",
    "tool_version": "ops-health-check v1.0",
    "thresholds": { ... }
  }
}
```

The JSON format includes:
- **summary**: Quick overview for alerting and trend analysis
- **details**: Complete system metrics in hierarchical structure
- **metadata**: Check configuration and version information

## Customizing Thresholds

Set environment variables before running:

```bash
# Example thresholds
DISK_WARNING=50 DISK_CRITICAL=80 \
MEMORY_WARNING=70 MEMORY_CRITICAL=90 \
CPU_LOAD_WARNING=200 CPU_LOAD_CRITICAL=500 \
ssh <host-ip> 'bash -s' < scripts/health-check.sh
```

Default thresholds:
- Disk: 50% warning, 80% critical
- Memory: 70% warning, 90% critical
- CPU Load: 2.0 warning, 5.0 critical

## Using This Skill

When a user requests health checks or system monitoring:

1. **Identify target host(s)** - Get IP address or hostname
2. **Run the script** via SSH for remote, or locally for current host
3. **Review the report** - Check for WARNING or CRITICAL indicators
4. **Take action** if any metrics exceed thresholds

### Using JSON Output

The JSON format enables programmatic analysis and integration:

```bash
# Query overall status
jq '.summary.overall_status' health-reports/*.json

# Extract memory usage percentage
jq '.details.memory.used_percent' health-reports/health-check-*.json

# Find all hosts with warnings
for json in health-reports/*.json; do
  hostname=$(jq -r '.summary.host.hostname' "$json")
  status=$(jq -r '.summary.overall_status' "$json")
  if [ "$status" != "ok" ]; then
    echo "$hostname: $status"
  fi
done

# Send to monitoring API
curl -X POST http://monitoring/api/metrics \
  -H "Content-Type: application/json" \
  -d @health-reports/health-check-*.json

# Generate summary table
jq -r '[.summary.host.hostname, .summary.overall_status] | @tsv' \
  health-reports/*.json
```

### Common Workflows

**Single host basic check**:
```
User: "Check the health of 192.168.0.42"
→ Execute: ssh 192.168.0.42 'bash -s' < scripts/health-check.sh
```

**Single host security check**:
```
User: "Do a security scan of 192.168.0.42"
→ Execute: ssh 192.168.0.42 'bash -s' < scripts/security-check.sh
```

**Single host Docker check**:
```
User: "Check Docker on 192.168.0.42"
→ Execute: ssh 192.168.0.42 'bash -s' < scripts/docker-check.sh
```

**Multiple hosts**:
```
User: "Check all my servers"
→ Loop through host list and run script for each
→ Aggregate results or present individually
```

**Save report**:
```
User: "Save the health report to a file"
→ Redirect output: ssh <host> 'bash -s' < script.sh > report.md
```

## Notes

- Script uses standard Linux commands: `free`, `df`, `uptime`, `ss`, `systemctl`, `last`, `find`, `docker`
- Requires Bash and basic Unix utilities
- Docker check requires Docker to be installed and user needs Docker access permissions
- Emoji status indicators work everywhere (terminal, files, web)
- Deep security check may take 30-60 seconds depending on system size
- Security check requires root privileges for complete analysis

## Security Check Configuration

Customize security check behavior:

```bash
# Check specific directories (default: /tmp /dev/shm /var/tmp)
CHECK_DIRS="/tmp /var/tmp /home"

# Set time range for recent file checks (default: 24 hours)
RECENT_HOURS=48

# Set thresholds for suspicious processes
MAX_CPU_PERCENT=80
MAX_MEM_PERCENT=50
```

## Limitations

Current version includes:
- ✅ Basic system health monitoring
- ✅ Deep security checks
- ✅ Docker container monitoring (detailed stats, images, volumes, networks)
- ✅ Markdown reports with emoji status
- ✅ JSON output format for programmatic processing
- ❌ Multi-host configuration files
- ❌ Historical tracking
- ❌ Alert notifications

Future versions will add:
- Multi-host configuration files (YAML-based)
- Historical tracking and trend analysis
- Alert notifications (email, DingTalk, WeChat)
