# 腾讯云ADP MCP Server配置指南

## 🚨 当前问题

腾讯云ADP平台连接失败，错误信息：
- `context deadline exceeded` - 连接超时
- `ECONNRESET` - SSE连接被重置

## 🛠️ 解决方案

### 1. 部署修复后的服务器

```bash
# 上传修复后的文件到CVM
scp src/http-server.js ubuntu@106.53.191.184:~/mcp_demo/src/

# 登录CVM
ssh ubuntu@106.53.191.184

# 进入项目目录
cd ~/mcp_demo

# 停止当前服务
pm2 stop mcp-http-server

# 启动修复后的服务
pm2 start src/http-server.js --name mcp-http-server

# 保存PM2配置
pm2 save

# 查看服务状态
pm2 status

# 查看日志
pm2 logs mcp-http-server
```

### 2. 验证修复效果

```bash
# 测试SSE端点
curl -I http://106.53.191.184:3000/sse

# 测试SSE数据流（10秒后按Ctrl+C停止）
timeout 10s curl -N http://106.53.191.184:3000/sse

# 运行完整测试
chmod +x test-adp-connection.sh
./test-adp-connection.sh
```

## 📋 腾讯云ADP平台配置

### 1. 基本配置JSON

```json
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
```

### 2. 关键配置说明

- **超时时间**: 60秒（增加超时时间避免连接超时）
- **SSE读取超时**: 300秒（5分钟）
- **User-Agent**: 标识为腾讯云ADP客户端
- **Content-Type**: 确保JSON格式正确

## 🔧 修复内容

### 1. SSE端点优化

- ✅ 添加详细的连接日志
- ✅ 改进错误处理机制
- ✅ 优化心跳频率（10秒）
- ✅ 添加连接超时处理（5分钟）
- ✅ 禁用Nginx缓冲

### 2. CORS配置优化

- ✅ 添加OPTIONS预检请求处理
- ✅ 支持所有HTTP方法
- ✅ 设置预检请求缓存时间

### 3. 错误处理改进

- ✅ 详细的错误日志
- ✅ 连接状态监控
- ✅ 自动清理机制

## 🧪 测试验证

### 1. 本地测试

```bash
# 测试SSE端点
curl -I http://106.53.191.184:3000/sse

# 预期响应头
HTTP/1.1 200 OK
Content-Type: text/event-stream
Cache-Control: no-cache
Connection: keep-alive
Access-Control-Allow-Origin: *
```

### 2. SSE数据流测试

```bash
# 测试SSE数据流
timeout 15s curl -N http://106.53.191.184:3000/sse

# 预期输出
data: {"type":"connection","status":"connected","timestamp":"2025-09-05T06:20:00.000Z","server":"ai-customer-service-mcp-server","version":"1.0.0"}

data: {"type":"heartbeat","timestamp":"2025-09-05T06:20:10.000Z","status":"alive"}

data: {"type":"heartbeat","timestamp":"2025-09-05T06:20:20.000Z","status":"alive"}
```

### 3. 完整功能测试

```bash
# 运行完整测试套件
./test-adp-connection.sh

# 预期结果：所有测试通过
# 成功率: 100%
```

## 📊 监控和日志

### 1. 查看服务状态

```bash
# 查看PM2状态
pm2 status

# 查看实时日志
pm2 logs mcp-http-server --lines 50

# 查看错误日志
pm2 logs mcp-http-server --err --lines 20
```

### 2. 关键日志信息

```
# 正常启动日志
AI智能客服MCP Server已启动
服务器地址: http://0.0.0.0:3000
健康检查: http://0.0.0.0:3000/health
SSE端点: http://0.0.0.0:3000/sse

# SSE连接日志
SSE连接请求来自: 106.53.191.184 Mozilla/5.0 (compatible; TencentADP/1.0)
SSE连接已建立

# 心跳日志
data: {"type":"heartbeat","timestamp":"2025-09-05T06:20:10.000Z","status":"alive"}
```

## 🚨 故障排除

### 1. 如果SSE仍然失败

```bash
# 检查防火墙
sudo ufw status
sudo ufw allow 3000/tcp

# 检查端口占用
sudo netstat -tlnp | grep :3000

# 重启服务
pm2 restart mcp-http-server
```

### 2. 如果连接超时

```bash
# 增加超时时间
# 在ADP配置中将timeout改为120秒

# 检查网络连接
ping 106.53.191.184
telnet 106.53.191.184 3000
```

### 3. 如果CORS错误

```bash
# 测试CORS
curl -I -X OPTIONS http://106.53.191.184:3000/sse \
  -H "Origin: https://adp.tencent.com" \
  -H "Access-Control-Request-Method: GET"

# 预期响应
HTTP/1.1 200 OK
Access-Control-Allow-Origin: *
Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS
```

## 🎯 最佳实践

1. **部署前测试**: 确保本地测试通过
2. **监控日志**: 实时查看服务日志
3. **网络检查**: 确保防火墙和网络配置正确
4. **超时配置**: 根据网络情况调整超时时间
5. **错误处理**: 关注错误日志，及时处理问题

## 📞 技术支持

如果问题仍然存在：

1. 运行完整测试：`./test-adp-connection.sh`
2. 查看详细日志：`pm2 logs mcp-http-server`
3. 检查网络连接：`ping 106.53.191.184`
4. 联系腾讯云技术支持
5. 联系项目技术支持团队
