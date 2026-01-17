# 运维健康检查 Skill - 使用示例

## 1. 基础使用 - 检查单台主机

```bash
# 最简单的方式 - 检查远程主机
ssh 192.168.0.42 'bash -s' < skills/ops-health-check/scripts/health-check.sh
```

**结果**：
- ✅ 运行时间：7 周 6 天
- ✅ CPU 负载：0.41, 0.41, 0.38
- ✅ 内存：42.4% (正常)
- ✅ 磁盘：26% (正常)
- ✅ 安全检查：无威胁
- ⚠️ 3 个服务失败

## 2. 保存报告到文件

```bash
# 自动生成带时间戳的报告文件
ssh 192.168.0.42 'bash -s' < skills/ops-health-check/scripts/health-check.sh > health-reports/192.168.0.42-$(date +%Y%m%d-%H%M%S).md

# 查看报告
cat health-reports/192.168.0.42-20260117-183440.md
```

**生成的报告**：
- 文件大小：987 字节
- 包含完整的 Markdown 格式报告
- 便于存档和历史对比

## 3. 自定义告警阈值（严格模式）

```bash
# 设置更严格的阈值
export DISK_WARNING=20 DISK_CRITICAL=25 \
       MEMORY_WARNING=30 MEMORY_CRITICAL=40

# 运行检查
ssh 192.168.0.42 "DISK_WARNING=$DISK_WARNING DISK_CRITICAL=$DISK_CRITICAL \
MEMORY_WARNING=$MEMORY_WARNING MEMORY_CRITICAL=$MEMORY_CRITICAL bash -s" < \
skills/ops-health-check/scripts/health-check.sh
```

**结果对比**：

| 指标 | 默认阈值 | 严格阈值 | 状态变化 |
|------|---------|---------|---------|
| 磁盘 26% | 50/80% | 20/25% | OK → **CRITICAL** |
| 内存 42.4% | 70/90% | 30/40% | OK → **CRITICAL** |

## 4. 检查失败的服务详情

```bash
# 查看失败的服务列表
ssh 192.168.0.42 "systemctl list-units --type=service --state=failed --no-pager"

# 查看具体服务的状态和日志
ssh 192.168.0.42 "systemctl status postfix@-.service --no-pager -l"
```

**发现**：
- 失败服务：postfix@-.service
- 原因：权限问题（LXC 容器限制）
- 时间：2025-11-23（已失败 1 个月 24 天）
- 影响：不影响核心功能（邮件服务非必需）

## 5. 多主机批量检查示例

```bash
# 创建主机列表
cat > /tmp/hosts.txt << EOF
192.168.0.42
192.168.0.43
192.168.0.44
EOF

# 循环检查所有主机
for host in $(cat /tmp/hosts.txt); do
  echo "=== Checking $host ==="
  ssh $host 'bash -s' < skills/ops-health-check/scripts/health-check.sh
  echo ""
done > health-reports/all-hosts-$(date +%Y%m%d).md
```

## 6. 定时任务示例（Cron）

```bash
# 编辑 crontab
crontab -e

# 每天早上 8 点检查所有主机
0 8 * * * ssh 192.168.0.42 'bash -s' < /path/to/skills/ops-health-check/scripts/health-check.sh > /path/to/health-reports/daily-$(date +\%Y\%m\%d).md

# 每 6 小时检查一次
0 */6 * * * for host in 192.168.0.42 192.168.0.43; do ssh $host 'bash -s' < /path/to/skills/ops-health-check/scripts/health-check.sh > /path/to/health-reports/${host}-$(date +\%Y\%m\%d-\%H\%M).md; done
```

## 7. 告警触发示例

```bash
# 检查并告警
ssh 192.168.0.42 'bash -s' < skills/ops-health-check/scripts/health-check.sh | \
grep -E "CRITICAL|WARNING" && \
echo "ALERT: Health check issues detected!" | \
mail -s "Server Health Alert" admin@example.com
```

## 8. 本地主机检查

```bash
# 检查本地主机
bash skills/ops-health-check/scripts/health-check.sh

# 保存本地报告
bash skills/ops-health-check/scripts/health-check.sh > health-reports/localhost-$(date +%Y%m%d).md
```

## 环境变量参考

| 变量名 | 默认值 | 说明 | 示例值 |
|--------|--------|------|--------|
| DISK_WARNING | 50 | 磁盘警告阈值（%） | 50 |
| DISK_CRITICAL | 80 | 磁盘严重阈值（%） | 80 |
| MEMORY_WARNING | 70 | 内存警告阈值（%） | 70 |
| MEMORY_CRITICAL | 90 | 内存严重阈值（%） | 90 |
| CPU_LOAD_WARNING | 200 | CPU 负载警告（2.0×100） | 200 |
| CPU_LOAD_CRITICAL | 500 | CPU 负载严重（5.0×100） | 500 |

## 输出状态说明

- **✅ OK (绿色)** - 所有指标在正常范围内
- **⚠️ WARNING (黄色)** - 超过警告阈值，需要关注
- **❌ CRITICAL (红色)** - 超过严重阈值，需要立即处理

## 限制和已知问题

1. **颜色代码**：远程 SSH 执行时会显示 ANSI 颜色代码（如 `[0;32m`），在终端中正常显示
2. **systemd 依赖**：服务检查需要 systemd，其他系统需要修改脚本
3. **LXC 容器**：某些服务（如 postfix）可能在容器中因权限限制而失败
4. **bc 命令**：脚本使用 awk 进行计算，避免依赖 bc

## 下一步改进建议

1. **修复颜色代码**：添加 `--no-color` 选项或自动检测
2. **JSON 输出**：便于程序化处理
3. **配置文件**：避免每次都设置环境变量
4. **Docker 支持**：添加容器检查
5. **告警通知**：集成邮件/钉钉/企微

---

**创建时间**: 2025-01-17
**测试主机**: 192.168.0.42 (Ubuntu LXC Container)
**Skill 版本**: ops-health-check v1.0 MVP
