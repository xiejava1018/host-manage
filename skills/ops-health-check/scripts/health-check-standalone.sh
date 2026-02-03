#!/bin/bash

# 健康检查脚本 - Linux 主机（独立版本，适合远程执行）
# 检查基础系统资源：运行时间、负载、内存、磁盘、网络

set -euo pipefail

# 默认阈值
DISK_WARNING=${DISK_WARNING:-50}
DISK_CRITICAL=${DISK_CRITICAL:-80}
MEMORY_WARNING=${MEMORY_WARNING:-70}
MEMORY_CRITICAL=${MEMORY_CRITICAL:-90}
CPU_LOAD_WARNING=${CPU_LOAD_WARNING:-2.0}
CPU_LOAD_CRITICAL=${CPU_LOAD_CRITICAL:-5.0}

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

# 获取主机信息
HOSTNAME=$(hostname)
IP=$(hostname -I | awk '{print $1}')
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# 输出函数
echo "# 🔍 主机健康检查报告"
echo ""
echo "**主机名**: $HOSTNAME"
echo "**IP地址**: $IP"
echo "**检查时间**: $TIMESTAMP"
echo ""

# 1. 系统运行时间和负载
echo "## 💻 系统概览"
echo ""
echo "### 运行时间与负载"
uptime_output=$(uptime)
uptime_clean=$(echo "$uptime_output" | sed 's/^ *//g')
uptime_str=$(uptime -p 2>/dev/null || echo "$uptime_clean" | awk -F'up ' '{print $2}' | awk -F',' '{print $1}')
load_str=$(echo "$uptime_clean" | awk -F'load average:' '{print $2}' | sed 's/^ *//g')

echo "- **运行时间**: $uptime_str"
echo "- **平均负载**: $load_str"
echo ""

# 2. 内存检查
echo "### 内存使用"
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

echo "- **内存**: ${mem_used}MB / ${mem_total}MB (${mem_percent}%) - $mem_status"
echo "- **交换分区**: ${swap_used}MB / ${swap_total}MB (${swap_percent}%)"
echo ""

# 3. 磁盘检查
echo "### 磁盘空间"
echo ""
echo "| 文件系统 | 容量 | 已用 | 可用 | 使用率 | 挂载点 | 状态 |"
echo "|---------|------|------|------|--------|--------|------|"

while IFS= read -r line; do
    [ -z "$line" ] && continue
    filesystem=$(echo $line | awk '{print $1}')
    size=$(echo $line | awk '{print $2}')
    used=$(echo $line | awk '{print $3}')
    avail=$(echo $line | awk '{print $4}')
    use_percent=$(echo $line | awk '{print $5}' | sed 's/%//')
    mount=$(echo $line | awk '{print $6}')

    status=$(check_status $use_percent $DISK_WARNING $DISK_CRITICAL)

    echo "| $filesystem | $size | $used | $avail | ${use_percent}% | $mount | $status |"
done < <(df -h | grep -vE '^Filesystem|tmpfs|overlay|none')
echo ""

# 4. 网络连接
echo "### 网络"
echo ""
conn_count=$(ss -tun 2>/dev/null | wc -l)
listening_count=$(ss -tln 2>/dev/null | grep LISTEN | wc -l)
echo "- **活动连接数**: $conn_count"
echo "- **监听端口数**: $listening_count"
echo ""

# 5. 运行服务摘要
echo "## 🔧 服务状态"
echo ""
if command -v systemctl &> /dev/null; then
    failed_count=$(systemctl list-units --type=service --state=failed --no-legend 2>/dev/null | wc -l)
    running_count=$(systemctl list-units --type=service --state=running --no-legend 2>/dev/null | wc -l)
    echo "- **运行中的服务**: $running_count"
    echo "- **失败的服务**: $failed_count"
else
    echo "服务状态不可用（未找到 systemd）"
fi
echo ""

# 6. 安全快速检查
echo "## 🔒 安全检查"
echo ""

# 检查可疑进程
mining_procs=$(ps aux 2>/dev/null | grep -E 'xmrig|minerd|cpuminer' | grep -v grep || true)
if [ -n "$mining_procs" ]; then
    echo "⚠️ **警告**: 检测到潜在的挖矿进程"
    echo "$mining_procs"
else
    echo "✅ **正常**: 未检测到挖矿进程"
fi

# 检查 /tmp 中的可执行文件
tmp_exec=$(find /tmp -type f -executable 2>/dev/null | wc -l)
if [ "$tmp_exec" -gt 0 ]; then
    echo "⚠️ **警告**: /tmp 中发现 $tmp_exec 个可执行文件"
else
    echo "✅ **正常**: /tmp 中无可执行文件"
fi

# 检查最近的失败登录
if [ -f /var/log/auth.log ]; then
    failed_logins=$(grep "Failed password" /var/log/auth.log 2>/dev/null | tail -10 | wc -l || echo 0)
    echo "- **最近失败登录**: $failed_logins 次（auth.log 中最近 10 条）"
elif [ -f /var/log/secure ]; then
    failed_logins=$(grep "Failed password" /var/log/secure 2>/dev/null | tail -10 | wc -l || echo 0)
    echo "- **最近失败登录**: $failed_logins 次（secure 中最近 10 条）"
fi
echo ""

# 页脚
echo "---"
echo ""
echo "**报告生成时间**: $(date '+%Y-%m-%d %H:%M:%S')"
echo "**检查工具**: 运维健康检查 v1.0 (独立版)"
