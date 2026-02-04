#!/bin/bash

# 健康检查脚本（带自动邮件发送）
# Linux主机健康检查 + 自动发送报告邮件

set -euo pipefail

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 默认配置
SEND_EMAIL=${SEND_EMAIL:-false}
EMAIL_RECIPIENT=${EMAIL_RECIPIENT:-""}
EMAIL_SUBJECT=${EMAIL_SUBJECT:-""}

# 帮助信息
show_help() {
    cat << EOF
健康检查脚本（带自动邮件发送）

用法: $0 [选项]

选项:
    -h, --help              显示帮助信息
    -e, --email             检查完成后发送邮件
    -r, --recipient <email> 指定收件人邮箱
    -s, --subject <subject> 指定邮件主题

环境变量:
    SEND_EMAIL              设置为true自动发送邮件
    EMAIL_RECIPIENT         收件人邮箱
    EMAIL_SUBJECT           邮件主题

示例:
    # 基础健康检查
    $0

    # 检查完成后发送邮件
    $0 --email

    # 指定收件人
    $0 --email --recipient user@example.com

    # 使用环境变量
    SEND_EMAIL=true $0

EOF
}

# 解析命令行参数
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -e|--email)
            SEND_EMAIL=true
            shift
            ;;
        -r|--recipient)
            EMAIL_RECIPIENT="$2"
            shift 2
            ;;
        -s|--subject)
            EMAIL_SUBJECT="$2"
            shift 2
            ;;
        *)
            echo "未知选项: $1"
            show_help
            exit 1
            ;;
    esac
done

# 获取脚本目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 检查standalone脚本是否存在
STANDALONE_SCRIPT="$SCRIPT_DIR/health-check-standalone.sh"
if [ ! -f "$STANDALONE_SCRIPT" ]; then
    echo -e "${RED}错误: 找不到健康检查脚本 $STANDALONE_SCRIPT${NC}"
    exit 1
fi

# 检查邮件发送配置
EMAIL_SCRIPT="$HOME/.config/ops-health-check/send_report.sh"
EMAIL_CONFIG="$HOME/.config/ops-health-check/email.conf"

can_send_email() {
    if [ "$SEND_EMAIL" != "true" ]; then
        return 1
    fi
    
    if [ ! -f "$EMAIL_SCRIPT" ]; then
        echo -e "${YELLOW}警告: 邮件发送脚本不存在: $EMAIL_SCRIPT${NC}"
        echo "跳过邮件发送"
        return 1
    fi
    
    if [ ! -f "$EMAIL_CONFIG" ]; then
        echo -e "${YELLOW}警告: 邮件配置文件不存在: $EMAIL_CONFIG${NC}"
        echo "跳过邮件发送"
        return 1
    fi
    
    return 0
}

# 运行健康检查
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}   运维健康检查（支持邮件报告）${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# 执行健康检查
bash "$STANDALONE_SCRIPT"

CHECK_RESULT=$?
REPORT_FILE=$(ls -t /tmp/health-check-*.txt 2>/dev/null | head -1 || echo "")

# 如果standalone没有输出文件，生成一个
if [ -z "$REPORT_FILE" ] || [ ! -f "$REPORT_FILE" ]; then
    echo ""
    echo "正在生成报告文件..."
    REPORT_FILE="/tmp/health-check-$(hostname)-$(date +%Y%m%d-%H%M%S).txt"
    
    # 重新运行并保存输出
    bash "$STANDALONE_SCRIPT" > "$REPORT_FILE" 2>&1 || true
fi

# 检查结果
if [ $CHECK_RESULT -eq 0 ]; then
    echo -e "${GREEN}✅ 健康检查完成${NC}"
else
    echo -e "${YELLOW}⚠️ 健康检查完成，但发现一些问题${NC}"
fi

# 发送邮件
if can_send_email; then
    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}   发送报告邮件${NC}"
    echo -e "${GREEN}========================================${NC}"
    
    # 确定邮件主题
    if [ -z "$EMAIL_SUBJECT" ]; then
        EMAIL_SUBJECT="健康检查报告 - $(hostname) - $(date +%Y-%m-%d)"
    fi
    
    # 构建收件人参数
    RECIPIENT_PARAM=""
    if [ -n "$EMAIL_RECIPIENT" ]; then
        RECIPIENT_PARAM="$EMAIL_RECIPIENT"
    fi
    
    # 发送邮件
    echo "正在发送邮件到 ${EMAIL_RECIPIENT:-默认收件人}..."
    
    if [ -n "$RECIPIENT_PARAM" ]; then
        bash "$EMAIL_SCRIPT" "$REPORT_FILE" "$EMAIL_SUBJECT" "$RECIPIENT_PARAM"
    else
        bash "$EMAIL_SCRIPT" "$REPORT_FILE" "$EMAIL_SUBJECT"
    fi
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ 报告邮件已发送${NC}"
    else
        echo -e "${RED}❌ 邮件发送失败${NC}"
    fi
fi

echo ""
echo "报告文件: $REPORT_FILE"

exit $CHECK_RESULT
