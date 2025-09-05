# AI智能客服MCP Server - 安装总结

## 项目概述

本项目是一个完整的AI智能客服MCP Server，支持订单查询和网点查询功能，提供多种部署方式。

## 安装方式对比

| 安装方式 | 适用场景 | 优点 | 缺点 |
|---------|---------|------|------|
| 自动安装脚本 | 开发/测试环境 | 一键安装，简单快速 | 需要Ubuntu 20.04 |
| 手动安装 | 自定义环境 | 完全控制，灵活配置 | 步骤较多，容易出错 |
| Docker部署 | 生产环境 | 环境一致，易于管理 | 需要Docker知识 |

## 快速开始指南

### 方式1：Ubuntu 20.04 自动安装

```bash
# 一键安装所有依赖
chmod +x install-ubuntu.sh
./install-ubuntu.sh

# 启动服务
./start.sh
```

### 方式2：Docker部署

```bash
# 一键Docker部署
chmod +x docker-start.sh
./docker-start.sh
```

### 方式3：手动安装

```bash
# 安装Node.js 18.x
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs

# 安装项目依赖
npm install

# 启动服务
npm start
```

## 系统要求

### 最低要求
- Ubuntu 20.04 LTS
- 2GB RAM
- 1GB 磁盘空间
- Node.js 18.0.0+

### 推荐配置
- Ubuntu 20.04 LTS
- 4GB RAM
- 5GB 磁盘空间
- Node.js 18.x LTS
- Docker 20.10+

## 功能验证

安装完成后，可以通过以下方式验证功能：

### 1. 检查服务状态

```bash
# 本地安装
npm start

# Docker部署
docker-compose ps
```

### 2. 测试工具调用

```bash
# 测试订单查询
curl -X POST http://localhost:3000/tools/call \
  -H "Content-Type: application/json" \
  -d '{"name": "query_order", "arguments": {"phone": "17798762697"}}'

# 测试网点查询
curl -X POST http://localhost:3000/tools/call \
  -H "Content-Type: application/json" \
  -d '{"name": "query_stores", "arguments": {"latitude": 39.946613, "longitude": 116.370503}}'
```

## 常见问题解决

### 1. Node.js版本问题

```bash
# 检查版本
node --version

# 如果版本过低，重新安装
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs
```

### 2. 权限问题

```bash
# 设置npm全局路径
mkdir ~/.npm-global
npm config set prefix '~/.npm-global'
echo 'export PATH=~/.npm-global/bin:$PATH' >> ~/.bashrc
source ~/.bashrc
```

### 3. 依赖安装失败

```bash
# 清理缓存
npm cache clean --force
rm -rf node_modules package-lock.json
npm install
```

### 4. Docker问题

```bash
# 检查Docker状态
sudo systemctl status docker

# 重启Docker服务
sudo systemctl restart docker

# 检查Docker Compose
docker-compose --version
```

## 性能优化建议

### 1. 系统优化

```bash
# 增加文件描述符限制
echo "* soft nofile 65536" >> /etc/security/limits.conf
echo "* hard nofile 65536" >> /etc/security/limits.conf

# 优化内核参数
echo "net.core.somaxconn = 65535" >> /etc/sysctl.conf
echo "net.ipv4.tcp_max_syn_backlog = 65535" >> /etc/sysctl.conf
sysctl -p
```

### 2. Node.js优化

```bash
# 增加内存限制
export NODE_OPTIONS="--max-old-space-size=4096"

# 启用集群模式
export NODE_ENV=production
```

### 3. Docker优化

```yaml
# docker-compose.yml优化
services:
  mcp-server:
    deploy:
      resources:
        limits:
          memory: 1G
          cpus: '0.5'
        reservations:
          memory: 512M
          cpus: '0.25'
```

## 监控和维护

### 1. 日志监控

```bash
# 查看应用日志
tail -f logs/app.log

# Docker日志
docker-compose logs -f
```

### 2. 性能监控

```bash
# 系统资源监控
htop
iostat -x 1

# Node.js性能监控
npm install -g clinic
clinic doctor -- node src/server.js
```

### 3. 健康检查

```bash
# 检查服务健康状态
curl http://localhost:3000/health

# 检查数据库连接
curl http://localhost:3000/status
```

## 安全建议

### 1. 网络安全

```bash
# 配置防火墙
sudo ufw enable
sudo ufw allow 3000/tcp
sudo ufw allow ssh
```

### 2. 应用安全

```bash
# 使用非root用户运行
sudo useradd -m -s /bin/bash mcpuser
sudo chown -R mcpuser:mcpuser /path/to/mcp_test
```

### 3. 数据安全

```bash
# 定期备份数据
tar -czf backup-$(date +%Y%m%d).tar.gz data/

# 加密敏感数据
gpg --symmetric --cipher-algo AES256 data/sensitive.xlsx
```

## 升级和维护

### 1. 应用升级

```bash
# 备份当前版本
cp -r /path/to/mcp_test /path/to/mcp_test.backup

# 更新代码
git pull origin main

# 更新依赖
npm install

# 重启服务
npm restart
```

### 2. 系统维护

```bash
# 定期更新系统
sudo apt update && sudo apt upgrade -y

# 清理系统
sudo apt autoremove -y
sudo apt autoclean
```

## 技术支持

如果遇到问题，请：

1. 查看README.md中的故障排除部分
2. 检查日志文件
3. 在GitHub上提交Issue
4. 联系技术支持团队

## 许可证

MIT License - 详见LICENSE文件
