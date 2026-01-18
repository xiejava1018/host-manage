#!/bin/bash

# Docker 容器监控检查脚本（简化稳定版）
# 检查 Docker 服务、容器、镜像、网络、卷的运行状态

echo "# Docker 容器监控报告"
echo ""
echo "**检查时间**: $(date '+%Y-%m-%d %H:%M:%S')"
echo "**主机**: $(hostname)"
echo "**IP地址**: $(hostname -I | awk '{print $1}')"
echo ""

# 检查 Docker 是否安装
if ! command -v docker &> /dev/null; then
    echo "❌ **Docker 未安装**"
    echo ""
    echo "---"
    echo ""
    echo "**检查完成时间**: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "**检查工具**: Docker 容器监控 v1.0"
    exit 0
fi

# ============================================================================
# 1. Docker 服务状态
# ============================================================================
echo "## 🐳 Docker 服务状态"
echo ""

docker_service_status=$(systemctl is-active docker 2>/dev/null || echo "unknown")
if [ "$docker_service_status" = "active" ]; then
    echo "Docker 服务: ✅ 运行中"
else
    echo "Docker 服务: ❌ $docker_service_status"
fi
echo ""

# Docker 版本信息
docker_version=$(docker version --format '{{.Server.Version}}' 2>/dev/null || echo "unknown")
echo "Docker 版本: $docker_version"
echo ""

# ============================================================================
# 2. 容器状态概览
# ============================================================================
echo "## 📦 容器状态概览"
echo ""

echo "**容器列表**："
docker ps -a 2>/dev/null || echo "无法获取容器列表"
echo ""

# 统计
total=$(docker ps -a --format "{{.ID}}" 2>/dev/null | wc -l | tr -d ' ' || echo 0)
running=$(docker ps --format "{{.ID}}" 2>/dev/null | wc -l | tr -d ' ' || echo 0)
echo "**统计**："
echo "- 总容器数: $total"
echo "- 运行中: $running"
echo "- 已停止: $((total - running))"
echo ""

# 资源使用
echo "**资源使用 Top 5**："
docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}" 2>/dev/null | head -6 || echo "无法获取资源信息"
echo ""

# ============================================================================
# 3. 镜像信息
# ============================================================================
echo "## 📷 Docker 镜像"
echo ""

echo "**镜像列表**（Top 10）："
docker images 2>/dev/null | head -11 || echo "无法获取镜像列表"
echo ""

# 统计
total_images=$(docker images --format "{{.ID}}" 2>/dev/null | wc -l | tr -d ' ' || echo 0)
dangling=$(docker images -f "dangling=true" -q 2>/dev/null | wc -l | tr -d ' ' || echo 0)
echo "- 总镜像数: $total_images"
echo "- 悬空镜像: $dangling"
echo ""

if [ $dangling -gt 0 ]; then
  echo "⚠️ **注意**: 发现悬空镜像"
  echo "清理: docker image prune"
fi
echo ""

# ============================================================================
# 4. Docker 网络
# ============================================================================
echo "## 🌐 Docker 网络"
echo ""

echo "**网络列表**："
docker network ls 2>/dev/null || echo "无法获取网络列表"
echo ""

network_count=$(docker network ls --format "{{.ID}}" 2>/dev/null | wc -l | tr -d ' ' || echo 0)
echo "- 网络数量: $network_count"
echo ""

# ============================================================================
# 5. Docker 卷
# ============================================================================
echo "## 💾 Docker 卷"
echo ""

echo "**卷列表**："
docker volume ls 2>/dev/null || echo "无法获取卷列表"
echo ""

volume_count=$(docker volume ls --format "{{.Name}}" 2>/dev/null | wc -l | tr -d ' ' || echo 0)
unused=$(docker volume ls -f "dangling=true" -q 2>/dev/null | wc -l | tr -d ' ' || echo 0)
echo "- 卷数量: $volume_count"
echo "- 未使用: $unused"
echo ""

# ============================================================================
# 6. 系统信息
# ============================================================================
echo "## ℹ️ Docker 系统信息"
echo ""

echo "**存储空间使用**："
docker system df 2>/dev/null || echo "无法获取存储信息"
echo ""

echo "**Docker 根目录**："
docker info 2>/dev/null | grep "Docker Root Dir" || echo "无法获取根目录信息"
echo ""

# ============================================================================
# 7. 清理建议
# ============================================================================
echo "## 💡 清理建议"
echo ""

echo "**常用清理命令**："
echo "- 清理悬空镜像: docker image prune"
echo "- 清理停止的容器: docker container prune"
echo "- 清理未使用的卷: docker volume prune"
echo "- 清理构建缓存: docker builder prune"
echo ""
echo "- **一键清理所有**: docker system prune -a --volumes"
echo ""

# 页脚
echo "---"
echo ""
echo "**检查完成时间**: $(date '+%Y-%m-%d %H:%M:%S')"
echo "**检查工具**: Docker 容器监控 v1.0"
