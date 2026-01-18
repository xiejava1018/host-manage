#!/bin/bash

# 健康检查脚本 - Linux 主机
# 检查基础系统资源：运行时间、负载、内存、磁盘、网络

set -euo pipefail

# 加载输出库
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/output.sh"

# 默认阈值
DISK_WARNING=${DISK_WARNING:-50}
DISK_CRITICAL=${DISK_CRITICAL:-80}
MEMORY_WARNING=${MEMORY_WARNING:-70}
MEMORY_CRITICAL=${MEMORY_CRITICAL:-90}
CPU_LOAD_WARNING=${CPU_LOAD_WARNING:-200}   # 使用整数 (2.0 * 100)
CPU_LOAD_CRITICAL=${CPU_LOAD_CRITICAL:-500} # 使用整数 (5.0 * 100)

# 检查状态函数
check_status() {
    local value=$1
    local warning=$2
    local critical=$3

    if [ "$value" -ge "$critical" ]; then
        echo "❌严重"
    elif [ "$value" -ge "$warning" ]; then
        echo "⚠️警告"
    else
        echo "✅正常"
    fi
}

# 初始化输出库
init_output "health"

# 开始数据收集
echo "🔍 正在收集系统数据..."

# 临时存储数据以便后续使用
MD_OUTPUT=""
md_echo() {
    MD_OUTPUT+="$1"$'\n'
}

# 1. 系统运行时间和负载
md_echo "## 💻 系统概览"
md_echo ""
md_echo "### 运行时间与负载"
uptime_output=$(uptime)
uptime_clean=$(echo "$uptime_output" | sed 's/^ *//g')
uptime_str=$(uptime -p 2>/dev/null || echo "$uptime_clean" | awk -F'up ' '{print $2}' | awk -F',' '{print $1}')
load_str=$(echo "$uptime_clean" | awk -F'load average:' '{print $2}' | sed 's/^ *//g')

md_echo "- **运行时间**: $uptime_str"
md_echo "- **平均负载**: $load_str"
md_echo ""

# 保存到输出库
add_system_data "uptime" "$uptime_str"
# 解析负载值
load1=$(echo "$load_str" | awk '{print $1}' | sed 's/,//')
load5=$(echo "$load_str" | awk '{print $2}' | sed 's/,//')
load15=$(echo "$load_str" | awk '{print $3}')
add_system_data "load_1min" "${load1:-0}"
add_system_data "load_5min" "${load5:-0}"
add_system_data "load_15min" "${load15:-0}"

# 2. 内存检查
md_echo "### 内存使用"
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
mem_status_code=$(echo "$mem_status" | sed 's/❌严重/critical/g' | sed 's/⚠️警告/warning/g' | sed 's/✅正常/ok/g')

md_echo "- **内存**: ${mem_used}MB / ${mem_total}MB (${mem_percent}%) - $mem_status"
md_echo "- **交换分区**: ${swap_used}MB / ${swap_total}MB (${swap_percent}%)"
md_echo ""

# 保存到输出库
add_memory_data "total_mb" "$mem_total"
add_memory_data "used_mb" "$mem_used"
add_memory_data "available_mb" "$mem_avail"
add_memory_data "used_percent" "$mem_percent"
add_memory_data "swap_total_mb" "$swap_total"
add_memory_data "swap_used_mb" "$swap_used"
add_memory_data "status" "$mem_status_code"

# 统计状态
case "$mem_status_code" in
    ok) add_status_count "ok" 1 ;;
    warning) add_status_count "warning" 1 ;;
    critical) add_status_count "critical" 1 ;;
esac

# 3. 磁盘检查
md_echo "### 磁盘空间"
md_echo ""
md_echo "| 文件系统 | 容量 | 已用 | 可用 | 使用率 | 挂载点 | 状态 |"
md_echo "|---------|------|------|------|--------|--------|------|"

disk_count=0
while IFS= read -r line; do
    [ -z "$line" ] && continue
    filesystem=$(echo $line | awk '{print $1}')
    size=$(echo $line | awk '{print $2}')
    used=$(echo $line | awk '{print $3}')
    avail=$(echo $line | awk '{print $4}')
    use_percent=$(echo $line | awk '{print $5}' | sed 's/%//')
    mount=$(echo $line | awk '{print $6}')

    status=$(check_status $use_percent $DISK_WARNING $DISK_CRITICAL)
    status_code=$(echo "$status" | sed 's/❌严重/critical/g' | sed 's/⚠️警告/warning/g' | sed 's/✅正常/ok/g')

    md_echo "| $filesystem | $size | $used | $avail | ${use_percent}% | $mount | $status |"

    # 保存到输出库
    add_disk_data "$filesystem" "$mount" "$size" "$used" "$avail" "$use_percent" "$status_code"

    # 统计状态
    case "$status_code" in
        ok) add_status_count "ok" 1 ;;
        warning) add_status_count "warning" 1 ;;
        critical) add_status_count "critical" 1 ;;
    esac

    ((disk_count++))
