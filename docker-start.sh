#!/bin/bash

# AI智能客服MCP Server - Docker快速启动脚本
# 作者: AI Assistant
# 版本: 1.0.0

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

# 检查Docker是否安装
check_docker() {
    if ! command -v docker &> /dev/null; then
        log_error "Docker未安装，请先安装Docker"
        echo "安装命令: curl -fsSL https://get.docker.com -o get-docker.sh && sh get-docker.sh"
        exit 1
    fi
    
    if ! command -v docker-compose &> /dev/null; then
        log_error "Docker Compose未安装，请先安装Docker Compose"
        echo "安装命令: sudo curl -L \"https://github.com/docker/compose/releases/download/v2.20.0/docker-compose-\$(uname -s)-\$(uname -m)\" -o /usr/local/bin/docker-compose && sudo chmod +x /usr/local/bin/docker-compose"
        exit 1
    fi
    
    log_success "Docker环境检查通过"
}

# 创建必要的目录
create_directories() {
    log_info "创建必要的目录..."
    
    mkdir -p logs
    mkdir -p data
    
    log_success "目录创建完成"
}

# 构建Docker镜像
build_image() {
    log_info "构建Docker镜像..."
    
    docker build -t ai-customer-service-mcp .
    
    if [[ $? -eq 0 ]]; then
        log_success "Docker镜像构建完成"
    else
        log_error "Docker镜像构建失败"
        exit 1
    fi
}

# 启动服务
start_service() {
    log_info "启动MCP Server服务..."
    
    # 停止可能存在的旧容器
    docker-compose down 2>/dev/null || true
    
    # 启动服务
    docker-compose up -d
    
    if [[ $? -eq 0 ]]; then
        log_success "MCP Server服务启动成功"
    else
        log_error "MCP Server服务启动失败"
        exit 1
    fi
}

# 检查服务状态
check_service() {
    log_info "检查服务状态..."
    
    sleep 5
    
    if docker-compose ps | grep -q "Up"; then
        log_success "服务运行正常"
        
        # 显示容器信息
        echo
        log_info "容器信息:"
        docker-compose ps
        
        # 显示日志
        echo
        log_info "最近日志:"
        docker-compose logs --tail=10
        
    else
        log_error "服务启动失败"
        docker-compose logs
        exit 1
    fi
}

# 显示使用说明
show_usage() {
    echo
    log_success "🎉 MCP Server Docker部署完成！"
    echo
    echo -e "${BLUE}有用的命令：${NC}"
    echo "- 查看服务状态: docker-compose ps"
    echo "- 查看日志: docker-compose logs -f"
    echo "- 停止服务: docker-compose down"
    echo "- 重启服务: docker-compose restart"
    echo "- 进入容器: docker-compose exec mcp-server sh"
    echo
    echo -e "${BLUE}服务访问：${NC}"
    echo "- 服务地址: http://localhost:3000"
    echo "- 健康检查: http://localhost:3000/health"
    echo
    echo -e "${BLUE}数据管理：${NC}"
    echo "- 数据目录: ./data/"
    echo "- 日志目录: ./logs/"
    echo
}

# 主函数
main() {
    echo -e "${BLUE}"
    echo "=========================================="
    echo "  AI智能客服MCP Server Docker部署"
    echo "  快速启动脚本"
    echo "=========================================="
    echo -e "${NC}"
    
    check_docker
    create_directories
    build_image
    start_service
    check_service
    show_usage
}

# 运行主函数
main "$@"
