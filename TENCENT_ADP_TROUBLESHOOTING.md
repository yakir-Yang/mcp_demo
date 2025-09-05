# 腾讯云ADP连接问题解决指南

## 🚨 问题描述

腾讯云ADP平台提示：`460009-MCP server连接失败, url:http://106.53.191.184:3000`

## 🔍 问题诊断步骤

### 1. 检查服务器状态

```bash
# 检查服务器是否运行
curl -I http://106.53.191.184:3000/health

# 检查健康状态
curl http://106.53.191.184:3000/health
```

**预期响应：**
```json
{
  "status": "healthy",
  "timestamp": "2025-09-05T06:13:00.197Z",
  "version": "1.0.0",
  "services": {
    "dataManager": "ready",
    "stores": 200,
    "orders": 100
  }
}
```

### 2. 检查MCP协议支持

```bash
# 测试MCP初始化
curl -X POST http://106.53.191.184:3000/mcp/initialize \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "id": 1,
    "method": "initialize",
    "params": {
      "protocolVersion": "2024-11-05",
      "capabilities": {},
      "clientInfo": {
        "name": "tencent-adp",
        "version": "1.0.0"
      }
    }
  }'
```

### 3. 检查工具列表

```bash
# 测试工具列表
curl -X POST http://106.53.191.184:3000/tools/list \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc": "2.0", "id": 1, "method": "tools/list"}'
```

## 🛠️ 解决方案

### 方案1: 使用ADP专用服务器（推荐）

我已经创建了专门为腾讯云ADP优化的MCP服务器版本。

#### 1. 部署ADP专用服务器

```bash
# 上传ADP专用服务器文件到CVM
scp src/adp-server.js ubuntu@106.53.191.184:~/mcp_demo/src/

# 登录CVM
ssh ubuntu@106.53.191.184

# 进入项目目录
cd ~/mcp_demo

# 停止当前服务
pm2 stop mcp-http-server

# 启动ADP专用服务器
pm2 start src/adp-server.js --name mcp-adp-server

# 保存PM2配置
pm2 save
```

#### 2. 测试ADP连接

```bash
# 运行ADP连接测试
./test-adp-connection.sh
```

### 方案2: 修复现有服务器

如果继续使用现有服务器，需要添加MCP协议支持：

#### 1. 添加MCP初始化端点

在现有的HTTP服务器中添加：

```javascript
// MCP协议 - 初始化端点
app.post('/mcp/initialize', (req, res) => {
  res.json({
    jsonrpc: '2.0',
    id: req.body.id || 1,
    result: {
      protocolVersion: '2024-11-05',
      capabilities: {
        tools: {}
      },
      serverInfo: {
        name: 'ai-customer-service-mcp-server',
        version: '1.0.0'
      }
    }
  });
});
```

#### 2. 更新CORS配置

```javascript
app.use(cors({
  origin: ['https://adp.tencent.com', 'https://*.tencent.com'],
  credentials: true,
  methods: ['GET', 'POST', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'X-Requested-With']
}));
```

### 方案3: 使用Nginx反向代理

#### 1. 配置Nginx

```bash
# 创建Nginx配置
sudo nano /etc/nginx/sites-available/mcp-adp
```

添加配置：

```nginx
server {
    listen 80;
    server_name 106.53.191.184;

    # 添加CORS头
    add_header 'Access-Control-Allow-Origin' 'https://adp.tencent.com' always;
    add_header 'Access-Control-Allow-Methods' 'GET, POST, OPTIONS' always;
    add_header 'Access-Control-Allow-Headers' 'Content-Type, Authorization, X-Requested-With' always;
    add_header 'Access-Control-Allow-Credentials' 'true' always;

    # 处理预检请求
    if ($request_method = 'OPTIONS') {
        add_header 'Access-Control-Allow-Origin' 'https://adp.tencent.com';
        add_header 'Access-Control-Allow-Methods' 'GET, POST, OPTIONS';
        add_header 'Access-Control-Allow-Headers' 'Content-Type, Authorization, X-Requested-With';
        add_header 'Access-Control-Max-Age' 1728000;
        add_header 'Content-Type' 'text/plain; charset=utf-8';
        add_header 'Content-Length' 0;
        return 204;
    }

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

#### 2. 启用配置

```bash
# 启用站点
sudo ln -s /etc/nginx/sites-available/mcp-adp /etc/nginx/sites-enabled/
sudo rm /etc/nginx/sites-enabled/default

