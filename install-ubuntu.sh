#!/bin/bash

# AI智能客服MCP Server - Ubuntu 20.04 自动安装脚本
# 作者: AI Assistant
# 版本: 1.0.0

set -e  # 遇到错误立即退出

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# 检查是否为root用户
check_root() {
    if [[ $EUID -eq 0 ]]; then
        log_error "请不要使用root用户运行此脚本"
        exit 1
    fi
}

# 检查Ubuntu版本
check_ubuntu_version() {
    if ! command -v lsb_release &> /dev/null; then
        log_info "安装lsb-release..."
        sudo apt-get update
        sudo apt-get install -y lsb-release
    fi
    
    UBUNTU_VERSION=$(lsb_release -rs)
    log_info "检测到Ubuntu版本: $UBUNTU_VERSION"
    
    if [[ "$UBUNTU_VERSION" != "20.04" ]]; then
        log_warning "此脚本专为Ubuntu 20.04设计，当前版本: $UBUNTU_VERSION"
        read -p "是否继续安装? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
}

# 更新系统包
update_system() {
    log_info "更新系统包..."
    sudo apt-get update
    sudo apt-get upgrade -y
    log_success "系统包更新完成"
}

# 安装系统依赖
install_system_dependencies() {
    log_info "安装系统依赖..."
    
    # 安装基础工具
    sudo apt-get install -y \
        curl \
        wget \
        git \
        build-essential \
        python3 \
        python3-pip \
        python3-dev \
        libssl-dev \
        libffi-dev \
        software-properties-common \
        apt-transport-https \
        ca-certificates \
        gnupg \
        lsb-release
    
    log_success "系统依赖安装完成"
}

# 安装Node.js
install_nodejs() {
    log_info "安装Node.js 18.x..."
    
    # 检查Node.js是否已安装
    if command -v node &> /dev/null; then
        NODE_VERSION=$(node --version | cut -d'v' -f2 | cut -d'.' -f1)
        if [[ $NODE_VERSION -ge 18 ]]; then
            log_success "Node.js已安装，版本: $(node --version)"
            return 0
        else
            log_warning "Node.js版本过低: $(node --version)，需要18.x或更高版本"
        fi
    fi
    
    # 添加NodeSource仓库
    log_info "添加NodeSource仓库..."
    curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
    
    # 安装Node.js
    log_info "安装Node.js..."
    sudo apt-get install -y nodejs
    
    # 验证安装
    if command -v node &> /dev/null && command -v npm &> /dev/null; then
        log_success "Node.js安装成功 - 版本: $(node --version)"
        log_success "npm安装成功 - 版本: $(npm --version)"
    else
        log_error "Node.js安装失败"
        exit 1
    fi
}

# 配置npm
configure_npm() {
    log_info "配置npm..."
    
    # 创建npm全局目录
    mkdir -p ~/.npm-global
    npm config set prefix '~/.npm-global'
    
    # 添加到PATH
    if ! grep -q "~/.npm-global/bin" ~/.bashrc; then
        echo 'export PATH=~/.npm-global/bin:$PATH' >> ~/.bashrc
        log_info "已将npm全局路径添加到~/.bashrc"
    fi
    
    # 设置npm镜像源（加速下载）
    npm config set registry https://registry.npmmirror.com
    log_info "已设置npm镜像源为: $(npm config get registry)"
    
    # 设置npm超时时间（使用正确的配置选项）
    npm config set fetch-timeout 60000 2>/dev/null || log_warning "无法设置fetch-timeout"
    npm config set fetch-retry-mintimeout 20000 2>/dev/null || log_warning "无法设置fetch-retry-mintimeout"
    npm config set fetch-retry-maxtimeout 120000 2>/dev/null || log_warning "无法设置fetch-retry-maxtimeout"
    
    # 设置其他有用的npm配置
    npm config set save-exact true 2>/dev/null || log_warning "无法设置save-exact"
    npm config set audit false 2>/dev/null || log_warning "无法设置audit"
    
    log_success "npm配置完成"
}

# 安装项目依赖
install_project_dependencies() {
    log_info "安装项目依赖..."
    
    # 检查package.json是否存在
    if [[ ! -f "package.json" ]]; then
        log_error "未找到package.json文件，请确保在项目根目录运行此脚本"
        exit 1
    fi
    
    # 清理可能存在的旧依赖
    if [[ -d "node_modules" ]]; then
        log_info "清理旧的依赖..."
        rm -rf node_modules package-lock.json
    fi
    
    # 安装依赖
    log_info "正在安装依赖，这可能需要几分钟..."
    npm install
    
    if [[ $? -eq 0 ]]; then
        log_success "项目依赖安装完成"
    else
        log_error "项目依赖安装失败"
        exit 1
    fi
}

# 设置文件权限
set_permissions() {
    log_info "设置文件权限..."
    
    # 设置启动脚本权限
    if [[ -f "start.sh" ]]; then
        chmod +x start.sh
        log_success "启动脚本权限设置完成"
    fi
    
    # 设置其他脚本权限
    find . -name "*.sh" -exec chmod +x {} \;
    
    log_success "文件权限设置完成"
}

# 验证安装
verify_installation() {
    log_info "验证安装..."
    
    # 检查Node.js版本
    NODE_VERSION=$(node --version)
    log_info "Node.js版本: $NODE_VERSION"
    
    # 检查npm版本
    NPM_VERSION=$(npm --version)
    log_info "npm版本: $NPM_VERSION"
    
    # 检查项目依赖
    if [[ -d "node_modules" ]]; then
        log_success "项目依赖已安装"
    else
        log_error "项目依赖未正确安装"
        exit 1
    fi
    
    # 测试项目启动（短暂测试）
    log_info "测试项目启动..."
    timeout 5s npm start 2>/dev/null || {
        if [[ $? -eq 124 ]]; then
            log_success "项目启动测试通过（超时正常）"
        else
            log_warning "项目启动测试失败，但依赖已正确安装"
        fi
    }
    
    log_success "安装验证完成"
}

# 显示安装完成信息
show_completion_info() {
    echo
    log_success "🎉 AI智能客服MCP Server安装完成！"
    echo
    echo -e "${BLUE}下一步操作：${NC}"
    echo "1. 重新加载shell配置: source ~/.bashrc"
    echo "2. 启动服务器: ./start.sh 或 npm start"
    echo "3. 查看README.md了解详细使用方法"
    echo
    echo -e "${BLUE}有用的命令：${NC}"
    echo "- 启动服务器: npm start"
    echo "- 开发模式: npm run dev"
    echo "- 查看帮助: cat README.md"
    echo
    echo -e "${BLUE}如果遇到问题：${NC}"
    echo "- 查看故障排除部分: README.md"
    echo "- 检查日志文件"
    echo "- 联系技术支持"
    echo
}

# 主函数
main() {
    echo -e "${BLUE}"
    echo "=========================================="
    echo "  AI智能客服MCP Server 安装脚本"
    echo "  Ubuntu 20.04 自动安装"
    echo "=========================================="
    echo -e "${NC}"
    
    # 检查环境
    check_root
    check_ubuntu_version
    
    # 安装步骤
    update_system
    install_system_dependencies
    install_nodejs
    configure_npm
    install_project_dependencies
    set_permissions
    verify_installation
    
    # 显示完成信息
    show_completion_info
}

# 运行主函数
main "$@"
