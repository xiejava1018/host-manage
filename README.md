# Host Management - Ops Health Check Skill

自动化运维健康检查 Skill，用于监控 Linux 主机的系统资源、Docker 容器、服务状态和安全指标。支持 **Markdown** 和 **JSON** 双格式输出。

## 项目结构

```
host-manage/
├── docs/
│   └── plans/
│       ├── 2025-01-17-ops-health-check-design.md     # 完整设计文档
│       └── 2025-01-18-json-output-design.md          # JSON 输出设计
├── skills/
│   └── ops-health-check/
│       ├── SKILL.md                                  # Skill 定义
│       └── scripts/
│           ├── health-check.sh                       # 基础健康检查
│           ├── security-check.sh                     # 深度安全检查
│           ├── docker-check.sh                       # Docker 监控
│           └── lib/
│               └── output.sh                         # 输出库（Markdown + JSON）
├── health-reports/                                   # 生成的报告
├── ops-health-check.skill                            # 打包的 Skill 文件
├── CLAUDE.md                                         # Claude Code 项目说明
└── README.md                                         # 本文件
```

## 当前版本：v1.1

### 已实现功能 ✅

- ✅ **系统资源检查**
  - 运行时间和 CPU 负载
  - 内存和 Swap 使用率
  - 磁盘空间（所有挂载点）
  - 网络连接统计

- ✅ **服务状态检查**
  - systemd 服务运行状态
  - 失败服务检测

- ✅ **Docker 监控** 🆕
  - 容器状态、资源使用
  - 镜像管理
  - 网络和卷统计
  - 存储空间分析

- ✅ **深度安全检查** 🆕
  - 异常进程检测（挖矿、高 CPU/内存）
  - 网络安全（反向 shell、高危端口）
  - 文件系统安全（最近修改、SUID/SGID）
  - 账户和登录安全
  - 系统完整性检查

- ✅ **双格式输出** 🆕
  - Markdown 报告（带 emoji 状态指示器）
  - JSON 格式（用于 API 和监控系统）

### 未来规划 📋

- 📊 多主机配置文件支持（YAML）
- 📈 历史趋势分析
- 📧 告警通知（邮件/钉钉/企微）

---

## 🚀 快速开始

### 方式 1️⃣: 直接使用脚本（推荐，最简单）

无需安装任何依赖，直接运行脚本：

```bash
# 1. 克隆仓库
git clone https://github.com/xiejava1018/host-manage.git
cd host-manage

# 2. 基础健康检查
ssh 192.168.0.42 'bash -s' < skills/ops-health-check/scripts/health-check.sh

# 3. Docker 监控
ssh 192.168.0.42 'bash -s' < skills/ops-health-check/scripts/docker-check.sh

# 4. 深度安全检查
ssh 192.168.0.42 'bash -s' < skills/ops-health-check/scripts/security-check.sh

# 5. 保存报告到文件
ssh 192.168.0.42 'bash -s' < skills/ops-health-check/scripts/health-check.sh > report.md
```

**优点**：
- ✅ 无需安装，开箱即用
- ✅ 适合自动化脚本和 cron 定时任务
- ✅ 易于调试和修改

---

### 方式 2️⃣: 安装为 Claude Code Skill

让 Claude Code 自动识别并使用此 skill：

#### Step 1: 下载 Skill 文件

```bash
# 直接下载
wget https://github.com/xiejava1018/host-manage/raw/main/ops-health-check.skill

# 或克隆仓库后复制
git clone https://github.com/xiejava1018/host-manage.git
cp host-manage/ops-health-check.skill .
```

#### Step 2: 安装 Skill

**macOS/Linux:**
```bash
mkdir -p ~/.claude/skills
cp ops-health-check.skill ~/.claude/skills/
```

**Windows:**
```powershell
mkdir $env:USERPROFILE\.claude\skills
Copy-Item ops-health-check.skill $env:USERPROFILE\.claude\skills\
```

#### Step 3: 重启 Claude Code

关闭并重新启动 Claude Code。

#### Step 4: 使用

现在可以直接对话：

```
你：检查 192.168.0.42 的健康状况
Claude Code：[自动识别并运行健康检查]
```

**优点**：
- ✅ AI 自动识别意图
- ✅ 无需手动输入命令
- ✅ 适合日常运维工作流

---

### 方式 3️⃣: 集成到项目 CLAUDE.md

