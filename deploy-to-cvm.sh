#!/bin/bash

# CVM部署脚本
# 用于在腾讯云CVM上部署MCP Server

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

# 配置变量
PROJECT_DIR="/opt/mcp-server"
SERVICE_NAME="mcp-server"
USER="ubuntu"

# 检查是否为root用户
check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "请使用root用户运行此脚本"
        exit 1
    fi
}

# 更新系统
update_system() {
    log_info "更新系统包..."
    apt-get update
    apt-get upgrade -y
    log_success "系统更新完成"
}

# 安装Node.js
install_nodejs() {
    log_info "安装Node.js..."
    
    if command -v node &> /dev/null; then
        log_info "Node.js已安装: $(node --version)"
        return 0
    fi
    
    # 安装Node.js 18.x
    curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
    apt-get install -y nodejs
    
    log_success "Node.js安装完成: $(node --version)"
}

# 安装PM2
install_pm2() {
    log_info "安装PM2..."
    
    if command -v pm2 &> /dev/null; then
        log_info "PM2已安装: $(pm2 --version)"
        return 0
    fi
    
    npm install -g pm2
    log_success "PM2安装完成: $(pm2 --version)"
}

# 安装Nginx
install_nginx() {
    log_info "安装Nginx..."
    
    if command -v nginx &> /dev/null; then
        log_info "Nginx已安装"
        return 0
    fi
    
    apt-get install -y nginx
    systemctl enable nginx
    systemctl start nginx
    
    log_success "Nginx安装完成"
}

# 创建项目目录
create_project_dir() {
    log_info "创建项目目录..."
    
    mkdir -p $PROJECT_DIR
    chown $USER:$USER $PROJECT_DIR
    
    log_success "项目目录创建完成: $PROJECT_DIR"
}

# 部署项目文件
deploy_project() {
    log_info "部署项目文件..."
    
    # 复制项目文件到目标目录
    cp -r . $PROJECT_DIR/
    chown -R $USER:$USER $PROJECT_DIR
    
    # 安装依赖
    cd $PROJECT_DIR
    sudo -u $USER npm install
    
    log_success "项目文件部署完成"
}

# 配置Nginx
configure_nginx() {
    log_info "配置Nginx..."
    
    cat > /etc/nginx/sites-available/$SERVICE_NAME << EOF
server {
    listen 80;
    server_name _;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
        proxy_read_timeout 300s;
        proxy_connect_timeout 75s;
    }
}
EOF

    # 启用站点
    ln -sf /etc/nginx/sites-available/$SERVICE_NAME /etc/nginx/sites-enabled/
    rm -f /etc/nginx/sites-enabled/default
    
    # 测试配置
    nginx -t
    
    # 重载Nginx
    systemctl reload nginx
    
    log_success "Nginx配置完成"
}

# 配置防火墙
configure_firewall() {
    log_info "配置防火墙..."
    
    # 安装ufw
    apt-get install -y ufw
    
    # 配置防火墙规则
    ufw --force enable
    ufw allow ssh
    ufw allow 80/tcp
    ufw allow 443/tcp
    
    log_success "防火墙配置完成"
}

# 启动服务
start_service() {
    log_info "启动MCP Server服务..."
    
    cd $PROJECT_DIR
    
    # 使用PM2启动服务
    sudo -u $USER pm2 start src/server.js --name $SERVICE_NAME
    sudo -u $USER pm2 save
    sudo -u $USER pm2 startup systemd -u $USER --hp /home/$USER
    
    # 等待服务启动
    sleep 5
    
    # 检查服务状态
    if sudo -u $USER pm2 list | grep -q $SERVICE_NAME; then
        log_success "MCP Server服务启动成功"
    else
        log_error "MCP Server服务启动失败"
        exit 1
    fi
}

# 测试服务
test_service() {
    log_info "测试服务..."
    
    # 等待服务完全启动
    sleep 10
    
    # 测试本地连接
    if curl -s -f http://localhost:3000/health > /dev/null; then
        log_success "本地服务测试通过"
    else
        log_warning "本地服务测试失败"
    fi
    
    # 测试外部连接
    if curl -s -f http://localhost/health > /dev/null; then
        log_success "外部服务测试通过"
    else
        log_warning "外部服务测试失败"
    fi
}

# 显示部署信息
show_deployment_info() {
    echo
    log_success "🎉 MCP Server部署完成！"
    echo
    echo -e "${BLUE}部署信息：${NC}"
    echo "- 项目目录: $PROJECT_DIR"
    echo "- 服务名称: $SERVICE_NAME"
    echo "- 运行用户: $USER"
    echo "- 服务端口: 3000"
    echo "- 外部访问: http://$(curl -s ifconfig.me)/"
    echo
    echo -e "${BLUE}管理命令：${NC}"
    echo "- 查看服务状态: sudo -u $USER pm2 status"
    echo "- 重启服务: sudo -u $USER pm2 restart $SERVICE_NAME"
    echo "- 查看日志: sudo -u $USER pm2 logs $SERVICE_NAME"
    echo "- 停止服务: sudo -u $USER pm2 stop $SERVICE_NAME"
    echo
    echo -e "${BLUE}测试命令：${NC}"
    echo "- 健康检查: curl http://$(curl -s ifconfig.me)/health"
    echo "- 工具列表: curl -X POST http://$(curl -s ifconfig.me)/tools/list -H 'Content-Type: application/json' -d '{\"jsonrpc\": \"2.0\", \"id\": 1, \"method\": \"tools/list\"}'"
    echo
}

# 主函数
main() {
    echo -e "${BLUE}"
    echo "=========================================="
    echo "  MCP Server CVM部署脚本"
    echo "=========================================="
    echo -e "${NC}"
    
    check_root
    update_system
    install_nodejs
    install_pm2
    install_nginx
    create_project_dir
    deploy_project
    configure_nginx
    configure_firewall
    start_service
    test_service
    show_deployment_info
}

# 运行主函数
main "$@"
