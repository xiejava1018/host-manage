# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is **host-manage** - an operations health check skill for monitoring Linux hosts. It provides automated monitoring of system resources, Docker containers, service status, and security indicators with **dual-format output** (Markdown + JSON).

## Architecture

### Core Components

```
skills/ops-health-check/
├── SKILL.md                    # Skill definition and usage guide
└── scripts/
    ├── health-check.sh         # Basic system health check
    ├── security-check.sh       # Deep security analysis
    ├── docker-check.sh         # Docker monitoring
    └── lib/
        └── output.sh           # Shared output library (Markdown + JSON)

scripts/lib/
└── output.sh                   # Copy of output library

docs/plans/
├── 2025-01-17-ops-health-check-design.md  # Overall design
└── 2025-01-18-json-output-design.md       # JSON output design

health-reports/                 # Generated reports (.md and .json)
```

### Output Library Pattern

The `scripts/lib/output.sh` library is the **core abstraction** for dual-format output:

- Uses temporary files for data storage (bash 3.2+ compatibility, no associative arrays)
- Functions: `init_output()`, `add_*_data()`, `generate_json()`, `add_status_count()`
- Generates both Markdown and JSON from same data collection
- Auto-creates files in `health-reports/` with naming: `<check>-<host>-<timestamp>.{md,json}`

**Critical**: Modified `health-check.sh` uses this library, but `security-check.sh` and `docker-check.sh` still use original code (not yet migrated per user request).

### Check Script Architecture

Each check script follows this pattern:

```bash
# 1. Set thresholds via environment variables
DISK_WARNING=${DISK_WARNING:-50}
DISK_CRITICAL=${DISK_CRITICAL:-80}

# 2. Load output library (health-check.sh only)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/output.sh"

# 3. Initialize output
init_output "health"  # or "security" or "docker"

# 4. Collect data
add_system_data "uptime" "$uptime_str"
add_memory_data "total_mb" "$mem_total"

# 5. Generate reports
OUTPUT_BASE="health-reports/health-check-<host>-$(date +%Y%m%d-%H%M%S)"
echo "$MD_OUTPUT" > "${OUTPUT_BASE}.md"
generate_json "${OUTPUT_BASE}.json"
```

### JSON Structure

All JSON outputs follow a consistent three-part structure:

```json
{
  "summary": {
    "host": { "hostname", "ip", "check_time" },
    "overall_status": "ok|warning|critical",
    "status_counts": { "ok": N, "warning": N, "critical": N },
    "check_types": ["health", "security", "docker"]
  },
  "details": {
    "system": { ... },
    "memory": { ... },
    "disk": [ ... ],
    "services": { ... },
    "docker": { ... },      // docker-check only
    "security": { ... }     // security-check only
  },
  "metadata": {
    "check_version": "1.0",
    "tool_version": "ops-health-check v1.0",
    "thresholds": { ... }
  }
}
```

## Running Checks

### Basic Health Check

```bash
# Remote host via SSH (pipes script to remote bash)
ssh 192.168.0.42 'bash -s' < skills/ops-health-check/scripts/health-check.sh

# Local host
bash skills/ops-health-check/scripts/health-check.sh

# Custom thresholds
DISK_WARNING=30 DISK_CRITICAL=50 ssh 192.168.0.42 'bash -s' < skills/ops-health-check/scripts/health-check.sh
```

### Security Check

```bash
ssh 192.168.0.42 'bash -s' < skills/ops-health-check/scripts/security-check.sh
```

### Docker Check

```bash
ssh 192.168.0.42 'bash -s' < skills/ops-health-check/scripts/docker-check.sh
```

### Important Note on Remote Execution

**Modified `health-check.sh` (with JSON output) has a remote execution issue**: When piped via SSH, the library sourcing fails because `BASH_SOURCE[0]` is not set in that context. The current workaround is to use the **original script** for remote execution, or manually copy both script and lib to the remote host.

Original script location: `/tmp/health-check-orig.sh` (backup from development)

## Status Indicators

- ✅正常 (OK) - All metrics within normal thresholds
- ⚠️警告 (WARNING) - Exceeds warning threshold, needs attention
- ❌严重 (CRITICAL) - Exceeds critical threshold, immediate action required

## Default Thresholds

- Disk: 50% warning, 80% critical
- Memory: 70% warning, 90% critical
- CPU Load: 2.0 warning, 5.0 critical

## Development Guidelines

### Modifying Check Scripts

When adding new checks or modifying existing ones:

