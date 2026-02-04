#!/bin/bash

# 远程健康检查 + 自动发送邮件到本地
# 在本地运行，通过SSH检查远程主机，然后发送邮件

set -euo pipefail

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 配置
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EMAIL_SCRIPT="$HOME/.config/ops-health-check/send_report.sh"
EMAIL_CONFIG="$HOME/.config/ops-health-check/email.conf"
REPORT_DIR="${HOME}/health-reports"

show_help() {
    cat << EOF
远程健康检查 + 自动邮件发送

用法: $0 <host-ip> [选项]

参数:
    <host-ip>              目标主机IP地址

选项:
    -h, --help             显示帮助信息
    -s, --security         同时执行安全检查
    -d, --docker           同时执行Docker检查
    -r, --recipient <email> 指定收件人
    --no-email             不发送邮件（仅保存报告）

环境变量:
    EMAIL_RECIPIENT        默认收件人

示例:
    # 基础健康检查并发送邮件
    $0 192.168.0.42

    # 健康检查 + 安全检查
    $0 192.168.0.42 --security

    # 健康检查 + Docker检查
    $0 192.168.0.42 --docker

    # 完整检查（健康+安全+Docker）
    $0 192.168.0.42 --security --docker

    # 指定收件人
    $0 192.168.0.42 --recipient admin@example.com

EOF
}

# 默认值
DO_SECURITY=false
DO_DOCKER=false
SEND_EMAIL_FLAG=true
EMAIL_RECIPIENT="${EMAIL_RECIPIENT:-}"

# 解析参数
if [ $# -lt 1 ]; then
    show_help
    exit 1
fi

HOST="$1"
shift

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -s|--security)
            DO_SECURITY=true
            shift
            ;;
        -d|--docker)
            DO_DOCKER=true
            shift
            ;;
        -r|--recipient)
            EMAIL_RECIPIENT="$2"
            shift 2
            ;;
        --no-email)
            SEND_EMAIL_FLAG=false
            shift
            ;;
        *)
            echo -e "${RED}未知选项: $1${NC}"
            show_help
            exit 1
            ;;
    esac
done

# 检查邮件配置
check_email_config() {
    if [ "$SEND_EMAIL_FLAG" != "true" ]; then
        return 1
    fi
    
    if [ ! -f "$EMAIL_SCRIPT" ]; then
        echo -e "${YELLOW}警告: 邮件发送脚本不存在${NC}"
        return 1
    fi
    
    if [ ! -f "$EMAIL_CONFIG" ]; then
        echo -e "${YELLOW}警告: 邮件配置文件不存在${NC}"
        return 1
    fi
    
    return 0
}

# 创建报告目录
mkdir -p "$REPORT_DIR"

# 时间戳
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
OUTPUT_BASE="${REPORT_DIR}/health-check-${HOST}-${TIMESTAMP}"

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}   远程主机健康检查${NC}"
echo -e "${GREEN}========================================${NC}"
echo -e "目标主机: ${HOST}"
echo -e "开始时间: $(date '+%Y-%m-%d %H:%M:%S')"
echo ""

# 1. 健康检查
echo -e "${GREEN}[1/3]${NC} 执行基础健康检查..."
MD_OUTPUT=""
ssh "root@${HOST}" 'bash -s' < "${SCRIPT_DIR}/health-check-standalone.sh" > "${OUTPUT_BASE}.md" 2>&1 || true
if [ -f "${OUTPUT_BASE}.md" ]; then
    echo -e "${GREEN}✅ 健康检查完成${NC}"
else
    echo -e "${RED}❌ 健康检查失败${NC}"
fi

# 2. 安全检查
if [ "$DO_SECURITY" = true ]; then
    echo -e "${GREEN}[2/3]${NC} 执行深度安全检查..."
    ssh "root@${HOST}" 'bash -s' < "${SCRIPT_DIR}/security-check.sh" > "${OUTPUT_BASE}-security.md" 2>&1 || true
    if [ -f "${OUTPUT_BASE}-security.md" ]; then
        echo -e "${GREEN}✅ 安全检查完成${NC}"
        cat "${OUTPUT_BASE}-security.md" >> "${OUTPUT_BASE}.md"
    else
        echo -e "${YELLOW}⚠️ 安全检查失败${NC}"
    fi
fi

# 3. Docker检查
if [ "$DO_DOCKER" = true ]; then
    echo -e "${GREEN}[3/3]${NC} 执行Docker检查..."
    ssh "root@${HOST}" 'bash -s' < "${SCRIPT_DIR}/docker-check.sh" > "${OUTPUT_BASE}-docker.md" 2>&1 || true
    if [ -f "${OUTPUT_BASE}-docker.md" ]; then
        echo -e "${GREEN}✅ Docker检查完成${NC}"
        cat "${OUTPUT_BASE}-docker.md" >> "${OUTPUT_BASE}.md"
    else
        echo -e "${YELLOW}⚠️ Docker检查失败${NC}"
    fi
fi

# 发送邮件
if check_email_config; then
    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}   发送报告邮件${NC}"
    echo -e "${GREEN}========================================${NC}"
    
    # 生成邮件主题
    SUBJECT="健康检查报告 - ${HOST} - $(date +%Y-%m-%d)"
    if [ "$DO_SECURITY" = true ]; then
        SUBJECT="健康+安全检查报告 - ${HOST} - $(date +%Y-%m-%d)"
    fi
    if [ "$DO_DOCKER" = true ]; then
        SUBJECT="${SUBject} +Docker"
    fi
    
    # 发送邮件
    echo "正在发送邮件..."
    if [ -n "$EMAIL_RECIPIENT" ]; then
        bash "$EMAIL_SCRIPT" "${OUTPUT_BASE}.md" "$SUBJECT" "$EMAIL_RECIPIENT"
    else
        bash "$EMAIL_SCRIPT" "${OUTPUT_BASE}.md" "$SUBJECT"
    fi
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ 报告邮件已发送${NC}"
    else
        echo -e "${RED}❌ 邮件发送失败${NC}"
    fi
fi

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}   检查完成${NC}"
echo -e "${GREEN}========================================${NC}"
echo -e "报告文件: ${OUTPUT_BASE}.md"
echo -e "结束时间: $(date '+%Y-%m-%d %H:%M:%S')"
echo ""

