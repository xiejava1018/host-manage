---
name: ops-health-check
description: "Comprehensive system health monitoring for Linux hosts. Use for: system resources check (CPU, memory, disk, network), service status verification, quick security checks (mining processes, suspicious files), health report generation. Triggers: health check, system status, check host, monitor server, server health"
---

# Ops Health Check

## Overview

Perform automated health checks on Linux hosts to monitor system resources, service status, and security indicators. Generate Markdown reports with status indicators (OK/WARNING/CRITICAL) based on configurable thresholds.

## Quick Start

To check a single host:

```bash
# Remote host check via SSH
ssh <host-ip> 'bash -s' < scripts/health-check.sh

# Example
ssh 192.168.0.42 'bash -s' < scripts/ops-health-check/scripts/health-check.sh
```

To check local host:

```bash
bash scripts/ops-health-check/scripts/health-check.sh
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

### Security
- Mining process detection (xmrig, minerd, cpuminer)
- Executable files in /tmp
- Recent failed login attempts

## Report Format

Output is Markdown with:
- **OK** (green) - All metrics within normal thresholds
- **WARNING** (yellow) - Exceeds warning threshold
- **CRITICAL** (red) - Exceeds critical threshold

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

**Single host check**:
```
User: "Check the health of 192.168.0.42"
→ Execute: ssh 192.168.0.42 'bash -s' < scripts/health-check.sh
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

- Script uses standard Linux commands: `free`, `df`, `uptime`, `ss`, `systemctl`
- Requires Bash and basic Unix utilities
- Color codes work in terminal; plain text in files
- For Docker, advanced security checks, or JSON output, see future versions

## Limitations (MVP)

This MVP version focuses on basic system health. Future versions will add:
- Docker container monitoring
- Multi-host configuration files
- JSON output format
- Advanced security checks
- Historical tracking
