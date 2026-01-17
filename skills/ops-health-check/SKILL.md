---
name: ops-health-check
description: "Comprehensive system health monitoring for Linux hosts. Use for: system resources check (CPU, memory, disk, network), service status verification, security checks (mining, malware, intrusions), deep security analysis, health report generation. Triggers: health check, system status, check host, monitor server, server health, security check"
---

# Ops Health Check

## Overview

Perform automated health checks on Linux hosts to monitor system resources, service status, and security indicators. Generate Markdown reports with status indicators (✅正常/⚠️警告/❌严重) based on configurable thresholds.

Includes both **basic health check** and **deep security check** capabilities.

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

### Local Host Check

```bash
# Basic check
bash scripts/ops-health-check/scripts/health-check.sh

# Security check
bash scripts/ops-health-check/scripts/security-check.sh
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

Output is Markdown with emoji status indicators:
- **✅正常** (OK) - All metrics within normal thresholds
- **⚠️警告** (WARNING) - Exceeds warning threshold, needs attention
- **❌严重** (CRITICAL) - Exceeds critical threshold, immediate action required

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

- Script uses standard Linux commands: `free`, `df`, `uptime`, `ss`, `systemctl`, `last`, `find`
- Requires Bash and basic Unix utilities
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
- ✅ Markdown reports with emoji status
- ⚠️ Docker monitoring (partial - basic container info in processes)
- ❌ Multi-host configuration files
- ❌ JSON output format
- ❌ Historical tracking
- ❌ Alert notifications

Future versions will add:
- Docker container monitoring (detailed stats, images, volumes)
- Multi-host configuration files (YAML-based)
- JSON output format for programmatic processing
- Historical tracking and trend analysis
- Alert notifications (email, DingTalk, WeChat)