done < <(df -h | grep -vE '^Filesystem|tmpfs|overlay|none')
md_echo ""

# 4. 网络连接
md_echo "### 网络"
md_echo ""
conn_count=$(ss -tun 2>/dev/null | wc -l)
listening_count=$(ss -tln 2>/dev/null | grep LISTEN | wc -l)
md_echo "- **活动连接数**: $conn_count"
md_echo "- **监听端口数**: $listening_count"
md_echo ""

# 保存到输出库
add_system_data "active_connections" "$conn_count"
add_system_data "listening_ports" "$listening_count"

# 5. 运行服务摘要
md_echo "## 🔧 服务状态"
md_echo ""
if command -v systemctl &> /dev/null; then
    failed_count=$(systemctl list-units --type=service --state=failed 2>/dev/null | grep -c "loaded" || echo 0)
    running_count=$(systemctl list-units --type=service --state=running 2>/dev/null | grep -c "loaded" || echo 0)
    md_echo "- **运行中的服务**: $running_count"
    md_echo "- **失败的服务**: $failed_count"

    # 保存到输出库
    add_service_data "systemd_running" "$running_count"
    add_service_data "systemd_failed" "$failed_count"
else
    md_echo "服务状态不可用（未找到 systemd）"
fi
md_echo ""

# 6. 安全快速检查
md_echo "## 🔒 安全检查"
md_echo ""

# 检查可疑进程
mining_procs=$(ps aux 2>/dev/null | grep -E 'xmrig|minerd|cpuminer' | grep -v grep || true)
if [ -n "$mining_procs" ]; then
    md_echo "⚠️ **警告**: 检测到潜在的挖矿进程"
    add_security_field "mining_detected" "true"
    add_status_count "warning" 1
else
    md_echo "✅ **正常**: 未检测到挖矿进程"
    add_security_field "mining_detected" "false"
    add_status_count "ok" 1
fi

# 检查 /tmp 中的可执行文件
tmp_exec=$(find /tmp -type f -executable 2>/dev/null | wc -l)
if [ "$tmp_exec" -gt 0 ]; then
    md_echo "⚠️ **警告**: /tmp 中发现 $tmp_exec 个可执行文件"
    add_security_field "tmp_executables" "$tmp_exec"
    add_status_count "warning" 1
else
    md_echo "✅ **正常**: /tmp 中无可执行文件"
    add_security_field "tmp_executables" "0"
    add_status_count "ok" 1
fi

# 检查最近的失败登录
if [ -f /var/log/auth.log ]; then
    failed_logins=$(grep "Failed password" /var/log/auth.log 2>/dev/null | tail -10 | wc -l || echo 0)
    md_echo "- **最近失败登录**: $failed_logins 次（auth.log 中最近 10 条）"
    add_security_field "failed_logins" "$failed_logins"
elif [ -f /var/log/secure ]; then
    failed_logins=$(grep "Failed password" /var/log/secure 2>/dev/null | tail -10 | wc -l || echo 0)
    md_echo "- **最近失败登录**: $failed_logins 次（secure 中最近 10 条）"
    add_security_field "failed_logins" "$failed_logins"
fi
md_echo ""

# 设置整体状态
if [ "${OUTPUT_STATUS_COUNTS[5]}" -gt 0 ]; then
    set_overall_status "critical"
elif [ "${OUTPUT_STATUS_COUNTS[3]}" -gt 0 ]; then
    set_overall_status "warning"
else
    set_overall_status "ok"
fi

# 页脚
md_echo "---"
md_echo ""
md_echo "**报告生成时间**: $(date '+%Y-%m-%d %H:%M:%S')"
md_echo "**检查工具**: 运维健康检查 v1.0"

# ============================================================================
# 生成输出文件
# ============================================================================

# 确保输出目录存在
OUTPUT_DIR="${OUTPUT_DIR:-health-reports}"
mkdir -p "$OUTPUT_DIR"

# 生成文件名
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
IP=$(hostname -I | awk '{print $1}')
OUTPUT_BASE="${OUTPUT_DIR}/health-check-${IP}-${TIMESTAMP}"

# 生成 Markdown 文件
echo "$MD_OUTPUT" > "${OUTPUT_BASE}.md"
echo "📄 Markdown: ${OUTPUT_BASE}.md"

# 生成 JSON 文件
generate_json "${OUTPUT_BASE}.json"

echo ""
echo "✅ 检查完成！"
