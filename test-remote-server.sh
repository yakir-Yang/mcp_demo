#!/bin/bash

# 远程MCP Server测试脚本
# 用于测试部署在CVM上的MCP Server

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
SERVER_IP="106.53.191.184"
SERVER_PORT="3000"
SERVER_URL="http://${SERVER_IP}:${SERVER_PORT}"

# 测试配置
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

# 测试错误处理
test_error_handling() {
    log_test "测试错误处理..."
    
    local test_data='{
        "jsonrpc": "2.0",
        "id": 4,
        "method": "tools/call",
        "params": {
            "name": "query_order",
            "arguments": {
                "phone": "123"
            }
        }
    }'
    
    local response=$(curl -s -X POST "$SERVER_URL/tools/call" \
        -H "Content-Type: application/json" \
        -d "$test_data" \
        --connect-timeout 10)
    
    if echo "$response" | grep -q "错误\|error\|手机号格式不正确"; then
        log_success "错误处理测试通过"
        return 0
    else
        log_warning "错误处理测试未达到预期"
        echo "响应内容: $response"
        return 1
    fi
}

# 性能测试
test_performance() {
    log_test "性能测试..."
    
    local start_time=$(date +%s%N)
    
    # 执行5次请求
    for i in {1..5}; do
        curl -s -X POST "$SERVER_URL/tools/call" \
            -H "Content-Type: application/json" \
            -d '{"jsonrpc": "2.0", "id": '$i', "method": "tools/call", "params": {"name": "query_order", "arguments": {"phone": "'$TEST_PHONE'"}}}' \
            --connect-timeout 10 > /dev/null
    done
    
    local end_time=$(date +%s%N)
    local duration=$(( (end_time - start_time) / 1000000 ))
    
    log_info "5次请求耗时: ${duration}ms"
    log_info "平均每次请求: $((duration / 5))ms"
    
    if [ $duration -lt 5000 ]; then
        log_success "性能测试通过"
        return 0
    else
        log_warning "性能测试警告: 响应时间较慢"
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
    echo "  远程服务器测试报告"
    echo "==========================================${NC}"
    echo -e "服务器地址: ${BLUE}$SERVER_URL${NC}"
    echo -e "总测试数: ${BLUE}$total_tests${NC}"
    echo -e "通过测试: ${GREEN}$passed_tests${NC}"
    echo -e "失败测试: ${RED}$failed_tests${NC}"
    echo -e "成功率: ${BLUE}$((passed_tests * 100 / total_tests))%${NC}"
    echo
    
    if [ $failed_tests -eq 0 ]; then
        log_success "🎉 远程服务器测试全部通过！"
        echo
        echo -e "${BLUE}腾讯云ADP对接信息：${NC}"
        echo "- 服务器地址: $SERVER_URL"
        echo "- 协议: HTTP/SSE"
        echo "- 工具: query_order, query_stores"
        echo "- 状态: 就绪"
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
    echo "  远程MCP Server测试"
    echo "  服务器: $SERVER_URL"
    echo "=========================================="
    echo -e "${NC}"
    
    # 执行测试
    echo
    log_info "开始执行远程测试..."
    echo
    
    # 测试1: 连通性
    total_tests=$((total_tests + 1))
    if test_connectivity; then
        passed_tests=$((passed_tests + 1))
    fi
    echo
    
    # 测试2: 工具列表
    total_tests=$((total_tests + 1))
    if test_tools_list; then
        passed_tests=$((passed_tests + 1))
    fi
    echo
    
    # 测试3: 订单查询
    total_tests=$((total_tests + 1))
    if test_order_query; then
        passed_tests=$((passed_tests + 1))
    fi
    echo
    
    # 测试4: 网点查询
    total_tests=$((total_tests + 1))
    if test_store_query; then
        passed_tests=$((passed_tests + 1))
    fi
    echo
    
    # 测试5: 错误处理
    total_tests=$((total_tests + 1))
    if test_error_handling; then
        passed_tests=$((passed_tests + 1))
    fi
    echo
    
    # 测试6: 性能测试
    total_tests=$((total_tests + 1))
    if test_performance; then
        passed_tests=$((passed_tests + 1))
    fi
    echo
    
    # 生成报告
    generate_report $total_tests $passed_tests
}

# 显示帮助信息
show_help() {
    echo "远程MCP Server测试脚本"
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