1. **For health-check.sh**: Use library functions in `lib/output.sh`
2. **For security-check.sh/docker-check.sh**: Currently use original code, but plan to migrate to library

### Bash Compatibility

**Must support bash 3.2+** (macOS default bash):

- No `declare -g` (bash 4.2+)
- No associative arrays `declare -A` (bash 4.0+)
- Use temporary files for data storage instead
- Test with `/bin/bash` on macOS

### Adding New Check Types

To add a new check type (e.g., runtime-check.sh):

1. Copy structure from existing script
2. Use `lib/output.sh` for data collection
3. Set `init_output "runtime"` for proper classification
4. Add check type to `check_types` array in metadata

### Testing JSON Output

```bash
# Test JSON generation without running full check
bash test-json-output.sh

# Validate JSON syntax
jq '.' health-reports/*.json

# Query specific fields
jq '.summary.overall_status' health-reports/*.json
jq '.details.memory.used_percent' health-reports/*.json
```

## What Each Check Does

### health-check.sh

- System uptime and load averages
- Memory and swap usage
- Disk space (all mount points)
- Network connection counts
- systemd service status (running/failed)
- Basic security: mining processes, /tmp executables, failed logins

### security-check.sh

**Anomalous Process Detection**:
- High CPU/memory processes
- Mining processes (xmrig, minerd, cpuminer)
- Suspicious process names
- Processes from /tmp or /dev/shm

**Network Security**:
- Reverse shell detection
- High-risk port monitoring
- External connection statistics

**File System Security**:
- Recently modified files (24h default)
- SUID/SGID executables
- Executables in temp directories
- Ransomware indicators (.encrypted, .locked, .crypto)

**Account & Login Security**:
- Recent login history (last 10)
- Failed login statistics
- Current logged-in users
- New user detection (30 days)
- Sudo usage logs

**System Integrity**:
- Recent /etc changes (7 days)
- Critical config file permissions
- Key file ownership verification

### docker-check.sh

- Docker service status and version
- Container status: total, running, stopped
- Container resource usage (Top 5 by CPU/memory)
- Image list with sizes
- Network and volume counts
- Storage usage (images, containers, volumes, build cache)
- Cleanup recommendations

## Troubleshooting

### Issue: `declare: -g: invalid option`
- **Cause**: Using bash 4.2+ feature on bash 3.2
- **Fix**: Remove `-g` flag from declare statements

### Issue: `declare: -A: invalid option`
- **Cause**: Using associative arrays (bash 4.0+) on bash 3.2
- **Fix**: Use temporary files instead: `mktemp`, `echo "key=value" >> file`, `grep "^key=" file`

### Issue: `bash: line X: BASH_SOURCE[0]: unbound variable`
- **Cause**: `set -u` treats unset variables as errors, BASH_SOURCE not set when script piped via SSH
- **Fix**: Use `${BASH_SOURCE[0]:-$0}` or avoid BASH_SOURCE in piped scripts

### Issue: JSON syntax errors like `"status":"warning:-ok}"`
- **Cause**: Default value syntax `${var:-default}` breaks when used in JSON string concatenation
- **Fix**: Create wrapper function that accepts default as parameter: `get_field $key $default`

## Common Tasks

### Check multiple hosts

```bash
for host in 192.168.0.42 192.168.0.43; do
  echo "=== Checking $host ==="
  ssh $host 'bash -s' < skills/ops-health-check/scripts/health-check.sh
  echo ""
done
```

### Schedule with cron

```bash
# Daily at 8 AM
0 8 * * * ssh 192.168.0.42 'bash -s' < /path/to/health-check.sh > /path/to/reports/daily-$(date +\%Y\%m\%d).md
```

### Query JSON for monitoring

```bash
# Find all hosts with warnings
for json in health-reports/*.json; do
  hostname=$(jq -r '.summary.host.hostname' "$json")
  status=$(jq -r '.summary.overall_status' "$json")
  if [ "$status" != "ok" ]; then
    echo "$hostname: $status"
  fi
done
```

## Known Limitations

- ✅ Basic system health monitoring
- ✅ Deep security checks
- ✅ Docker container monitoring
- ✅ Markdown reports with emoji status
- ✅ JSON output format (health-check.sh only)
- ❌ Multi-host configuration files (YAML-based)
- ❌ Historical tracking and trend analysis
- ❌ Alert notifications (email, DingTalk, WeChat)
- ❌ Modified health-check.sh has remote execution issues (use original for SSH)
