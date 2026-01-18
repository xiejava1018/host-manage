#!/bin/bash

# 输出格式化库 - ops-health-check
# 支持 Markdown 和 JSON 双格式输出
# 兼容 bash 3.2+

# 临时文件存储数据（兼容旧版本 bash）
OUTPUT_SUMMARY_FILE=""
OUTPUT_SYSTEM_FILE=""
OUTPUT_MEMORY_FILE=""
OUTPUT_SERVICES_FILE=""
OUTPUT_SECURITY_FILE=""
OUTPUT_DISKS_FILE=""
OUTPUT_DOCKER_FILE=""
OUTPUT_STATUS_FILE=""

# 当前检查类型
OUTPUT_CHECK_TYPE="health"

# ============================================================================
# 初始化函数
# ============================================================================

# 初始化输出数据结构
init_output() {
    local check_type=$1
    OUTPUT_CHECK_TYPE=${check_type:-health}

    # 创建临时文件
    OUTPUT_SUMMARY_FILE=$(mktemp)
    OUTPUT_SYSTEM_FILE=$(mktemp)
    OUTPUT_MEMORY_FILE=$(mktemp)
    OUTPUT_SERVICES_FILE=$(mktemp)
    OUTPUT_SECURITY_FILE=$(mktemp)
    OUTPUT_DISKS_FILE=$(mktemp)
    OUTPUT_DOCKER_FILE=$(mktemp)
    OUTPUT_STATUS_FILE=$(mktemp)

    # 设置默认值
    add_summary_field "check_time" "$(date -u +%Y-%m-%dT%H:%M:%S%z 2>/dev/null || date)"
    add_summary_field "hostname" "$(hostname)"
    add_summary_field "ip" "$(hostname -I | awk '{print $1}')"
    add_summary_field "check_type" "$OUTPUT_CHECK_TYPE"

    # 初始化状态计数
    echo "ok 0" > "$OUTPUT_STATUS_FILE"
    echo "warning 0" >> "$OUTPUT_STATUS_FILE"
    echo "critical 0" >> "$OUTPUT_STATUS_FILE"
}

# ============================================================================
# 摘要数据收集
# ============================================================================

add_summary_field() {
    local key=$1
    local value=$2
    echo "$key=$value" >> "$OUTPUT_SUMMARY_FILE"
}

get_summary_field() {
    local key=$1
    local default=${2:-}
    local value=$(grep "^$key=" "$OUTPUT_SUMMARY_FILE" 2>/dev/null | cut -d'=' -f2-)
    echo "${value:-$default}"
}

add_status_count() {
    local status=$1
    local count=$2

    case $status in
        ok|OK|✅正常)
            local current=$(grep "^ok " "$OUTPUT_STATUS_FILE" | awk '{print $2}')
            echo "ok $((current + count))" > "$OUTPUT_STATUS_FILE.tmp"
            grep -v "^ok " "$OUTPUT_STATUS_FILE" >> "$OUTPUT_STATUS_FILE.tmp"
            mv "$OUTPUT_STATUS_FILE.tmp" "$OUTPUT_STATUS_FILE"
            ;;
        warning|WARNING|⚠️警告)
            local current=$(grep "^warning " "$OUTPUT_STATUS_FILE" | awk '{print $2}')
            grep -v "^warning " "$OUTPUT_STATUS_FILE" > "$OUTPUT_STATUS_FILE.tmp"
            echo "warning $((current + count))" >> "$OUTPUT_STATUS_FILE.tmp"
            mv "$OUTPUT_STATUS_FILE.tmp" "$OUTPUT_STATUS_FILE"
            ;;
        critical|CRITICAL|❌严重)
            local current=$(grep "^critical " "$OUTPUT_STATUS_FILE" | awk '{print $2}')
            grep -v "^critical " "$OUTPUT_STATUS_FILE" > "$OUTPUT_STATUS_FILE.tmp"
            echo "critical $((current + count))" >> "$OUTPUT_STATUS_FILE.tmp"
            mv "$OUTPUT_STATUS_FILE.tmp" "$OUTPUT_STATUS_FILE"
            ;;
    esac
}

get_status_count() {
    local status=$1
    local default=${2:-0}
    local count=$(grep "^$status " "$OUTPUT_STATUS_FILE" 2>/dev/null | awk '{print $2}')
    echo "${count:-$default}"
}

# 辅助函数：从文件中获取值，支持默认值
get_field_value() {
    local file=$1
    local field=$2
    local default=${3:-}
    local value=$(grep "^$field=" "$file" 2>/dev/null | cut -d'=' -f2-)
    echo "${value:-$default}"
}

set_overall_status() {
    local status=$1
    case $status in
        ok|OK|✅正常) add_summary_field "overall_status" "ok" ;;
        warning|WARNING|⚠️警告) add_summary_field "overall_status" "warning" ;;
        critical|CRITICAL|❌严重) add_summary_field "overall_status" "critical" ;;
        *) add_summary_field "overall_status" "unknown" ;;
    esac
}

