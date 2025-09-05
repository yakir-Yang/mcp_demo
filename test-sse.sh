#!/bin/bash

# SSE连接测试脚本
# 专门用于测试腾讯云ADP的SSE连接

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
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

log_sse() {
    echo -e "${CYAN}[SSE]${NC} $1"
}

# 配置
SERVER_URL="http://106.53.191.184:3000"
TEST_DURATION=30  # 测试持续时间（秒）
LOG_FILE="/tmp/sse_test.log"

# 清理函数
cleanup() {
    if [ -f "$LOG_FILE" ]; then
        rm -f "$LOG_FILE"
    fi
    # 杀死后台进程
    jobs -p | xargs -r kill 2>/dev/null || true
}

# 设置退出时清理
trap cleanup EXIT

# 显示帮助信息
show_help() {
    echo "SSE连接测试脚本"
    echo
    echo "用法: $0 [选项]"
    echo
    echo "选项:"
    echo "  -h, --help         显示帮助信息"
    echo "  -s, --server       指定服务器地址 (默认: $SERVER_URL)"
    echo "  -d, --duration     测试持续时间，秒 (默认: $TEST_DURATION)"
    echo "  -v, --verbose      详细输出模式"
    echo "  -q, --quiet        安静模式，只显示结果"
    echo
    echo "示例:"
    echo "  $0                                    # 使用默认参数测试30秒"
    echo "  $0 -s http://localhost:3000 -d 60    # 测试本地服务器60秒"
    echo "  $0 -v                                # 详细输出模式"
    echo "  $0 -q                                # 安静模式"
}

# 测试SSE端点响应头
test_sse_headers() {
    log_test "测试SSE端点响应头..."
    
    local response=$(curl -s -I "$SERVER_URL/sse" --connect-timeout 10 2>/dev/null)
    
    if [ $? -eq 0 ]; then
        log_success "SSE端点可访问"
        
        # 检查关键响应头
        if echo "$response" | grep -q "Content-Type: text/event-stream"; then
            log_success "Content-Type正确: text/event-stream"
        else
            log_warning "Content-Type可能不正确"
        fi
        
        if echo "$response" | grep -q "Cache-Control: no-cache"; then
            log_success "Cache-Control正确: no-cache"
        else
            log_warning "Cache-Control可能不正确"
        fi
        
        if echo "$response" | grep -q "Connection: keep-alive"; then
            log_success "Connection正确: keep-alive"
        else
            log_warning "Connection可能不正确"
        fi
        
        if echo "$response" | grep -q "Access-Control-Allow-Origin"; then
            log_success "CORS配置正确"
        else
            log_warning "CORS配置可能有问题"
        fi
        
        return 0
    else
        log_error "SSE端点不可访问"
        return 1
    fi
}

# 测试SSE数据流
test_sse_stream() {
    log_test "测试SSE数据流 (${TEST_DURATION}秒)..."
    
    # 清空日志文件
    > "$LOG_FILE"
    
    # 启动SSE连接（后台运行）
    curl -s -N "$SERVER_URL/sse" > "$LOG_FILE" 2>&1 &
    local curl_pid=$!
    
    # 等待连接建立
    sleep 3
    
    # 检查连接是否建立
    if ! kill -0 $curl_pid 2>/dev/null; then
        log_error "SSE连接失败"
        return 1
    fi
    
    log_success "SSE连接已建立 (PID: $curl_pid)"
    
    # 监控数据流
    local start_time=$(date +%s)
    local end_time=$((start_time + TEST_DURATION))
    local message_count=0
    local last_message_time=0
    
    while [ $(date +%s) -lt $end_time ]; do
        if [ -f "$LOG_FILE" ] && [ -s "$LOG_FILE" ]; then
            # 计算新消息数量
            local current_count=$(wc -l < "$LOG_FILE" 2>/dev/null || echo 0)
            local new_messages=$((current_count - message_count))
            
            if [ $new_messages -gt 0 ]; then
                local current_time=$(date +%s)
                local time_diff=$((current_time - last_message_time))
                
                if [ $VERBOSE -eq 1 ]; then
                    log_sse "收到 $new_messages 条新消息 (间隔: ${time_diff}秒)"
                fi
                
                message_count=$current_count
                last_message_time=$current_time
            fi
        fi
        
        sleep 1
    done
    
    # 停止SSE连接
    kill $curl_pid 2>/dev/null || true
    wait $curl_pid 2>/dev/null || true
    
    log_success "SSE测试完成，共收到 $message_count 条消息"
    
    # 分析消息内容
    if [ -f "$LOG_FILE" ] && [ -s "$LOG_FILE" ]; then
        analyze_sse_messages
    fi
    
    return 0
}

