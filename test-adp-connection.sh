#!/bin/bash

# 腾讯云ADP连接测试脚本
# 用于测试MCP Server与腾讯云ADP平台的连接

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_test() {
    echo -e "${PURPLE}[TEST]${NC} $1"
}

# 配置
SERVER_URL="http://106.53.191.184:3000"
TEST_PHONE="17798762697"
TEST_LATITUDE=39.946613
TEST_LONGITUDE=116.370503

# 测试服务器连通性
test_connectivity() {
    log_test "测试服务器连通性..."
    
    if curl -s -f --connect-timeout 10 "$SERVER_URL/health" > /dev/null 2>&1; then
        log_success "服务器连通性正常"
        return 0
    else
        log_error "无法连接到服务器 $SERVER_URL"
        return 1
    fi
}

# 测试MCP初始化
test_mcp_initialize() {
    log_test "测试MCP初始化..."
    
    local response=$(curl -s -X POST "$SERVER_URL/mcp/initialize" \
        -H "Content-Type: application/json" \
        -d '{"jsonrpc": "2.0", "id": 1, "method": "initialize", "params": {"protocolVersion": "2024-11-05", "capabilities": {}, "clientInfo": {"name": "tencent-adp", "version": "1.0.0"}}}' \
        --connect-timeout 10)
    
    if echo "$response" | grep -q "protocolVersion"; then
        log_success "MCP初始化测试通过"
        echo "响应内容:"
        echo "$response" | jq '.' 2>/dev/null || echo "$response"
        return 0
    else
        log_error "MCP初始化测试失败"
        echo "响应内容: $response"
        return 1
    fi
}

# 测试工具列表
test_tools_list() {
    log_test "测试工具列表..."
    
    local response=$(curl -s -X POST "$SERVER_URL/tools/list" \
        -H "Content-Type: application/json" \
        -d '{"jsonrpc": "2.0", "id": 1, "method": "tools/list"}' \
        --connect-timeout 10)
    
    if echo "$response" | grep -q "query_order\|query_stores"; then
        log_success "工具列表测试通过"
        echo "可用工具:"
        echo "$response" | jq '.result.tools[].name' 2>/dev/null || echo "$response"
        return 0
    else
        log_error "工具列表测试失败"
        echo "响应内容: $response"
        return 1
    fi
}

# 测试订单查询
test_order_query() {
    log_test "测试订单查询..."
    
    local test_data='{
        "jsonrpc": "2.0",
        "id": 2,
        "method": "tools/call",
        "params": {
            "name": "query_order",
            "arguments": {
                "phone": "'$TEST_PHONE'"
            }
        }
    }'
    
    local response=$(curl -s -X POST "$SERVER_URL/tools/call" \
        -H "Content-Type: application/json" \
        -d "$test_data" \
        --connect-timeout 10)
    
    if echo "$response" | grep -q "手机号.*$TEST_PHONE"; then
        log_success "订单查询测试通过"
        echo "响应内容:"
        echo "$response" | jq '.' 2>/dev/null || echo "$response"
        return 0
    else
        log_error "订单查询测试失败"
        echo "响应内容: $response"
        return 1
    fi
}

# 测试网点查询
test_store_query() {
    log_test "测试网点查询..."
    
    local test_data='{
        "jsonrpc": "2.0",
        "id": 3,
        "method": "tools/call",
        "params": {
            "name": "query_stores",
            "arguments": {
                "latitude": '$TEST_LATITUDE',
                "longitude": '$TEST_LONGITUDE',
                "limit": 3
            }
        }
    }'
    
    local response=$(curl -s -X POST "$SERVER_URL/tools/call" \
        -H "Content-Type: application/json" \
        -d "$test_data" \
        --connect-timeout 10)
    
    if echo "$response" | grep -q "网点名称"; then
        log_success "网点查询测试通过"
        echo "响应内容:"
        echo "$response" | jq '.' 2>/dev/null || echo "$response"
        return 0
    else
        log_error "网点查询测试失败"
        echo "响应内容: $response"
        return 1
    fi
}

# 测试CORS
test_cors() {
    log_test "测试CORS配置..."
    
    local response=$(curl -s -I -X OPTIONS "$SERVER_URL/tools/list" \
        -H "Origin: https://adp.tencent.com" \
        -H "Access-Control-Request-Method: POST" \
        -H "Access-Control-Request-Headers: Content-Type" \
        --connect-timeout 10)
    
    if echo "$response" | grep -q "Access-Control-Allow-Origin"; then
        log_success "CORS配置正常"
        return 0
    else
        log_warning "CORS配置可能有问题"
        echo "响应头: $response"
        return 1
    fi
}

