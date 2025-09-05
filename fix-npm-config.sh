#!/bin/bash

# npm配置修复脚本
# 用于修复npm配置中的错误选项

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

# 修复npm配置
fix_npm_config() {
    log_info "修复npm配置..."
    
    # 删除可能存在的错误配置
    npm config delete timeout 2>/dev/null || true
    
    # 设置正确的超时配置
    log_info "设置正确的npm超时配置..."
    npm config set fetch-timeout 60000 2>/dev/null || log_warning "无法设置fetch-timeout"
    npm config set fetch-retry-mintimeout 20000 2>/dev/null || log_warning "无法设置fetch-retry-mintimeout"
    npm config set fetch-retry-maxtimeout 120000 2>/dev/null || log_warning "无法设置fetch-retry-maxtimeout"
    
    # 设置其他有用的配置
    log_info "设置其他npm配置..."
    npm config set save-exact true 2>/dev/null || log_warning "无法设置save-exact"
    npm config set audit false 2>/dev/null || log_warning "无法设置audit"
    
    # 验证配置
    log_info "验证npm配置..."
    echo "当前npm配置:"
    npm config list
    
    log_success "npm配置修复完成"
}

# 测试npm功能
test_npm() {
    log_info "测试npm功能..."
    
    # 测试npm命令
    if npm --version > /dev/null 2>&1; then
        log_success "npm命令正常"
    else
        log_error "npm命令异常"
        exit 1
    fi
    
    # 测试npm配置
    if npm config get registry > /dev/null 2>&1; then
        log_success "npm配置正常"
    else
        log_error "npm配置异常"
        exit 1
    fi
    
    log_success "npm功能测试通过"
}

# 主函数
main() {
    echo -e "${BLUE}"
    echo "=========================================="
    echo "  npm配置修复脚本"
    echo "  修复npm配置中的错误选项"
    echo "=========================================="
    echo -e "${NC}"
    
    fix_npm_config
    test_npm
    
    echo
    log_success "🎉 npm配置修复完成！"
    echo
    echo -e "${BLUE}下一步操作：${NC}"
    echo "1. 重新运行安装脚本: ./install-ubuntu.sh"
    echo "2. 或直接安装项目依赖: npm install"
    echo
}

# 运行主函数
main "$@"