在你项目的 `CLAUDE.md` 中引用此项目，Claude Code 会自动理解如何使用这些工具。

**示例**：
```markdown
## Project Overview

This project uses ops-health-check for monitoring:
- Basic health checks: `ssh <host> 'bash -s' < skills/ops-health-check/scripts/health-check.sh`
- Docker monitoring: `ssh <host> 'bash -s' < skills/ops-health-check/scripts/docker-check.sh`
- Security checks: `ssh <host> 'bash -s' < skills/ops-health-check/scripts/security-check.sh`
```

**优点**：
- ✅ 项目特定的运维工具
- ✅ 灵活，可随时修改
- ✅ 适合团队协作

---

## 📋 使用示例

### 基础健康检查

```bash
# 远程主机
ssh 192.168.0.42 'bash -s' < skills/ops-health-check/scripts/health-check.sh

# 本地主机
bash skills/ops-health-check/scripts/health-check.sh

# 自定义阈值
DISK_WARNING=30 DISK_CRITICAL=50 \
MEMORY_WARNING=60 MEMORY_CRITICAL=80 \
ssh 192.168.0.42 'bash -s' < skills/ops-health-check/scripts/health-check.sh
```

### Docker 监控

```bash
# 检查 Docker 状态
ssh 192.168.0.42 'bash -s' < skills/ops-health-check/scripts/docker-check.sh

# 查看容器资源使用
ssh 192.168.0.42 'bash -s' < skills/ops-health-check/scripts/docker-check.sh | grep -A 10 "容器资源"
```

### 深度安全检查

```bash
# 完整安全扫描（需要 root 权限）
ssh root@192.168.0.42 'bash -s' < skills/ops-health-check/scripts/security-check.sh

# 检查最近 48 小时修改的文件
RECENT_HOURS=48 \
ssh 192.168.0.42 'bash -s' < skills/ops-health-check/scripts/security-check.sh
```

### 批量检查多台主机

```bash
# 检查多个主机
for host in 192.168.0.42 192.168.0.43 192.168.0.44; do
  echo "=== Checking $host ==="
  ssh $host 'bash -s' < skills/ops-health-check/scripts/health-check.sh
  echo ""
done
```

### 使用 JSON 输出进行监控

```bash
# 查询整体状态
jq '.summary.overall_status' health-reports/*.json

# 提取内存使用率
jq '.details.memory.used_percent' health-reports/health-check-*.json

# 查找所有有告警的主机
for json in health-reports/*.json; do
  hostname=$(jq -r '.summary.host.hostname' "$json")
  status=$(jq -r '.summary.overall_status' "$json")
  if [ "$status" != "ok" ]; then
    echo "$hostname: $status"
  fi
done

# 发送到监控 API
curl -X POST http://monitoring/api/metrics \
  -H "Content-Type: application/json" \
  -d @health-reports/health-check-*.json
```

### 定时任务（Cron）

```bash
# 每天早上 8 点检查所有主机
0 8 * * * ssh 192.168.0.42 'bash -s' < /path/to/health-check.sh > /path/to/reports/daily-$(date +\%Y\%m\%d).md

# 每 5 分钟检查并生成 JSON
*/5 * * * * ssh 192.168.0.42 'bash -s' < /path/to/health-check.sh > /path/to/reports/health-$(date +\%Y\%m\%d-\%H\%M).json
```

---

## 📊 输出示例

### Markdown 报告

```markdown
# 系统健康检查报告

**检查时间**: 2026-01-18 11:37:32
**主机**: pve-ubuntu-pandawiki
**IP地址**: 192.168.0.55

## 💻 系统概览

### 运行时间与负载
- **运行时间**: up 3 hours, 56 minutes
- **平均负载**: 0.30, 0.21, 0.17

### 内存使用
- **内存**: 2455MB / 9945MB (24.7%) - ✅正常
- **交换分区**: 0MB / 3915MB (0.0%)

### 磁盘空间

| 文件系统 | 容量 | 已用 | 可用 | 使用率 | 挂载点 | 状态 |
|---------|------|------|------|--------|--------|------|
| /dev/mapper/ubuntu--vg-ubuntu--lv | 293G | 43G | 238G | 16% | / | ✅正常 |
| /dev/sda2 | 2.0G | 192M | 1.6G | 11% | /boot | ✅正常 |

## 🔒 安全检查

✅ **正常**: 未检测到挖矿进程
✅ **正常**: /tmp 中无可执行文件
- **最近失败登录**: 9 次
```

