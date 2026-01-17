# Host Management - Ops Health Check Skill

自动化运维健康检查 Skill，用于监控 Linux 主机的系统资源、服务状态和安全指标。

## 项目结构

```
host-manage/
├── docs/
│   └── plans/
│       └── 2025-01-17-ops-health-check-design.md  # 完整设计文档
├── skills/
│   └── ops-health-check/
│       ├── SKILL.md                                # Skill 定义
│       └── scripts/
│           └── health-check.sh                     # 健康检查脚本
├── ops-health-check.skill                          # 打包的 Skill 文件
└── README.md                                        # 本文件
```

## 当前版本：MVP v1.0

这是第一个最小可行产品（MVP）版本，包含核心功能。

### 已实现功能 ✅

- ✅ **系统资源检查**
  - 运行时间和 CPU 负载
  - 内存和 Swap 使用率
  - 磁盘空间（所有挂载点）
  - 网络连接统计

- ✅ **服务状态检查**
  - systemd 服务运行状态
  - 失败服务检测

- ✅ **快速安全检查**
  - 挖矿程序检测（xmrig, minerd, cpuminer）
  - /tmp 可疑文件检查
  - 失败登录尝试统计

- ✅ **Markdown 报告生成**
  - 带状态指示器（OK/WARNING/CRITICAL）
  - 可配置的告警阈值

### 未来规划 📋

- 🐳 Docker 容器监控
- 📝 JSON 输出格式
- 📊 多主机配置文件支持
- 🔒 深度安全检查（rootkit、勒索病毒）
- 📈 历史趋势分析
- 📧 告警通知（邮件/钉钉/企微）

## 快速开始

### 安装 Skill

1. 将 `ops-health-check.skill` 文件复制到你的 Claude Code skills 目录
2. 重启 Claude Code 或重新加载 skills

### 使用方法

**检查单台主机：**

```bash
# 通过 SSH 检查远程主机
ssh 192.168.0.42 'bash -s' < skills/ops-health-check/scripts/health-check.sh

# 保存报告到文件
ssh 192.168.0.42 'bash -s' < skills/ops-health-check/scripts/health-check.sh > report.md
```

**检查本地主机：**

```bash
bash skills/ops-health-check/scripts/health-check.sh
```

**自定义阈值：**

```bash
DISK_WARNING=50 DISK_CRITICAL=80 \
MEMORY_WARNING=70 MEMORY_CRITICAL=90 \
ssh 192.168.0.42 'bash -s' < skills/ops-health-check/scripts/health-check.sh
```

## 输出示例

```markdown
# System Health Check Report

**Check Time**: 2025-01-17 10:29:50
**Host**: pve-LXC-ubuntu02
**IP**: 192.168.0.42

## 💻 System Overview

### Uptime & Load
- **Uptime**: up 7 weeks, 6 days, 1 hour, 57 minutes
- **Load Average**: 0.31, 0.37, 0.38

### Memory Usage
- **Memory**: 1737MB / 4096MB (42.4%) - OK
- **Swap**: 97MB / 2048MB (4.7%)

### Disk Space

| Filesystem | Size | Used | Available | Use% | Mount Point | Status |
|------------|------|------|-----------|-----|-------------|--------|
| GW2T/subvol-102-disk-0 | 50G | 13G | 38G | 26% | / | OK |

## 🔒 Quick Security Check

✅ **OK**: No mining processes detected
✅ **OK**: No executable files in /tmp
- **Recent Failed Logins**: 0
```

## 配置说明

### 默认阈值

- **磁盘使用率**: 警告 50%, 严重 80%
- **内存使用率**: 警告 70%, 严重 90%
- **CPU 负载**: 警告 2.0, 严重 5.0

### 环境变量

可通过环境变量自定义阈值：

- `DISK_WARNING`: 磁盘警告阈值（百分比）
- `DISK_CRITICAL`: 磁盘严重阈值（百分比）
- `MEMORY_WARNING`: 内存警告阈值（百分比）
- `MEMORY_CRITICAL`: 内存严重阈值（百分比）
- `CPU_LOAD_WARNING`: CPU 负载警告阈值（整数，200 = 2.0）
- `CPU_LOAD_CRITICAL`: CPU 负载严重阈值（整数，500 = 5.0）

## 系统要求

### 远程主机需要

- Linux 操作系统
- Bash shell
- 标准工具：`free`, `df`, `uptime`, `ss`, `systemctl`
- SSH 访问权限

### 本地主机需要

- SSH 客户端
- Bash

## 开发路线图

### v1.1 - Docker 监控
- Docker 容器状态检查
- 容器资源使用统计
- 镜像和卷管理

### v1.2 - 配置文件
- YAML 配置文件支持
- 多主机批量检查
- 主机分组

### v1.3 - 高级功能
- JSON 输出格式
- 深度安全检查
- 历史数据追踪

### v2.0 - 企业级功能
- Web 界面
- 告警通知
- 趋势分析
- 自动修复

## 贡献指南

欢迎提交 Issue 和 Pull Request！

## 许可证

MIT License

## 作者

Created with ❤️ by Claude Code + 用户协作

---

**查看完整设计文档**: [docs/plans/2025-01-17-ops-health-check-design.md](docs/plans/2025-01-17-ops-health-check-design.md)
