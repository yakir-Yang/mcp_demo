#!/bin/bash

# 腾讯云ADP修复部署脚本
# 用于快速部署修复后的MCP Server到CVM

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

log_step() {
    echo -e "${PURPLE}[STEP]${NC} $1"
}

# 配置
CVM_HOST="106.53.191.184"
CVM_USER="ubuntu"
CVM_PATH="~/mcp_demo"
LOCAL_PROJECT_PATH="/Users/kk/Desktop/mcp_test"

# 检查本地文件
check_local_files() {
    log_step "检查本地文件..."
    
    if [ ! -f "$LOCAL_PROJECT_PATH/src/http-server.js" ]; then
        log_error "本地文件不存在: src/http-server.js"
        exit 1
    fi
    
    if [ ! -f "$LOCAL_PROJECT_PATH/test-adp-connection.sh" ]; then
        log_error "本地文件不存在: test-adp-connection.sh"
        exit 1
    fi
    
    log_success "本地文件检查完成"
}

# 上传文件到CVM
upload_files() {
    log_step "上传文件到CVM..."
    
    # 上传修复后的HTTP服务器
    log_info "上传 http-server.js..."
    scp "$LOCAL_PROJECT_PATH/src/http-server.js" "$CVM_USER@$CVM_HOST:$CVM_PATH/src/"
    
    # 上传测试脚本
    log_info "上传 test-adp-connection.sh..."
    scp "$LOCAL_PROJECT_PATH/test-adp-connection.sh" "$CVM_USER@$CVM_HOST:$CVM_PATH/"
    
    # 上传配置文档
    log_info "上传 TENCENT_ADP_CONFIG.md..."
    scp "$LOCAL_PROJECT_PATH/TENCENT_ADP_CONFIG.md" "$CVM_USER@$CVM_HOST:$CVM_PATH/"
    
    log_success "文件上传完成"
}

# 在CVM上部署服务
deploy_on_cvm() {
    log_step "在CVM上部署服务..."
    
    ssh "$CVM_USER@$CVM_HOST" << 'EOF'
        cd ~/mcp_demo
        
        # 停止当前服务
        log_info "停止当前服务..."
        pm2 stop mcp-http-server || true
        
        # 启动修复后的服务
        log_info "启动修复后的服务..."
        pm2 start src/http-server.js --name mcp-http-server
        
        # 保存PM2配置
        pm2 save
        
        # 查看服务状态
        log_info "查看服务状态..."
        pm2 status
        
        # 给测试脚本执行权限
        chmod +x test-adp-connection.sh
        
        log_success "服务部署完成"
EOF
}

# 测试部署结果
test_deployment() {
    log_step "测试部署结果..."
    
    ssh "$CVM_USER@$CVM_HOST" << 'EOF'
        cd ~/mcp_demo
        
        # 等待服务启动
        sleep 5
        
        # 测试健康检查
        log_info "测试健康检查..."
        curl -s http://localhost:3000/health | head -1
        
        # 测试SSE端点
        log_info "测试SSE端点..."
        curl -I http://localhost:3000/sse | head -3
        
        # 运行完整测试
        log_info "运行完整测试..."
        ./test-adp-connection.sh
EOF
}

# 显示部署结果
show_results() {
    echo
    echo -e "${BLUE}=========================================="
    echo "  腾讯云ADP修复部署完成"
    echo "==========================================${NC}"
    echo
    echo -e "${GREEN}✅ 部署状态: 成功${NC}"
    echo -e "${BLUE}服务器地址: http://$CVM_HOST:3000${NC}"
    echo -e "${BLUE}SSE端点: http://$CVM_HOST:3000/sse${NC}"
    echo -e "${BLUE}健康检查: http://$CVM_HOST:3000/health${NC}"
    echo
    echo -e "${PURPLE}腾讯云ADP配置JSON:${NC}"
    cat << 'EOF'
[
  {
    "AI智能客服MCP Server": {
      "url": "http://106.53.191.184:3000",
      "desc": "AI智能客服系统MCP Server - 提供订单查询和网点查询功能，支持SSE协议",
      "headers": [
        {
          "key": "Content-Type",
          "value": "application/json",
          "appDefined": true
        },
        {
          "key": "Accept",
          "value": "application/json",
          "appDefined": true
        },
        {
          "key": "User-Agent",
          "value": "TencentADP/1.0",
          "appDefined": true
        }
      ],
      "timeout": "60",
      "sse_read_timeout": "300"
    }
  }
]
EOF
    echo
    echo -e "${YELLOW}下一步操作:${NC}"
    echo "1. 复制上面的JSON配置到腾讯云ADP平台"
    echo "2. 在ADP平台中添加MCP Server"
    echo "3. 测试连接是否成功"
    echo
    echo -e "${BLUE}监控命令:${NC}"
    echo "ssh $CVM_USER@$CVM_HOST 'cd ~/mcp_demo && pm2 logs mcp-http-server'"
    echo
}

# 主函数
main() {
    echo -e "${BLUE}"
    echo "=========================================="
    echo "  腾讯云ADP修复部署脚本"
    echo "  CVM: $CVM_HOST"
    echo "=========================================="
    echo -e "${NC}"
    
    check_local_files
    upload_files
    deploy_on_cvm
    test_deployment
    show_results
    
    log_success "🎉 部署完成！"
}

# 显示帮助信息
show_help() {
    echo "腾讯云ADP修复部署脚本"
    echo
    echo "用法: $0 [选项]"
    echo
    echo "选项:"
    echo "  -h, --help     显示帮助信息"
    echo "  -c, --cvm      指定CVM地址 (默认: $CVM_HOST)"
    echo "  -u, --user     指定CVM用户名 (默认: $CVM_USER)"
    echo
    echo "示例:"
    echo "  $0                                    # 使用默认参数部署"
    echo "  $0 -c 192.168.1.100 -u root          # 指定CVM地址和用户名"
}

# 解析命令行参数
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -c|--cvm)
            CVM_HOST="$2"
            shift 2
            ;;
        -u|--user)
            CVM_USER="$2"
            shift 2
            ;;
        *)
            log_error "未知参数: $1"
            show_help
            exit 1
            ;;
    esac
done

# 运行主函数
main
