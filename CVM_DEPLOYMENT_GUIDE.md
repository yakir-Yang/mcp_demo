# CVM部署指南 - HTTP版本MCP Server

## 🚨 问题分析

您遇到的问题是因为原始的MCP Server使用的是stdio传输，不能通过HTTP访问。我已经创建了HTTP版本的MCP Server来解决这个问题。

## 🔧 解决方案

### 步骤1: 停止当前服务

```bash
# 停止当前运行的MCP Server
pkill -f "node src/server.js"

# 或者如果使用PM2
pm2 stop mcp-server
pm2 delete mcp-server
```

### 步骤2: 更新项目文件

将新的HTTP服务器文件上传到CVM：

```bash
# 从本地上传新文件到CVM
scp src/http-server.js ubuntu@106.53.191.184:~/mcp_demo/src/
scp package.json ubuntu@106.53.191.184:~/mcp_demo/
scp test-http-server.sh ubuntu@106.53.191.184:~/mcp_demo/
```

### 步骤3: 在CVM上更新项目

```bash
# 登录CVM
ssh ubuntu@106.53.191.184

# 进入项目目录
cd ~/mcp_demo

# 安装新的依赖（如果需要）
npm install

# 给测试脚本添加执行权限
chmod +x test-http-server.sh
```

### 步骤4: 启动HTTP版本的MCP Server

```bash
# 启动HTTP服务器
npm start

# 或者使用PM2管理
pm2 start src/http-server.js --name mcp-http-server
pm2 save
```

### 步骤5: 配置防火墙

```bash
# 开放端口3000
sudo ufw allow 3000/tcp
sudo ufw reload

# 检查防火墙状态
sudo ufw status
```

### 步骤6: 测试HTTP服务器

```bash
# 运行测试脚本
./test-http-server.sh

# 或者手动测试
curl http://localhost:3000/health
curl -X POST http://localhost:3000/tools/list \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc": "2.0", "id": 1, "method": "tools/list"}'
```

## 🌐 服务端点

HTTP版本的MCP Server提供以下端点：

### 基础端点
- `GET /` - 服务信息
- `GET /health` - 健康检查
- `POST /tools/list` - 工具列表
- `POST /tools/call` - 工具调用

### 兼容性端点
- `POST /query_order` - 直接订单查询
- `POST /query_stores` - 直接网点查询

## 📋 测试命令

### 健康检查
```bash
curl http://106.53.191.184:3000/health
```

### 工具列表
```bash
curl -X POST http://106.53.191.184:3000/tools/list \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc": "2.0", "id": 1, "method": "tools/list"}'
```

### 订单查询
```bash
curl -X POST http://106.53.191.184:3000/tools/call \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "id": 2,
    "method": "tools/call",
    "params": {
      "name": "query_order",
      "arguments": {
        "phone": "17798762697"
      }
    }
  }'
```

### 网点查询
```bash
curl -X POST http://106.53.191.184:3000/tools/call \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "id": 3,
    "method": "tools/call",
    "params": {
      "name": "query_stores",
      "arguments": {
        "latitude": 39.946613,
        "longitude": 116.370503,
        "limit": 3
      }
    }
  }'
```

## 🔒 生产环境配置

### 使用PM2管理进程

```bash
# 安装PM2
npm install -g pm2

# 启动服务
pm2 start src/http-server.js --name mcp-http-server

# 设置开机自启
pm2 startup
pm2 save

# 查看服务状态
pm2 status
pm2 logs mcp-http-server
```

### 配置Nginx反向代理

```bash
# 安装Nginx
sudo apt install nginx

# 创建配置文件
sudo nano /etc/nginx/sites-available/mcp-server
```

添加以下配置：

```nginx
server {
    listen 80;
    server_name 106.53.191.184;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
        proxy_read_timeout 300s;
        proxy_connect_timeout 75s;
    }
}
```

启用配置：

```bash
sudo ln -s /etc/nginx/sites-available/mcp-server /etc/nginx/sites-enabled/
sudo rm /etc/nginx/sites-enabled/default
sudo nginx -t
sudo systemctl reload nginx
```

## 🧪 完整测试流程

### 1. 本地测试
```bash
# 启动服务器
npm start

# 运行测试
./test-http-server.sh
```

### 2. 远程测试
```bash
# 测试远程服务器
./test-remote-server.sh -s http://106.53.191.184:3000
```

### 3. 腾讯云ADP对接测试
```bash
# 测试ADP对接
curl -X POST http://106.53.191.184:3000/tools/call \
  -H "Content-Type: application/json" \
  -H "User-Agent: Tencent-ADP-Client/1.0" \
  -d '{
    "jsonrpc": "2.0",
    "id": 1,
    "method": "tools/call",
    "params": {
      "name": "query_order",
      "arguments": {
        "phone": "17798762697"
      }
    }
  }'
```

## 📊 监控和维护

### 查看服务状态
```bash
# 查看PM2状态
pm2 status

# 查看日志
pm2 logs mcp-http-server

# 查看系统资源
htop
```

### 重启服务
```bash
# 重启PM2服务
pm2 restart mcp-http-server

# 或者重启整个服务
pm2 stop mcp-http-server
pm2 start mcp-http-server
```

## 🚨 故障排除

### 常见问题

#### 1. 端口被占用
```bash
# 查看端口占用
sudo netstat -tulpn | grep :3000

# 杀死占用进程
sudo kill -9 <PID>
```

#### 2. 防火墙问题
```bash
# 检查防火墙状态
sudo ufw status

# 开放端口
sudo ufw allow 3000/tcp
```

#### 3. 服务启动失败
```bash
# 查看错误日志
pm2 logs mcp-http-server

# 检查Node.js版本
node --version

# 检查依赖
npm list
```

## 📞 技术支持

如果遇到问题：

1. 查看PM2日志：`pm2 logs mcp-http-server`
2. 检查系统日志：`journalctl -u nginx`
3. 运行测试脚本：`./test-http-server.sh`
4. 联系技术支持团队

## 🎯 下一步

部署完成后：

1. 运行测试验证功能
2. 配置腾讯云ADP平台
3. 设置监控和告警
4. 优化性能和安全性