# 测试配置
sudo nginx -t

# 重载Nginx
sudo systemctl reload nginx
```

## 🧪 测试验证

### 1. 运行完整测试

```bash
# 运行ADP连接测试
./test-adp-connection.sh

# 或手动测试各个端点
curl http://106.53.191.184:3000/health
curl -X POST http://106.53.191.184:3000/mcp/initialize -H "Content-Type: application/json" -d '{"jsonrpc": "2.0", "id": 1, "method": "initialize"}'
curl -X POST http://106.53.191.184:3000/tools/list -H "Content-Type: application/json" -d '{"jsonrpc": "2.0", "id": 1, "method": "tools/list"}'
```

### 2. 验证MCP协议

```bash
# 测试MCP初始化
curl -X POST http://106.53.191.184:3000/mcp/initialize \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "id": 1,
    "method": "initialize",
    "params": {
      "protocolVersion": "2024-11-05",
      "capabilities": {},
      "clientInfo": {
        "name": "tencent-adp",
        "version": "1.0.0"
      }
    }
  }'
```

**预期响应：**
```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "result": {
    "protocolVersion": "2024-11-05",
    "capabilities": {
      "tools": {}
    },
    "serverInfo": {
      "name": "ai-customer-service-mcp-server",
      "version": "1.0.0"
    }
  }
}
```

## 📋 腾讯云ADP配置

### 1. ADP平台配置

在腾讯云ADP平台中配置：

```json
{
  "name": "AI智能客服MCP Server",
  "url": "http://106.53.191.184:3000",
  "protocol": "mcp",
  "version": "2024-11-05",
  "endpoints": {
    "initialize": "/mcp/initialize",
    "tools_list": "/tools/list",
    "tools_call": "/tools/call"
  },
  "tools": [
    "query_order",
    "query_stores"
  ]
}
```

### 2. 连接参数

- **服务器URL**: `http://106.53.191.184:3000`
- **协议类型**: MCP (Model Context Protocol)
- **初始化端点**: `/mcp/initialize`
- **工具列表端点**: `/tools/list`
- **工具调用端点**: `/tools/call`

## 🚨 常见问题

### 1. 连接超时

**问题**: 连接超时或无法访问

**解决方案**:
```bash
# 检查防火墙
sudo ufw status
sudo ufw allow 3000/tcp

# 检查服务状态
pm2 status
pm2 logs mcp-adp-server
```

### 2. CORS错误

**问题**: 跨域请求被阻止

**解决方案**:
```bash
# 检查CORS配置
curl -I -X OPTIONS http://106.53.191.184:3000/tools/list \
  -H "Origin: https://adp.tencent.com" \
  -H "Access-Control-Request-Method: POST"
```

### 3. MCP协议错误

**问题**: MCP协议不兼容

**解决方案**:
```bash
# 使用ADP专用服务器
pm2 start src/adp-server.js --name mcp-adp-server
```

### 4. 工具调用失败

**问题**: 工具调用返回错误

**解决方案**:
```bash
# 检查数据加载
pm2 logs mcp-adp-server | grep "数据加载"

# 测试工具调用
curl -X POST http://106.53.191.184:3000/tools/call \
  -H "Content-Type: application/json" \
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

## 📞 技术支持

如果问题仍然存在：

1. 运行完整测试：`./test-adp-connection.sh`
2. 查看服务器日志：`pm2 logs mcp-adp-server`
3. 检查网络连接：`ping 106.53.191.184`
4. 联系腾讯云技术支持
5. 联系项目技术支持团队

## 🎯 最佳实践

1. **使用ADP专用服务器**: 专门为腾讯云ADP优化的版本
2. **配置CORS**: 允许ADP平台跨域访问
3. **实现MCP协议**: 完整的MCP协议支持
4. **监控服务状态**: 定期检查服务健康状态
5. **日志记录**: 详细记录连接和调用日志