# ============================================================================
# 系统数据收集
# ============================================================================

add_system_data() {
    local key=$1
    local value=$2
    echo "$key=$value" >> "$OUTPUT_SYSTEM_FILE"
}

# ============================================================================
# 内存数据收集
# ============================================================================

add_memory_data() {
    local key=$1
    local value=$2
    echo "$key=$value" >> "$OUTPUT_MEMORY_FILE"
}

# ============================================================================
# 磁盘数据收集
# ============================================================================

add_disk_data() {
    local device=$1
    local mount=$2
    local total=$3
    local used=$4
    local avail=$5
    local use_percent=$6
    local status=$7

    # 转义 JSON 字符串
    device=$(echo "$device" | sed 's/"/\\"/g')
    mount=$(echo "$mount" | sed 's/"/\\"/g')

    echo "{\"device\":\"$device\",\"mount\":\"$mount\",\"total_gb\":\"$total\",\"used_gb\":\"$used\",\"available_gb\":\"$avail\",\"used_percent\":$use_percent,\"status\":\"$status\"}" >> "$OUTPUT_DISKS_FILE"
}

# ============================================================================
# 服务数据收集
# ============================================================================

add_service_data() {
    local key=$1
    local value=$2
    echo "$key=$value" >> "$OUTPUT_SERVICES_FILE"
}

# ============================================================================
# Docker 数据收集
# ============================================================================

add_docker_field() {
    local key=$1
    local value=$2
    echo "$key=$value" >> "$OUTPUT_DOCKER_FILE"
}

# ============================================================================
# 安全数据收集
# ============================================================================

add_security_field() {
    local key=$1
    local value=$2
    echo "$key=$value" >> "$OUTPUT_SECURITY_FILE"
}

# ============================================================================
# JSON 生成函数
# ============================================================================