# 生成测试报告
generate_report() {
    local total_tests=$1
    local passed_tests=$2
    local failed_tests=$((total_tests - passed_tests))
    
    echo
    echo -e "${BLUE}=========================================="
    echo "  腾讯云ADP连接测试报告"
    echo "==========================================${NC}"
    echo -e "服务器地址: ${BLUE}$SERVER_URL${NC}"
    echo -e "总测试数: ${BLUE}$total_tests${NC}"
    echo -e "通过测试: ${GREEN}$passed_tests${NC}"
    echo -e "失败测试: ${RED}$failed_tests${NC}"
    echo -e "成功率: ${BLUE}$((passed_tests * 100 / total_tests))%${NC}"
    echo
    
    if [ $failed_tests -eq 0 ]; then
        log_success "🎉 所有测试通过！MCP Server与腾讯云ADP连接正常。"
        echo
        echo -e "${BLUE}腾讯云ADP配置信息：${NC}"
        echo "- 服务器地址: $SERVER_URL"
        echo "- 协议: MCP (Model Context Protocol)"
        echo "- 初始化端点: $SERVER_URL/mcp/initialize"
        echo "- 工具列表端点: $SERVER_URL/tools/list"
        echo "- 工具调用端点: $SERVER_URL/tools/call"
        echo "- 可用工具: query_order, query_stores"
        echo
        echo -e "${BLUE}ADP平台配置建议：${NC}"
        echo "1. 服务器URL: $SERVER_URL"
        echo "2. 协议类型: MCP"
        echo "3. 初始化方法: POST /mcp/initialize"
        echo "4. 工具列表方法: POST /tools/list"
        echo "5. 工具调用方法: POST /tools/call"
    else
        log_warning "⚠️  有 $failed_tests 个测试失败，请检查服务器配置。"
        echo
        echo -e "${BLUE}故障排除建议：${NC}"
        echo "1. 检查服务器是否正常运行"
        echo "2. 检查防火墙设置"
        echo "3. 检查CORS配置"
        echo "4. 检查MCP协议实现"
        echo "5. 查看服务器日志"
    fi
}

# 主测试函数
run_tests() {
    local total_tests=0
    local passed_tests=0
    
    echo -e "${BLUE}"
    echo "=========================================="
    echo "  腾讯云ADP MCP Server连接测试"
    echo "  服务器: $SERVER_URL"
    echo "=========================================="
    echo -e "${NC}"
    
    # 执行测试
    echo
    log_info "开始执行ADP连接测试..."
    echo
    
    # 测试1: 连通性
    total_tests=$((total_tests + 1))
    if test_connectivity; then
        passed_tests=$((passed_tests + 1))
    fi
    echo
    
    # 测试2: MCP初始化
    total_tests=$((total_tests + 1))
    if test_mcp_initialize; then
        passed_tests=$((passed_tests + 1))
    fi
    echo
    
    # 测试3: 工具列表
    total_tests=$((total_tests + 1))
    if test_tools_list; then
        passed_tests=$((passed_tests + 1))
    fi
    echo
    
    # 测试4: 订单查询
    total_tests=$((total_tests + 1))
    if test_order_query; then
        passed_tests=$((passed_tests + 1))
    fi
    echo
    
    # 测试5: 网点查询
    total_tests=$((total_tests + 1))
    if test_store_query; then
        passed_tests=$((passed_tests + 1))
    fi
    echo
    
    # 测试6: CORS
    total_tests=$((total_tests + 1))
    if test_cors; then
        passed_tests=$((passed_tests + 1))
    fi
    echo
    
    # 生成报告
    generate_report $total_tests $passed_tests
}

# 显示帮助信息
show_help() {
    echo "腾讯云ADP连接测试脚本"
    echo
    echo "用法: $0 [选项]"
    echo
    echo "选项:"
    echo "  -h, --help     显示帮助信息"
    echo "  -s, --server   指定服务器地址 (默认: $SERVER_URL)"
    echo "  -p, --phone    指定测试手机号 (默认: $TEST_PHONE)"
    echo
    echo "示例:"
    echo "  $0                                    # 使用默认参数测试"
    echo "  $0 -s http://192.168.1.100:3000      # 测试其他服务器"
    echo "  $0 -p 13800138000                    # 使用指定手机号测试"
}

# 解析命令行参数
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -s|--server)
            SERVER_URL="$2"
            shift 2
            ;;
        -p|--phone)
            TEST_PHONE="$2"
            shift 2
            ;;
        *)
            log_error "未知参数: $1"
            show_help
            exit 1
            ;;
    esac
done

# 运行测试
run_tests
