#!/bin/bash

# AI智能客服MCP Server 功能测试脚本
# 作者: AI Assistant
# 版本: 1.0.0

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

# 测试配置
SERVER_URL="http://localhost:3000"
TEST_PHONE="17798762697"
TEST_LATITUDE=39.946613
TEST_LONGITUDE=116.370503

# 检查服务器是否运行
check_server_running() {
    log_test "检查MCP Server是否运行..."
    
    if curl -s -f "$SERVER_URL/health" > /dev/null 2>&1; then
        log_success "MCP Server正在运行"
        return 0
    else
        log_warning "MCP Server未运行，尝试启动..."
        return 1
    fi
}

# 启动MCP Server
start_server() {
    log_info "启动MCP Server..."
    
    # 检查是否已有进程在运行
    if pgrep -f "node.*server.js" > /dev/null; then
        log_warning "检测到MCP Server进程已在运行"
        return 0
    fi
    
    # 启动服务器（后台运行）
    nohup npm start > server.log 2>&1 &
    SERVER_PID=$!
    
    # 等待服务器启动
    log_info "等待服务器启动..."
    for i in {1..30}; do
        if curl -s -f "$SERVER_URL/health" > /dev/null 2>&1; then
            log_success "MCP Server启动成功 (PID: $SERVER_PID)"
            return 0
        fi
        sleep 1
        echo -n "."
    done
    
    log_error "MCP Server启动超时"
    return 1
}

# 测试订单查询功能
test_order_query() {
    log_test "测试订单查询功能..."
    
    local test_data='{
        "jsonrpc": "2.0",
        "id": 1,
        "method": "tools/call",
        "params": {
            "name": "query_order",
            "arguments": {
                "phone": "'$TEST_PHONE'"
            }
        }
    }'
    
    log_info "查询手机号: $TEST_PHONE"
    
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

# 测试网点查询功能
test_store_query() {
    log_test "测试网点查询功能..."
    
    local test_data='{
        "jsonrpc": "2.0",
        "id": 2,
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
    
    log_info "查询坐标: ($TEST_LATITUDE, $TEST_LONGITUDE)"
    
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

# 测试工具列表功能
test_tools_list() {
    log_test "测试工具列表功能..."
    
    local response=$(curl -s -X POST "$SERVER_URL/tools/list" \
        -H "Content-Type: application/json" \
        -d '{"jsonrpc": "2.0", "id": 3, "method": "tools/list"}')
    
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

# 测试错误处理
test_error_handling() {
    log_test "测试错误处理..."
    
    # 测试无效手机号
    local invalid_phone_data='{
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
        -d "$invalid_phone_data")
    
    if echo "$response" | grep -q "错误\|error\|手机号格式不正确"; then
        log_success "错误处理测试通过"
        return 0
    else
        log_warning "错误处理测试未通过预期"
        echo "响应内容: $response"
        return 1
    fi
}

# 性能测试
test_performance() {
    log_test "性能测试..."
    
    local start_time=$(date +%s%N)
    
    # 执行10次订单查询
    for i in {1..10}; do
        curl -s -X POST "$SERVER_URL/tools/call" \
            -H "Content-Type: application/json" \
            -d '{"jsonrpc": "2.0", "id": '$i', "method": "tools/call", "params": {"name": "query_order", "arguments": {"phone": "'$TEST_PHONE'"}}}' > /dev/null
    done
    
    local end_time=$(date +%s%N)
    local duration=$(( (end_time - start_time) / 1000000 )) # 转换为毫秒
    
    log_info "10次查询耗时: ${duration}ms"
    log_info "平均每次查询: $((duration / 10))ms"
    
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
    echo "  测试报告"
    echo "==========================================${NC}"
    echo -e "总测试数: ${BLUE}$total_tests${NC}"
    echo -e "通过测试: ${GREEN}$passed_tests${NC}"
    echo -e "失败测试: ${RED}$failed_tests${NC}"
    echo -e "成功率: ${BLUE}$((passed_tests * 100 / total_tests))%${NC}"
    echo
    
    if [ $failed_tests -eq 0 ]; then
        log_success "🎉 所有测试通过！MCP Server功能正常。"
    else
        log_warning "⚠️  有 $failed_tests 个测试失败，请检查日志。"
    fi
}

# 清理函数
cleanup() {
    log_info "清理测试环境..."
    
    # 停止测试启动的服务器
    if [ ! -z "$SERVER_PID" ]; then
        kill $SERVER_PID 2>/dev/null || true
        log_info "已停止测试服务器"
    fi
    
    # 清理临时文件
    rm -f server.log test.log
}

# 主测试函数
run_tests() {
    local total_tests=0
    local passed_tests=0
    
    echo -e "${BLUE}"
    echo "=========================================="
    echo "  AI智能客服MCP Server 功能测试"
    echo "=========================================="
    echo -e "${NC}"
    
    # 设置清理陷阱
    trap cleanup EXIT
    
    # 检查服务器状态
    if ! check_server_running; then
        if ! start_server; then
            log_error "无法启动MCP Server，测试终止"
            exit 1
        fi
    fi
    
    # 等待服务器完全启动
    sleep 2
    
    # 执行测试
    echo
    log_info "开始执行功能测试..."
    echo
    
    # 测试1: 工具列表
    total_tests=$((total_tests + 1))
    if test_tools_list; then
        passed_tests=$((passed_tests + 1))
    fi
    echo
    
    # 测试2: 订单查询
    total_tests=$((total_tests + 1))
    if test_order_query; then
        passed_tests=$((passed_tests + 1))
    fi
    echo
    
    # 测试3: 网点查询
    total_tests=$((total_tests + 1))
    if test_store_query; then
        passed_tests=$((passed_tests + 1))
    fi
    echo
    
    # 测试4: 错误处理
    total_tests=$((total_tests + 1))
    if test_error_handling; then
        passed_tests=$((passed_tests + 1))
    fi
    echo
    
    # 测试5: 性能测试
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
    echo "AI智能客服MCP Server 测试脚本"
    echo
    echo "用法: $0 [选项]"
    echo
    echo "选项:"
    echo "  -h, --help     显示帮助信息"
    echo "  -s, --server   指定服务器地址 (默认: http://localhost:3000)"
    echo "  -p, --phone    指定测试手机号 (默认: 17798762697)"
    echo "  -l, --lat      指定测试纬度 (默认: 39.946613)"
    echo "  -g, --lng      指定测试经度 (默认: 116.370503)"
    echo
    echo "示例:"
    echo "  $0                                    # 使用默认参数测试"
    echo "  $0 -s http://192.168.1.100:3000      # 测试远程服务器"
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
        -l|--lat)
            TEST_LATITUDE="$2"
            shift 2
            ;;
        -g|--lng)
            TEST_LONGITUDE="$2"
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
