#!/bin/bash

# 邮件功能安装向导
# 帮助用户快速配置自动邮件发送功能

set -euo pipefail

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}   运维健康检查 - 邮件功能安装向导${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# 配置目录
CONFIG_DIR="$HOME/.config/ops-health-check"
CONFIG_FILE="$CONFIG_DIR/email.conf"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 检查是否已配置
if [ -f "$CONFIG_FILE" ]; then
    echo -e "${YELLOW}检测到已存在邮件配置文件${NC}"
    echo "配置文件: $CONFIG_FILE"
    echo ""
    read -p "是否重新配置? (y/N): " reconfigure
    if [[ ! $reconfigure =~ ^[Yy]$ ]]; then
        echo "保持现有配置"
        exit 0
    fi
    echo ""
fi

# 创建配置目录
mkdir -p "$CONFIG_DIR"

echo -e "${BLUE}步骤 1/4: 选择SMTP服务器${NC}"
echo ""
echo "请选择您的邮箱服务提供商:"
echo "  1) QQ邮箱 (smtp.qq.com:465)"
echo "  2) Gmail (smtp.gmail.com:587)"
echo "  3) Outlook/Office365 (smtp.office365.com:587)"
echo "  4) 163邮箱 (smtp.163.com:465)"
echo "  5) 自定义SMTP服务器"
echo ""
read -p "请输入选项 (1-5): " smtp_choice

case $smtp_choice in
    1)
        SMTP_SERVER="smtp.qq.com"
        SMTP_PORT="465"
        USE_SSL="true"
        echo "您选择了: QQ邮箱"
        echo "获取授权码步骤: QQ邮箱 → 设置 → 账户 → 开启SMTP服务 → 生成授权码"
        ;;
    2)
        SMTP_SERVER="smtp.gmail.com"
        SMTP_PORT="587"
        USE_SSL="false"
        echo "您选择了: Gmail"
        echo "注意: Gmail需要使用应用专用密码，需要在Google账户设置中生成"
        ;;
    3)
        SMTP_SERVER="smtp.office365.com"
        SMTP_PORT="587"
        USE_SSL="false"
        echo "您选择了: Outlook/Office365"
        ;;
    4)
        SMTP_SERVER="smtp.163.com"
        SMTP_PORT="465"
        USE_SSL="true"
        echo "您选择了: 163邮箱"
        ;;
    5)
        read -p "请输入SMTP服务器地址: " SMTP_SERVER
        read -p "请输入端口号 (通常465或587): " SMTP_PORT
        read -p "使用SSL? (true/false): " USE_SSL
        ;;
    *)
        echo -e "${RED}无效选项${NC}"
        exit 1
        ;;
esac

echo ""
echo -e "${BLUE}步骤 2/4: 配置发件人信息${NC}"
echo ""
read -p "请输入发件人邮箱地址: " sender_email
read -p "请输入发件人显示名称 (默认: 系统监控): " sender_name
sender_name=${sender_name:-系统监控}

echo ""
echo -e "${BLUE}步骤 3/4: 配置认证信息${NC}"
echo ""
echo -e "${YELLOW}重要: 请输入邮箱授权码（不是登录密码！）${NC}"
read -sp "请输入授权码: " auth_code
echo ""

echo ""
echo -e "${BLUE}步骤 4/4: 配置默认收件人${NC}"
echo ""
read -p "请输入默认收件人邮箱地址: " default_recipient

# 生成配置文件
cat > "$CONFIG_FILE" << EOCONFIG
# 邮件配置文件
# 自动生成于 $(date)

# SMTP服务器
SMTP_SERVER=$SMTP_SERVER
SMTP_PORT=$SMTP_PORT
USE_SSL=$USE_SSL

# 发件人邮箱
SENDER_EMAIL=$sender_email
SENDER_NAME=$sender_name

# 授权码
AUTH_CODE=$auth_code

# 默认收件人
DEFAULT_RECIPIENT=$default_recipient
EOCONFIG

# 设置权限
chmod 600 "$CONFIG_FILE"

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}   配置完成！${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "配置文件已保存到: $CONFIG_FILE"
echo "权限已设置为: 600 (仅所有者可读写)"
echo ""

# 复制Python脚本
if [ ! -f "$CONFIG_DIR/send_email_auto.py" ]; then
    cp "$SCRIPT_DIR/../../../.config/ops-health-check/send_email_auto.py" "$CONFIG_DIR/" 2>/dev/null || true
fi

# 测试邮件发送
echo -e "${BLUE}是否发送测试邮件验证配置?${NC}"
read -p "发送测试邮件? (y/N): " send_test

if [[ $send_test =~ ^[Yy]$ ]]; then
    # 创建测试报告
    TEST_REPORT="/tmp/email-test-$(date +%Y%m%d-%H%M%S).txt"
    cat > "$TEST_REPORT" << EOREPORT
========================================
邮件功能测试报告
========================================

测试时间: $(date)
测试主机: $(hostname)

这是一封测试邮件，用于验证邮件功能配置是否成功。

如果您收到此邮件，说明配置正确！

========================================
EOREPORT

    # 获取Python脚本路径
    PYTHON_SCRIPT="$CONFIG_DIR/send_email_auto.py"
    if [ ! -f "$PYTHON_SCRIPT" ]; then
        PYTHON_SCRIPT="$HOME/.config/ops-health-check/send_email_auto.py"
    fi
    
    if [ -f "$PYTHON_SCRIPT" ]; then
        echo "正在发送测试邮件到 $default_recipient..."
        if python3 "$PYTHON_SCRIPT" "邮件功能测试" "$TEST_REPORT"; then
            echo -e "${GREEN}✅ 测试邮件发送成功！${NC}"
            echo "请检查收件箱确认收到邮件"
        else
            echo -e "${RED}❌ 测试邮件发送失败${NC}"
            echo "请检查配置是否正确"
        fi
        rm -f "$TEST_REPORT"
    else
        echo -e "${YELLOW}警告: 找不到邮件发送脚本${NC}"
        echo "请确保已安装完整功能"
    fi
fi

echo ""
echo -e "${GREEN}邮件功能配置完成！${NC}"
echo "现在可以使用 --email 选项自动发送检查报告"