# 分析SSE消息内容
analyze_sse_messages() {
    log_test "分析SSE消息内容..."
    
    if [ ! -f "$LOG_FILE" ] || [ ! -s "$LOG_FILE" ]; then
        log_warning "没有SSE消息数据"
        return 1
    fi
    
    # 统计消息类型
    local connection_messages=$(grep -c "event: connected" "$LOG_FILE" 2>/dev/null || echo 0)
    local mcp_info_messages=$(grep -c "event: mcp-info" "$LOG_FILE" 2>/dev/null || echo 0)
    local heartbeat_messages=$(grep -c "event: heartbeat" "$LOG_FILE" 2>/dev/null || echo 0)
    local tools_messages=$(grep -c "event: tools-available" "$LOG_FILE" 2>/dev/null || echo 0)
    
    log_info "消息统计:"
    echo "  连接消息: $connection_messages"
    echo "  MCP信息: $mcp_info_messages"
    echo "  心跳消息: $heartbeat_messages"
    echo "  工具信息: $tools_messages"
    
    # 显示最后几条消息
    if [ $VERBOSE -eq 1 ]; then
        log_info "最后5条消息:"
        tail -5 "$LOG_FILE" | sed 's/^/  /'
    fi
    
    # 检查消息格式
    local valid_messages=$(grep -c "^data:" "$LOG_FILE" 2>/dev/null || echo 0)
    local total_lines=$(wc -l < "$LOG_FILE" 2>/dev/null || echo 0)
    
    if [ $total_lines -gt 0 ]; then
        local valid_ratio=$((valid_messages * 100 / total_lines))
        log_info "有效消息比例: $valid_ratio% ($valid_messages/$total_lines)"
        
        if [ $valid_ratio -gt 50 ]; then
            log_success "SSE消息格式正确"
        else
            log_warning "SSE消息格式可能有问题"
        fi
    fi
}

# 测试SSE连接稳定性
test_sse_stability() {
    log_test "测试SSE连接稳定性..."
    
    local test_count=5
    local success_count=0
    
    for i in $(seq 1 $test_count); do
        log_info "稳定性测试 $i/$test_count..."
        
        # 测试5秒连接
        local result=$(timeout 5s curl -s -N "$SERVER_URL/sse" 2>/dev/null | wc -l)
        
        if [ $result -gt 0 ]; then
            log_success "测试 $i 成功，收到 $result 行数据"
            success_count=$((success_count + 1))
        else
            log_warning "测试 $i 失败，没有收到数据"
        fi
        
        sleep 1
    done
    
    local success_rate=$((success_count * 100 / test_count))
    log_info "稳定性测试结果: $success_count/$test_count 成功 ($success_rate%)"
    
    if [ $success_rate -ge 80 ]; then
        log_success "SSE连接稳定性良好"
        return 0
    else
        log_warning "SSE连接稳定性需要改进"
        return 1
    fi
}

