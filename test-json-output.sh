#!/bin/bash

# 简单的 JSON 输出测试脚本

# 加载输出库
source "scripts/lib/output.sh"

echo "=== 测试 JSON 输出功能 ==="
echo ""

# 初始化输出
init_output "health"

# 添加测试数据
add_system_data "uptime" "15 days, 3:24"
add_system_data "load_1min" "0.5"
add_system_data "load_5min" "0.8"
add_system_data "load_15min" "1.2"

add_memory_data "total_mb" "16384"
add_memory_data "used_mb" "12500"
add_memory_data "available_mb" "3884"
add_memory_data "used_percent" "76.3"
add_memory_data "status" "warning"

add_disk_data "/dev/sda1" "/" "100G" "45G" "55G" "45.0" "ok"
add_disk_data "/dev/sdb1" "/data" "500G" "425G" "75G" "85.0" "warning"

add_service_data "systemd_running" "23"
add_service_data "systemd_failed" "2"

add_security_field "mining_detected" "false"
add_security_field "tmp_executables" "0"
add_security_field "failed_logins" "3"

add_status_count "ok" 8
add_status_count "warning" 3
add_status_count "critical" 0

set_overall_status "warning"

# 生成 JSON 文件
OUTPUT_DIR="health-reports"
mkdir -p "$OUTPUT_DIR"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
OUTPUT_BASE="${OUTPUT_DIR}/test-output-${TIMESTAMP}"

generate_json "${OUTPUT_BASE}.json"

echo ""
echo "=== 测试完成 ==="
echo "JSON 文件: ${OUTPUT_BASE}.json"

# 显示 JSON 内容
if command -v jq &> /dev/null; then
    echo ""
    echo "=== JSON 内容（格式化） ==="
    jq . "${OUTPUT_BASE}.json"
else
    echo ""
    echo "=== JSON 内容 ==="
    cat "${OUTPUT_BASE}.json"
fi