### JSON 报告

```json
{
  "summary": {
    "host": {
      "hostname": "pve-ubuntu-pandawiki",
      "ip": "192.168.0.55",
      "check_time": "2026-01-18T11:37:32+0800"
    },
    "overall_status": "ok",
    "status_counts": {
      "ok": 8,
      "warning": 1,
      "critical": 0
    }
  },
  "details": {
    "system": {
      "uptime": "up 3 hours, 56 minutes",
      "load_1m": 0.30,
      "load_5m": 0.21,
      "load_15m": 0.17
    },
    "memory": {
      "total_mb": 9945,
      "used_mb": 2455,
      "free_mb": 7490,
      "used_percent": 24.7,
      "status": "ok"
    }
  },
  "metadata": {
    "check_version": "1.0",
    "tool_version": "ops-health-check v1.1",
    "thresholds": {
      "disk": { "warning": 50, "critical": 80 },
      "memory": { "warning": 70, "critical": 90 },
      "cpu_load": { "warning": 2.0, "critical": 5.0 }
    }
  }
}
```

---

## ⚙️ 配置说明

### 默认阈值

- **磁盘使用率**: 警告 50%, 严重 80%
- **内存使用率**: 警告 70%, 严重 90%
- **CPU 负载**: 警告 2.0, 严重 5.0

### 环境变量

可通过环境变量自定义阈值：

```bash
# 基础检查
DISK_WARNING=50 DISK_CRITICAL=80 \
MEMORY_WARNING=70 MEMORY_CRITICAL=90 \
CPU_LOAD_WARNING=200 CPU_LOAD_CRITICAL=500 \
ssh <host> 'bash -s' < health-check.sh

# 安全检查
RECENT_HOURS=48 \              # 检查最近 48 小时修改的文件
MAX_CPU_PERCENT=80 \           # CPU 使用率阈值
MAX_MEM_PERCENT=50 \           # 内存使用率阈值
CHECK_DIRS="/tmp /var/tmp" \   # 检查目录
ssh <host> 'bash -s' < security-check.sh
```

### 状态指示器

- **✅正常 (OK)** - 所有指标在正常阈值内
- **⚠️警告 (WARNING)** - 超过警告阈值，需要关注
- **❌严重 (CRITICAL)** - 超过严重阈值，需要立即处理

---

## 📦 系统要求

### 远程主机需要

- Linux 操作系统（Ubuntu, CentOS, Debian 等）
- Bash shell（bash 3.2+）
- 标准工具：`free`, `df`, `uptime`, `ss`, `systemctl`
- SSH 访问权限

### Docker 检查额外需要

- Docker 已安装并运行
- 用户需要有 Docker 访问权限

### 安全检查建议

- root 权限（用于完整分析）
- `last`, `find`, `ps`, `netstat` 或 `ss` 命令

### 本地主机需要

- SSH 客户端
- Bash

---

## 🔄 开发路线图

### ✅ v1.1 - 当前版本（已完成）

- ✅ Docker 监控
- ✅ 深度安全检查
- ✅ JSON 输出格式
- ✅ 双格式报告（Markdown + JSON）

### 📋 v1.2 - 计划中

- YAML 配置文件支持
- 多主机批量检查
- 主机分组管理

### 📋 v1.3 - 计划中

- 历史数据追踪
- 趋势分析图表
- Web 仪表板

### 📋 v2.0 - 未来

- 告警通知（邮件/钉钉/企微/Slack）
- 自动修复常见问题
- 分布式监控架构

---

## 🤝 贡献指南

欢迎提交 Issue 和 Pull Request！

### 如何贡献

1. Fork 本仓库
2. 创建特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 开启 Pull Request

### 报告问题

请在 GitHub Issues 中报告 bug 或提出功能请求。

---

## 📄 许可证

MIT License

---

## 👨‍💻 作者

Created with ❤️ by [Claude Code](https://claude.ai/code) + [xiejava1018](https://github.com/xiejava1018)

---

## 📚 相关文档

- [完整设计文档](docs/plans/2025-01-17-ops-health-check-design.md)
- [JSON 输出设计](docs/plans/2025-01-18-json-output-design.md)
- [项目使用指南 (CLAUDE.md)](CLAUDE.md)

---

## 🌟 Star History

如果这个项目对你有帮助，请给个 Star ⭐️