# 测试腾讯云ADP兼容性
test_tencent_adp_compatibility() {
    log_test "测试腾讯云ADP兼容性..."
    
    # 模拟腾讯云ADP的请求头
    local response=$(curl -s -I "$SERVER_URL/sse" \
        -H "User-Agent: TencentADP/1.0" \
        -H "Accept: text/event-stream" \
        -H "Cache-Control: no-cache" \
        --connect-timeout 10 2>/dev/null)
    
    if [ $? -eq 0 ]; then
        log_success "腾讯云ADP请求头兼容性测试通过"
        
        # 检查关键头部
        if echo "$response" | grep -q "Access-Control-Allow-Origin"; then
            log_success "CORS支持正确"
        else
            log_warning "CORS支持可能有问题"
        fi
        
        if echo "$response" | grep -q "Access-Control-Allow-Headers"; then
            log_success "CORS头部支持正确"
        else
            log_warning "CORS头部支持可能有问题"
        fi
        
        return 0
    else
        log_error "腾讯云ADP兼容性测试失败"
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
    echo "  SSE连接测试报告"
    echo "==========================================${NC}"
    echo -e "服务器地址: ${BLUE}$SERVER_URL${NC}"
    echo -e "测试持续时间: ${BLUE}${TEST_DURATION}秒${NC}"
    echo -e "总测试数: ${BLUE}$total_tests${NC}"
    echo -e "通过测试: ${GREEN}$passed_tests${NC}"
    echo -e "失败测试: ${RED}$failed_tests${NC}"
    echo -e "成功率: ${BLUE}$((passed_tests * 100 / total_tests))%${NC}"
    echo
    
    if [ $failed_tests -eq 0 ]; then
        log_success "🎉 所有SSE测试通过！服务器与腾讯云ADP兼容。"
        echo
        echo -e "${BLUE}腾讯云ADP配置建议:${NC}"
        echo "- 服务器URL: $SERVER_URL"
        echo "- 超时时间: 120秒"
        echo "- SSE读取超时: 600秒"
        echo "- 支持的事件: connected, mcp-info, heartbeat, tools-available"
    else
        log_warning "⚠️  有 $failed_tests 个测试失败，请检查服务器配置。"
        echo
        echo -e "${BLUE}故障排除建议:${NC}"
        echo "1. 检查服务器是否正常运行"
        echo "2. 检查SSE端点实现"
        echo "3. 检查CORS配置"
        echo "4. 查看服务器日志"
        echo "5. 检查网络连接"
    fi
}

# 主测试函数
run_tests() {
    local total_tests=0
    local passed_tests=0
    
    echo -e "${BLUE}"
    echo "=========================================="
    echo "  SSE连接测试"
    echo "  服务器: $SERVER_URL"
    echo "  持续时间: ${TEST_DURATION}秒"
    echo "=========================================="
    echo -e "${NC}"
    
    # 执行测试
    echo
    log_info "开始执行SSE测试..."
    echo
    
    # 测试1: SSE响应头
    total_tests=$((total_tests + 1))
    if test_sse_headers; then
        passed_tests=$((passed_tests + 1))
    fi
    echo
    
    # 测试2: SSE数据流
    total_tests=$((total_tests + 1))
    if test_sse_stream; then
        passed_tests=$((passed_tests + 1))
    fi
    echo
    
    # 测试3: 连接稳定性
    total_tests=$((total_tests + 1))
    if test_sse_stability; then
        passed_tests=$((passed_tests + 1))
    fi
    echo
    
    # 测试4: 腾讯云ADP兼容性
    total_tests=$((total_tests + 1))
    if test_tencent_adp_compatibility; then
        passed_tests=$((passed_tests + 1))
    fi
    echo
    
    # 生成报告
    generate_report $total_tests $passed_tests
}

# 解析命令行参数
VERBOSE=0
QUIET=0

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
        -d|--duration)
            TEST_DURATION="$2"
            shift 2
            ;;
        -v|--verbose)
            VERBOSE=1
            shift
            ;;
        -q|--quiet)
            QUIET=1
            shift
            ;;
        *)
            log_error "未知参数: $1"
            show_help
            exit 1
            ;;
    esac
done

# 运行测试
if [ $QUIET -eq 1 ]; then
    run_tests > /dev/null 2>&1
    echo "SSE测试完成"
else
    run_tests
fi
