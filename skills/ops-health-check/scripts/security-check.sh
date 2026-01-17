#!/bin/bash

# 深度安全检查脚本
# 检测系统安全威胁：木马、挖矿、勒索病毒、入侵痕迹等

set -euo pipefail

# 配置
CHECK_DIRS="${CHECK_DIRS:-/tmp /dev/shm /var/tmp}"
RECENT_HOURS=${RECENT_HOURS:-24}
MAX_CPU_PERCENT=${MAX_CPU_PERCENT:-80}
MAX_MEM_PERCENT=${MAX_MEM_PERCENT:-50}

echo "## 🔒 深度安全检查"
echo ""

# ============================================================================
# 1. 异常进程深度检测
# ============================================================================
echo "### 🎯 异常进程检测"
echo ""

# 高资源占用进程
echo "**高CPU/内存占用进程**："
high_resource_procs=$(ps aux --sort=-%cpu | head -n 11 | tail -n 10 | awk 'NR>1 && ($3>'"$MAX_CPU_PERCENT"' || $4>'"$MAX_MEM_PERCENT"')')
if [ -n "$high_resource_procs" ]; then
    echo "⚠️ **警告**：发现高资源占用进程"
    ps aux --sort=-%cpu | head -n 11 | tail -n 10 | awk '{printf "- PID %s (%s): CPU %s%%, 内存 %s%%\n", $2, $11, $3, $4}' | while read line; do
        echo "  $line"
    done
else
    echo "✅ **正常**：未发现异常高资源占用进程"
fi
echo ""

# 挖矿程序检测（扩展列表）
echo "**挖矿程序检测**："
mining_keywords="xmrig|minerd|cpuminer|cgminer|bfgminer|ufasoft|cryptonight|monero"
mining_procs=$(ps aux 2>/dev/null | grep -E "$mining_keywords" | grep -v grep || true)
if [ -n "$mining_procs" ]; then
    echo "❌ **严重**：检测到挖矿进程"
    echo "$mining_procs" | awk '{printf "- PID %s: %s\n", $2, $11}'
else
    echo "✅ **正常**：未检测到挖矿进程"
fi
echo ""

