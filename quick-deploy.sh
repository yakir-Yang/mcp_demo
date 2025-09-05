#!/bin/bash

# 快速部署脚本 - 修复腾讯云ADP连接问题

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 配置
CVM_HOST="106.53.191.184"
CVM_USER="ubuntu"
CVM_PATH="~/mcp_demo"

echo -e "${BLUE}=========================================="
echo "  快速部署 - 修复腾讯云ADP连接问题"
echo "==========================================${NC}"
echo

# 上传修复后的文件
echo -e "${BLUE}[步骤1]${NC} 上传修复后的文件..."
scp src/http-server.js $CVM_USER@$CVM_HOST:$CVM_PATH/src/
echo -e "${GREEN}✅ 文件上传完成${NC}"

# 在CVM上重启服务
echo -e "${BLUE}[步骤2]${NC} 重启服务..."
ssh $CVM_USER@$CVM_HOST << 'EOF'
    cd ~/mcp_demo
    pm2 restart mcp-http-server
    pm2 save
    echo "✅ 服务重启完成"
EOF

# 等待服务启动
echo -e "${BLUE}[步骤3]${NC} 等待服务启动..."
sleep 5

# 测试服务
echo -e "${BLUE}[步骤4]${NC} 测试服务..."
ssh $CVM_USER@$CVM_HOST << 'EOF'
    cd ~/mcp_demo
    echo "测试健康检查..."
    curl -s http://localhost:3000/health | head -1
    echo "测试SSE端点..."
    curl -I http://localhost:3000/sse | head -3
    echo "✅ 服务测试完成"
EOF

echo
echo -e "${GREEN}🎉 部署完成！${NC}"
echo
echo -e "${BLUE}腾讯云ADP配置:${NC}"
echo "URL: http://106.53.191.184:3000"
echo "超时: 120秒"
echo "SSE读取超时: 600秒"
echo
echo -e "${YELLOW}关键修复:${NC}"
echo "✅ 根据Accept头智能响应（JSON或SSE）"
echo "✅ 改进的腾讯云ADP检测"
echo "✅ 更详细的日志记录"
echo "✅ 优化的连接管理"
echo
echo -e "${BLUE}监控命令:${NC}"
echo "ssh $CVM_USER@$CVM_HOST 'cd ~/mcp_demo && pm2 logs mcp-http-server'"
