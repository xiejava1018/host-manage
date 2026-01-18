# JSON 输出格式功能设计

## 概述

为 ops-health-check 工具添加 JSON 输出格式支持，每次检查自动同时生成 Markdown 和 JSON 两种格式的报告，满足人工阅读和机器处理的双重需求。

## 设计目标

- **多用途支持** - 同时支持人类可读的 Markdown 和机器可处理的 JSON
- **分层结构** - JSON 包含 summary（摘要）和 details（详细数据）两部分
- **易于集成** - 便于监控系统、API 和自动化脚本使用
- **代码复用** - 三个检查脚本共用输出逻辑

## JSON 数据结构

### 完整示例

```json
{
  "summary": {
    "host": {
      "hostname": "server-01",
      "ip": "192.168.0.42",
      "check_time": "2025-01-17T19:30:00+08:00",
      "check_duration": 2.5
    },
    "overall_status": "ok",
    "status_counts": {
      "ok": 15,
      "warning": 2,
      "critical": 0
    },
    "check_types": ["health"]
  },
  "details": {
    "system": {
      "uptime": "15 days, 3:24",
      "load_average": [0.5, 0.8, 1.2],
      "cpu": {
        "status": "ok",
        "load_1min": 0.5,
        "load_5min": 0.8,
        "load_15min": 1.2
      },
      "memory": {
        "status": "warning",
        "total_mb": 16384,
        "used_mb": 12500,
        "available_mb": 3884,
        "used_percent": 76.3,
        "swap_total_mb": 2048,
        "swap_used_mb": 256
      },
      "disk": [
        {
          "device": "/dev/sda1",
          "mount": "/",
          "status": "ok",
          "total_gb": 100,
          "used_gb": 45,
          "available_gb": 55,
          "used_percent": 45.0
        },
        {
          "device": "/dev/sdb1",
          "mount": "/data",
          "status": "warning",
          "total_gb": 500,
          "used_gb": 425,
          "available_gb": 75,
          "used_percent": 85.0
        }
      ],
      "network": {
        "active_connections": 45,
        "listening_ports": 12
      }
    },
    "services": {
      "systemd_enabled": 25,
      "systemd_running": 23,
      "systemd_failed": 2
    }
  },
  "metadata": {
    "check_version": "1.0",
    "tool_version": "ops-health-check v1.0",
    "thresholds": {
      "disk_warning": 50,
      "disk_critical": 80,
      "memory_warning": 70,
      "memory_critical": 90
    },
    "check_script": "health-check.sh"
  }
}
```

### 结构说明

**summary 部分** - 快速摘要
- `host`: 主机基本信息
- `overall_status`: 整体状态 (ok/warning/critical)
- `status_counts`: 各级别的检查项数量
- `check_types`: 执行的检查类型列表

**details 部分** - 详细数据
- `system`: 系统资源详情
- `services`: 服务状态
- `docker`: Docker 容器信息（Docker 检查时）
- `security`: 安全检查详情（安全检查时）

**metadata 部分** - 元数据
- 检查版本和工具版本
- 使用的阈值配置
- 执行的脚本名称

## 实现方案

### 文件结构

```
scripts/
├── lib/
│   └── output.sh          # 新增：输出格式化库
├── health-check.sh        # 修改：使用 output.sh
├── security-check.sh      # 修改：使用 output.sh
└── docker-check.sh        # 修改：使用 output.sh
```

### 核心函数

**`scripts/lib/output.sh` 提供**：

```bash
# 初始化输出数据结构
init_output()

# 收集摘要数据
add_summary_field "hostname" "$HOSTNAME"
add_summary_field "ip" "$IP"
add_summary_field "overall_status" "ok"
add_status_count "ok" 15

# 收集详细数据
add_system_data "uptime" "$uptime"
add_memory_data "used_percent" 76.3
add_disk_data "/" "used_percent" 45.0
add_docker_data "containers_running" 8

# 生成报告
generate_markdown "$output_file.md"
generate_json "$output_file.json"
```

### JSON 生成策略

1. **优先使用 jq** - 如果系统安装了 `jq`，使用它生成标准 JSON
2. **降级方案** - 如果没有 jq，使用 Bash 手动拼接 JSON
3. **时间格式** - 使用 ISO 8601 格式（`date -u +%Y-%m-%dT%H:%M:%S%z`）

### 文件命名规则

```
health-reports/
├── health-check-192.168.0.42-20250117-193000.md
├── health-check-192.168.0.42-20250117-193000.json
├── security-check-192.168.0.18-20250117-193000.md
├── security-check-192.168.0.18-20250117-193000.json
├── docker-check-192.168.0.42-20250117-193000.md
└── docker-check-192.168.0.42-20250117-193000.json
```

相同基础名，不同扩展名，便于关联。

## 使用示例

### 执行检查

```bash
# 远程检查（自动生成两种格式）
ssh 192.168.0.42 'bash -s' < scripts/health-check.sh

# 本地检查
bash scripts/health-check.sh

# 输出示例
# ✅ 报告已生成：
# 📄 Markdown: health-reports/health-check-192.168.0.42-20250117-193000.md
# 📊 JSON:      health-reports/health-check-192.168.0.42-20250117-193000.json
```

### 使用 JSON 数据

```bash
# 使用 jq 查询整体状态
jq '.summary.overall_status' health-reports/*.json

# 提取内存使用率
jq '.details.memory.used_percent' health-reports/*.json

# 批量分析多台主机
for json in health-reports/*.json; do
  hostname=$(jq -r '.summary.host.hostname' "$json")
  status=$(jq -r '.summary.overall_status' "$json")
  echo "$hostname: $status"
done

# 发送到监控系统
curl -X POST http://monitoring/api/metrics \
  -H "Content-Type: application/json" \
  -d @health-reports/health-check-*.json
```

## 兼容性

- **向后兼容** - 原有 Markdown 输出格式不变
- **可选依赖** - jq 不是必需的，有降级方案
- **标准 JSON** - 遵循 RFC 8259，兼容所有 JSON 解析器

## 未来扩展

- 支持其他格式（XML、CSV、InfluxDB Line Protocol）
- 添加 JSON Schema 验证
- 支持增量更新（追加历史数据到 JSON）
- 添加 JSON 输出过滤选项（只输出 summary 或 details）