# 可疑进程名检测（只检测真正的可疑模式）
echo "**可疑进程名检测**："
# 只检测纯数字进程名、非常短的隐藏进程、明显的随机字符串
suspicious_procs=$(ps aux 2>/dev/null | awk '{
    proc = $11;
    # 跳过正常路径和带[ ]的内核进程
    if (proc ~ /^\// || proc ~ /^\[.*\]$/) next;
    # 检测纯数字进程名
    if (proc ~ /^[0-9]{8,}$/) print;
    # 检测明显的随机字符串（小写+数字，8位以上）
    if (proc ~ /^[a-z]{8,}[0-9]+$/) print;
}' | head -20 || true)
if [ -n "$suspicious_procs" ]; then
    echo "⚠️ **警告**：发现可疑进程名（隐藏或随机字符）"
    echo "$suspicious_procs" | awk '{printf "- PID %s: %s\n", $2, $11}'
else
    echo "✅ **正常**：未发现可疑进程名"
fi
echo ""

# 检查进程路径
echo "**可疑路径进程检测**："
suspicious_path_procs=$(ps aux 2>/dev/null | awk '{print $11}' | grep -E '^/tmp/|^/dev/shm/' | sort -u || true)
if [ -n "$suspicious_path_procs" ]; then
    echo "❌ **严重**：发现从 /tmp 或 /dev/shm 运行的进程"
    echo "$suspicious_path_procs" | while read proc; do
        echo "- $proc"
        ps aux 2>/dev/null | grep "$proc" | grep -v grep | head -1 | awk '{printf "  PID: %s, 用户: %s\n", $2, $1}'
    done
else
    echo "✅ **正常**：未发现从可疑路径运行的进程"
fi
echo ""

# ============================================================================
# 2. 可疑网络连接
# ============================================================================
echo "### 🌐 网络连接安全"
echo ""

# 反向shell检测
echo "**反向Shell检测**："
reverse_shell=$(ss -tnp 2>/dev/null | awk '$5 ~ /:[0-9]{4,}$/ && $1 !~ /127.0.0.1/ {print}' || true)
if [ -n "$reverse_shell" ]; then
    echo "⚠️ **警告**：检测到可能的外部连接（反向Shell迹象）"
    echo "$reverse_shell" | head -5
else
    echo "✅ **正常**：未检测到反向Shell连接"
fi
echo ""

# 监听端口
echo "**监听端口检查**："
listening_ports=$(ss -tlnp 2>/dev/null | grep LISTEN | awk '{print $4}' | awk -F: '{print $NF}' | sort -n | uniq)
echo "当前监听端口：$(echo $listening_ports | tr '\n' ' ')"

# 检查高危端口
dangerous_ports="4444|5555|6666|31337|12345"
dangerous_listening=$(ss -tlnp 2>/dev/null | grep -E "$dangerous_ports" || true)
if [ -n "$dangerous_listening" ]; then
    echo "⚠️ **警告**：检测到高危端口监听"
    echo "$dangerous_listening" | awk '{print "- Port: " $4}'
else
    echo "✅ **正常**：未检测到高危端口监听"
fi
echo ""

# 外部连接统计
echo "**外部连接统计**："
external_conn=$(ss -tnp 2>/dev/null | awk '$5 !~ /^127\./ && $5 !~ /^192\.168\./ && $5 !~ /^10\./ {print}' | wc -l)
echo "外部连接数：$external_conn"
echo ""

# ============================================================================
# 3. 文件系统安全
# ============================================================================
echo "### 📁 文件系统安全"
echo ""

# 最近修改的文件
echo "**最近 ${RECENT_HOURS} 小时修改的文件（重点目录）**："
recent_files=""
# 将小时转换为天数（使用 awk）
days_ago=$(awk "BEGIN {print $RECENT_HOURS/24}")
for dir in $CHECK_DIRS; do
    if [ -d "$dir" ]; then
        files=$(find "$dir" -type f -mtime -${days_ago} 2>/dev/null | head -20 || true)
        if [ -n "$files" ]; then
            recent_files="$recent_files\n$files"
        fi
    fi
done

if [ -n "$recent_files" ]; then
    echo "⚠️ **警告**：发现最近修改的文件"
    echo -e "$recent_files" | while read file; do
        [ -n "$file" ] && ls -lh "$file" 2>/dev/null | awk '{printf "- %s (%s, %s)\n", $9, $5, $6, $7, $8}'
    done
else
    echo "✅ **正常**：未发现可疑的最近修改文件"
fi
echo ""

# SUID/SGID 文件检查
echo "**SUID/SGID 可执行文件**："
suid_files=$(find / -type f -perm -4000 2>/dev/null | head -20 || true)
sgid_files=$(find / -type f -perm -2000 2>/dev/null | head -20 || true)

if [ -n "$suid_files" ] || [ -n "$sgid_files" ]; then
    echo "发现以下特权文件（正常系统文件）："
    echo "$suid_files" | while read file; do
        [ -n "$file" ] && [ -f "$file" ] && echo "- SUID: $file"
    done
    echo "$sgid_files" | while read file; do
        [ -n "$file" ] && [ -f "$file" ] && echo "- SGID: $file"
    done
else
    echo "✅ 未发现异常的 SUID/SGID 文件"
fi
echo ""

# /tmp 可执行文件
echo "**/tmp 目录可执行文件**："
tmp_exec_count=0
for dir in $CHECK_DIRS; do
    count=$(find "$dir" -type f -executable 2>/dev/null | wc -l)
    tmp_exec_count=$((tmp_exec_count + count))
done

if [ $tmp_exec_count -gt 0 ]; then
    echo "⚠️ **警告**：发现 $tmp_exec_count 个可执行文件"
    for dir in $CHECK_DIRS; do
        if [ -d "$dir" ]; then
            find "$dir" -type f -executable 2>/dev/null | head -10 | while read file; do
                echo "- $file"
            done
        fi
    done
else
    echo "✅ **正常**：未在临时目录发现可执行文件"
fi
echo ""

# 勒索病毒特征检测
echo "**勒索病毒特征检测**："
ransomware_extensions=$(find /home /root /var/www 2>/dev/null -name "*.encrypted" -o -name "*.locked" -o -name "*.crypto" 2>/dev/null | head -10 || true)
if [ -n "$ransomware_extensions" ]; then
    echo "❌ **严重**：发现可能的勒索病毒加密文件"
    echo "$ransomware_extensions" | while read file; do
        [ -n "$file" ] && echo "- $file"
    done
else
    echo "✅ **正常**：未发现勒索病毒特征文件"
fi
echo ""

# ============================================================================
# 4. 账户和登录安全
# ============================================================================
echo "### 👤 账户和登录安全"
echo ""

# 最近登录记录
echo "**最近登录记录（最近10次）**："
if command -v last &> /dev/null; then
    last -n 10 2>/dev/null | head -11 || echo "无登录记录"
else
    echo "last 命令不可用"
fi
echo ""

# 失败登录统计
echo "**失败登录统计**："
if [ -f /var/log/auth.log ]; then
    failed_logins=$(grep "Failed password" /var/log/auth.log 2>/dev/null | tail -20 || true)
    failed_count=$(echo "$failed_logins" | grep -c "Failed" || echo 0)
    # 确保是数字
    failed_count=${failed_count:-0}
    echo "最近失败登录次数：$failed_count"
    if [ "$failed_count" -gt 0 ] 2>/dev/null; then
        echo "最近的失败登录："
        echo "$failed_logins" | tail -5 | awk '{print "  -", $0}'
    fi
elif [ -f /var/log/secure ]; then
    failed_logins=$(grep "Failed password" /var/log/secure 2>/dev/null | tail -20 || true)
    failed_count=$(echo "$failed_logins" | grep -c "Failed" || echo 0)
    failed_count=${failed_count:-0}
    echo "最近失败登录次数：$failed_count"
    if [ "$failed_count" -gt 0 ] 2>/dev/null; then
        echo "最近的失败登录："
        echo "$failed_logins" | tail -5 | awk '{print "  -", $0}'
    fi
else
    echo "登录日志文件未找到"
fi
echo ""

# 当前登录用户
echo "**当前登录用户**："
if command -v who &> /dev/null; then
    who 2>/dev/null || echo "无当前登录用户"
else
    echo "who 命令不可用"
fi
echo ""

# 检查新增用户（最近30天）
echo "**新增用户检查（最近30天）**："
# 检查最近修改的用户目录
new_users=""
while IFS=: read -r username passwd uid gid gecos home_dir shell; do
    # 跳过系统用户（UID < 1000）
    if [ "$uid" -lt 1000 ] 2>/dev/null; then
        continue
    fi
    # 检查home目录是否存在且最近30天创建
    if [ -d "$home_dir" ]; then
        # 查找最近30天的目录
        if find "$home_dir" -maxdepth 0 -mtime -30 2>/dev/null | grep -q .; then
            new_users="$new_users\n$username"
        fi
    fi
done < /etc/passwd 2>/dev/null

if [ -n "$new_users" ]; then
    echo "⚠️ **警告**：发现最近30天的新用户"
    echo "$new_users" | while read user; do
        echo "- $user"
    done
else
    echo "✅ **正常**：未发现可疑的新增用户"
fi
echo ""

# sudo 使用日志
echo "**sudo 使用日志（最近10次）**："
if [ -f /var/log/auth.log ]; then
    sudo_logs=$(grep sudo /var/log/auth.log 2>/dev/null | grep -v "COMMAND=" | tail -10 || true)
    if [ -n "$sudo_logs" ]; then
        echo "$sudo_logs" | awk '{print "  -", $0}'
    else
        echo "无最近的 sudo 记录"
    fi
elif [ -f /var/log/secure ]; then
    sudo_logs=$(grep sudo /var/log/secure 2>/dev/null | grep -v "COMMAND=" | tail -10 || true)
    if [ -n "$sudo_logs" ]; then
        echo "$sudo_logs" | awk '{print "  -", $0}'
    else
        echo "无最近的 sudo 记录"
    fi
else
    echo "sudo 日志文件未找到"
fi
echo ""

# ============================================================================
# 5. 系统完整性
# ============================================================================
echo "### 🛡️ 系统完整性"
echo ""

# /etc 目录最近变更
echo "**/etc 目录最近变更（最近7天）**："
etc_changes=$(find /etc -type f -mtime -7 2>/dev/null | head -20 || true)
if [ -n "$etc_changes" ]; then
    echo "⚠️ **注意**：发现最近修改的配置文件"
    echo "$etc_changes" | while read file; do
        [ -f "$file" ] && ls -lh "$file" 2>/dev/null | awk '{printf "- %s (%s, %s)\n", $9, $5, $6, $7, $8}'
    done
else
    echo "✅ **正常**：/etc 目录无异常变更"
fi
echo ""

# 关键配置文件检查
echo "**关键配置文件检查**："
critical_files="/etc/passwd /etc/shadow /etc/sudoers /etc/ssh/sshd_config"
for file in $critical_files; do
    if [ -f "$file" ]; then
        perms=$(ls -ld "$file" | awk '{print $1}')
        owner=$(ls -ld "$file" | awk '{print $3}')
        echo "- $file: 权限 $perms, 所有者 $owner"
    fi
done
echo ""

echo "---"
echo ""
echo "**安全检查完成时间**: $(date '+%Y-%m-%d %H:%M:%S')"
echo "**检查工具**: 运维深度安全检查 v1.0"
