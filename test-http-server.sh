#!/bin/bash

# HTTP MCP Server 测试脚本
# 用于测试HTTP版本的MCP Server

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
SERVER_URL="http://localhost:3000"
TEST_PHONE="17798762697"
TEST_LATITUDE=39.946613
TEST_LONGITUDE=116.370503

# 测试健康检查
test_health() {
    log_test "测试健康检查..."
    
    local response=$(curl -s "$SERVER_URL/health")
    
    if echo "$response" | grep -q "healthy"; then
        log_success "健康检查测试通过"
        echo "响应内容:"
        echo "$response" | jq '.' 2>/dev/null || echo "$response"
        return 0
    else
        log_error "健康检查测试失败"
        echo "响应内容: $response"
        return 1
    fi
}

# 测试根路径
test_root() {
    log_test "测试根路径..."
    
    local response=$(curl -s "$SERVER_URL/")
    
    if echo "$response" | grep -q "AI智能客服MCP Server"; then
        log_success "根路径测试通过"
        echo "响应内容:"
        echo "$response" | jq '.' 2>/dev/null || echo "$response"
        return 0
    else
        log_error "根路径测试失败"
        echo "响应内容: $response"
        return 1
    fi
}

# 测试工具列表
test_tools_list() {
    log_test "测试工具列表..."
    
    local response=$(curl -s -X POST "$SERVER_URL/tools/list" \
        -H "Content-Type: application/json" \
        -d '{"jsonrpc": "2.0", "id": 1, "method": "tools/list"}')
    
    if echo "$response" | grep -q "query_order\|query_stores"; then
        log_success "工具列表测试通过"
        echo "响应内容:"
        echo "$response" | jq '.' 2>/dev/null || echo "$response"
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
        -d "$test_data")
    
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
        -d "$test_data")
    
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

# 测试兼容性端点
test_compatibility_endpoints() {
    log_test "测试兼容性端点..."
    
    # 测试直接订单查询端点
    local order_response=$(curl -s -X POST "$SERVER_URL/query_order" \
        -H "Content-Type: application/json" \
        -d '{"phone": "'$TEST_PHONE'"}')
    
    if echo "$order_response" | grep -q "手机号.*$TEST_PHONE"; then
        log_success "直接订单查询端点测试通过"
    else
        log_error "直接订单查询端点测试失败"
        echo "响应内容: $order_response"
        return 1
    fi
    
    # 测试直接网点查询端点
    local store_response=$(curl -s -X POST "$SERVER_URL/query_stores" \
        -H "Content-Type: application/json" \
        -d '{"latitude": '$TEST_LATITUDE', "longitude": '$TEST_LONGITUDE', "limit": 3}')
    
    if echo "$store_response" | grep -q "网点名称"; then
        log_success "直接网点查询端点测试通过"
        return 0
    else
        log_error "直接网点查询端点测试失败"
        echo "响应内容: $store_response"
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
    echo "  HTTP MCP Server 测试报告"
    echo "==========================================${NC}"
    echo -e "服务器地址: ${BLUE}$SERVER_URL${NC}"
    echo -e "总测试数: ${BLUE}$total_tests${NC}"
    echo -e "通过测试: ${GREEN}$passed_tests${NC}"
    echo -e "失败测试: ${RED}$failed_tests${NC}"
    echo -e "成功率: ${BLUE}$((passed_tests * 100 / total_tests))%${NC}"
    echo
    
    if [ $failed_tests -eq 0 ]; then
        log_success "🎉 所有测试通过！HTTP MCP Server功能正常。"
        echo
        echo -e "${BLUE}可用的端点：${NC}"
        echo "- 健康检查: $SERVER_URL/health"
        echo "- 工具列表: $SERVER_URL/tools/list"
        echo "- 工具调用: $SERVER_URL/tools/call"
        echo "- 订单查询: $SERVER_URL/query_order"
        echo "- 网点查询: $SERVER_URL/query_stores"
    else
        log_warning "⚠️  有 $failed_tests 个测试失败，请检查服务器状态。"
    fi
}

# 主测试函数
run_tests() {
    local total_tests=0
    local passed_tests=0
    
    echo -e "${BLUE}"
    echo "=========================================="
    echo "  HTTP MCP Server 功能测试"
    echo "  服务器: $SERVER_URL"
    echo "=========================================="
    echo -e "${NC}"
    
    # 执行测试
    echo
    log_info "开始执行HTTP测试..."
    echo
    
    # 测试1: 健康检查
    total_tests=$((total_tests + 1))
    if test_health; then
        passed_tests=$((passed_tests + 1))
    fi
    echo
    
    # 测试2: 根路径
    total_tests=$((total_tests + 1))
    if test_root; then
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
    
    # 测试6: 兼容性端点
    total_tests=$((total_tests + 1))
    if test_compatibility_endpoints; then
        passed_tests=$((passed_tests + 1))
    fi
    echo
    
    # 生成报告
    generate_report $total_tests $passed_tests
}

# 显示帮助信息
show_help() {
    echo "HTTP MCP Server测试脚本"
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