generate_json() {
    local output_file=$1

    # 构建 JSON
    local json="{"

    # Summary 部分
    json+="\"summary\":{"
    json+="\"host\":{"
    json+="\"hostname\":\"$(get_summary_field hostname)\","
    json+="\"ip\":\"$(get_summary_field ip)\","
    json+="\"check_time\":\"$(get_summary_field check_time)\""
    if [ -n "$(get_summary_field check_duration)" ]; then
        json+=",\"check_duration\":$(get_summary_field check_duration)"
    fi
    json+="},"
    json+="\"overall_status\":\"$(get_summary_field overall_status 'ok')}\","
    json+="\"status_counts\":{"
    json+="\"ok\":$(get_status_count ok),"
    json+="\"warning\":$(get_status_count warning),"
    json+="\"critical\":$(get_status_count critical)"
    json+="},"
    json+="\"check_types\":[\"$OUTPUT_CHECK_TYPE\"]"
    json+="},"

    # Details 部分
    json+="\"details\":{"

    # System 数据
    if [ -s "$OUTPUT_SYSTEM_FILE" ]; then
        json+="\"system\":{"
        local first=true
        while IFS='=' read -r key value; do
            if [ "$first" = true ]; then
                first=false
            else
                json+=","
            fi
            # 转义 JSON 字符串
            value=$(echo "$value" | sed 's/"/\\"/g' | sed "s/$'\n'/\\\\n/g")
            json+="\"$key\":\"$value\""
        done < "$OUTPUT_SYSTEM_FILE"

        # CPU
        if [ -n "$(grep "^load_1min=" "$OUTPUT_SYSTEM_FILE" | cut -d'=' -f2)" ]; then
            local cpu_status=$(get_field_value "$OUTPUT_SYSTEM_FILE" "cpu_status" "ok")
            local load1=$(get_field_value "$OUTPUT_SYSTEM_FILE" "load_1min" "0")
            local load5=$(get_field_value "$OUTPUT_SYSTEM_FILE" "load_5min" "0")
            local load15=$(get_field_value "$OUTPUT_SYSTEM_FILE" "load_15min" "0")
            json+=",\"cpu\":{"
            json+="\"status\":\"$cpu_status\","
            json+="\"load_1min\":$load1,"
            json+="\"load_5min\":$load5,"
            json+="\"load_15min\":$load15"
            json+="}"
        fi

        # Memory
        if [ -s "$OUTPUT_MEMORY_FILE" ]; then
            local mem_status=$(get_field_value "$OUTPUT_MEMORY_FILE" "status" "ok")
            local mem_total=$(get_field_value "$OUTPUT_MEMORY_FILE" "total_mb" "0")
            local mem_used=$(get_field_value "$OUTPUT_MEMORY_FILE" "used_mb" "0")
            local mem_avail=$(get_field_value "$OUTPUT_MEMORY_FILE" "available_mb" "0")
            local mem_percent=$(get_field_value "$OUTPUT_MEMORY_FILE" "used_percent" "0")
            local swap_total=$(get_field_value "$OUTPUT_MEMORY_FILE" "swap_total_mb" "0")
            local swap_used=$(get_field_value "$OUTPUT_MEMORY_FILE" "swap_used_mb" "0")
            json+=",\"memory\":{"
            json+="\"status\":\"$mem_status\","
            json+="\"total_mb\":$mem_total,"
            json+="\"used_mb\":$mem_used,"
            json+="\"available_mb\":$mem_avail,"
            json+="\"used_percent\":$mem_percent,"
            json+="\"swap_total_mb\":$swap_total,"
            json+="\"swap_used_mb\":$swap_used"
            json+="}"
        fi

        # Network
        if [ -n "$(grep "^active_connections=" "$OUTPUT_SYSTEM_FILE" | cut -d'=' -f2)" ]; then
            local active_conn=$(get_field_value "$OUTPUT_SYSTEM_FILE" "active_connections" "0")
            local listen_ports=$(get_field_value "$OUTPUT_SYSTEM_FILE" "listening_ports" "0")
            json+=",\"network\":{"
            json+="\"active_connections\":$active_conn,"
            json+="\"listening_ports\":$listen_ports"
            json+="}"
        fi

        # Disk
        if [ -s "$OUTPUT_DISKS_FILE" ]; then
            json+=",\"disk\":["
            local first=true
            while IFS= read -r disk_entry; do
                if [ "$first" = true ]; then
                    first=false
                else
                    json+=","
                fi
                json+="$disk_entry"
            done < "$OUTPUT_DISKS_FILE"
            json+="]"
        fi

        json+="}"
    fi

    # Services 数据
    if [ -s "$OUTPUT_SERVICES_FILE" ]; then
        if [ -s "$OUTPUT_SYSTEM_FILE" ]; then json+=","; fi
        json+="\"services\":{"
        local first=true
        while IFS='=' read -r key value; do
            if [ "$first" = true ]; then
                first=false
            else
                json+=","
            fi
            json+="\"$key\":$value"
        done < "$OUTPUT_SERVICES_FILE"
        json+="}"
    fi

    # Security 数据
    if [ -s "$OUTPUT_SECURITY_FILE" ]; then
        if [ -s "$OUTPUT_SYSTEM_FILE" ] || [ -s "$OUTPUT_SERVICES_FILE" ]; then json+=","; fi
        json+="\"security\":{"
        local first=true
        while IFS='=' read -r key value; do
            if [ "$first" = true ]; then
                first=false
            else
                json+=","
            fi
            value=$(echo "$value" | sed 's/"/\\"/g')
            json+="\"$key\":\"$value\""
        done < "$OUTPUT_SECURITY_FILE"
        json+="}"
    fi

    # Docker 数据
    if [ -s "$OUTPUT_DOCKER_FILE" ]; then
        if [ -s "$OUTPUT_SYSTEM_FILE" ] || [ -s "$OUTPUT_SERVICES_FILE" ] || [ -s "$OUTPUT_SECURITY_FILE" ]; then json+=","; fi
        json+="\"docker\":{"
        local first=true
        while IFS='=' read -r key value; do
            if [ "$first" = true ]; then
                first=false
            else
                json+=","
            fi
            json+="\"$key\":$value"
        done < "$OUTPUT_DOCKER_FILE"
        json+="}"
    fi

    json+="},"

    # Metadata 部分
    json+="\"metadata\":{"
    json+="\"check_version\":\"1.0\","
    json+="\"tool_version\":\"ops-health-check v1.0\","
    json+="\"check_script\":\"${OUTPUT_CHECK_TYPE}-check.sh\","
    json+="\"thresholds\":{"
    json+="\"disk_warning\":${DISK_WARNING:-50},"
    json+="\"disk_critical\":${DISK_CRITICAL:-80},"
    json+="\"memory_warning\":${MEMORY_WARNING:-70},"
    json+="\"memory_critical\":${MEMORY_CRITICAL:-90}"
    json+="}"
    json+="}"

    json+="}"

    # 写入文件
    echo "$json" > "$output_file"

    # 如果有 jq，尝试格式化
    if command -v jq &> /dev/null; then
        jq . "$output_file" > "${output_file}.tmp" 2>/dev/null && mv "${output_file}.tmp" "$output_file"
    fi

    # 清理临时文件
    rm -f "$OUTPUT_SUMMARY_FILE" "$OUTPUT_SYSTEM_FILE" "$OUTPUT_MEMORY_FILE" \
          "$OUTPUT_SERVICES_FILE" "$OUTPUT_SECURITY_FILE" "$OUTPUT_DISKS_FILE" \
          "$OUTPUT_DOCKER_FILE" "$OUTPUT_STATUS_FILE"

    echo "📊 JSON: $output_file"
}

# ============================================================================
# Markdown 生成辅助函数（保持兼容）
# ============================================================================

get_markdown_header() {
    echo "# 系统健康检查报告"
    echo ""
    echo "**检查时间**: $(get_summary_field check_time)"
    echo "**主机**: $(get_summary_field hostname)"
    echo "**IP地址**: $(get_summary_field ip)"
    echo ""
}

get_markdown_footer() {
    echo "---"
    echo ""
    echo "**报告生成时间**: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "**检查工具**: 运维健康检查 v1.0"
}
