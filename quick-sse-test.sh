#!/bin/bash

# 快速SSE测试脚本
# 用于快速验证SSE连接是否正常

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 配置
SERVER_URL="http://106.53.191.184:3000"

echo -e "${BLUE}=========================================="
echo "  快速SSE测试"
echo "  服务器: $SERVER_URL"
echo "==========================================${NC}"
echo

# 测试1: 检查SSE端点是否可访问
echo -e "${BLUE}[测试1]${NC} 检查SSE端点..."
if curl -s -I "$SERVER_URL/sse" --connect-timeout 10 | grep -q "200 OK"; then
    echo -e "${GREEN}✅ SSE端点可访问${NC}"
else
    echo -e "${RED}❌ SSE端点不可访问${NC}"
    exit 1
fi

# 测试2: 检查响应头
echo -e "${BLUE}[测试2]${NC} 检查响应头..."
response=$(curl -s -I "$SERVER_URL/sse" --connect-timeout 10)

if echo "$response" | grep -q "Content-Type: text/event-stream"; then
    echo -e "${GREEN}✅ Content-Type正确${NC}"
else
    echo -e "${RED}❌ Content-Type错误${NC}"
fi

if echo "$response" | grep -q "Cache-Control: no-cache"; then
    echo -e "${GREEN}✅ Cache-Control正确${NC}"
else
    echo -e "${YELLOW}⚠️  Cache-Control可能有问题${NC}"
fi

# 测试3: 测试SSE数据流（10秒）
echo -e "${BLUE}[测试3]${NC} 测试SSE数据流（10秒）..."
echo "正在连接SSE流..."

# 使用timeout命令测试10秒
timeout 10s curl -s -N "$SERVER_URL/sse" > /tmp/sse_output.log 2>&1 &
curl_pid=$!

# 等待连接建立
sleep 3

# 检查是否有数据
if [ -f /tmp/sse_output.log ] && [ -s /tmp/sse_output.log ]; then
    line_count=$(wc -l < /tmp/sse_output.log)
    echo -e "${GREEN}✅ SSE数据流正常，收到 $line_count 行数据${NC}"
    
    # 显示前几行数据
    echo "前5行数据:"
    head -5 /tmp/sse_output.log | sed 's/^/  /'
    
    # 检查消息类型
    if grep -q "event: connected" /tmp/sse_output.log; then
        echo -e "${GREEN}✅ 连接事件正常${NC}"
    fi
    
    if grep -q "event: heartbeat" /tmp/sse_output.log; then
        echo -e "${GREEN}✅ 心跳事件正常${NC}"
    fi
    
else
    echo -e "${RED}❌ SSE数据流异常${NC}"
fi

# 清理
rm -f /tmp/sse_output.log

echo
echo -e "${BLUE}=========================================="
echo "  快速SSE测试完成"
echo "==========================================${NC}"

# 如果所有测试都通过，显示成功信息
if [ $? -eq 0 ]; then
    echo -e "${GREEN}🎉 SSE连接测试通过！${NC}"
    echo
    echo -e "${BLUE}腾讯云ADP配置:${NC}"
    echo "URL: $SERVER_URL"
    echo "超时: 120秒"
    echo "SSE读取超时: 600秒"
else
    echo -e "${RED}❌ SSE连接测试失败${NC}"
    echo
    echo -e "${YELLOW}故障排除建议:${NC}"
    echo "1. 检查服务器是否运行"
    echo "2. 检查防火墙设置"
    echo "3. 查看服务器日志"
fi
