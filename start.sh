#!/bin/bash

# AI智能客服MCP Server启动脚本

echo "正在启动AI智能客服MCP Server..."

# 检查Node.js版本
node_version=$(node --version 2>/dev/null)
if [ $? -ne 0 ]; then
    echo "错误: 未找到Node.js，请先安装Node.js 18.0.0或更高版本"
    exit 1
fi

echo "Node.js版本: $node_version"

# 检查依赖是否已安装
if [ ! -d "node_modules" ]; then
    echo "正在安装依赖..."
    npm install
    if [ $? -ne 0 ]; then
        echo "错误: 依赖安装失败"
        exit 1
    fi
fi

# 启动服务器
echo "启动MCP Server..."
npm start
