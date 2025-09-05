# 腾讯云智能体开放平台ADP对接指南

## 🌐 服务器信息

- **公网IP**: `106.53.191.184`
- **端口**: `3000`
- **完整URL**: `http://106.53.191.184:3000`
- **协议**: HTTP/SSE
- **状态**: 运行中

## 🔧 ADP平台配置步骤

### 步骤1: 登录ADP平台
1. 访问 [腾讯云智能体开放平台](https://adp.tencent.com)
2. 使用您的腾讯云账号登录
3. 进入"连接管理"或"外部工具"页面

### 步骤2: 创建MCP连接
1. 点击"新建连接"或"添加工具"
2. 选择连接类型为"MCP Server"或"自定义工具"

### 步骤3: 配置连接参数

#### 基本信息
```json
{
  "name": "AI智能客服MCP Server",
  "description": "提供订单查询和网点查询功能的MCP服务器",
  "type": "mcp",
  "version": "1.0.0"
}
```

#### 连接配置
```json
{
  "endpoint": "http://106.53.191.184:3000",
  "protocol": "sse",
  "timeout": 30000,
  "retry": 3,
  "headers": {
    "Content-Type": "application/json",
    "User-Agent": "Tencent-ADP-Client/1.0"
  }
}
```

#### 工具配置
```json
{
  "tools": [
    {
      "name": "query_order",
      "description": "根据手机号查询订单详情",
      "inputSchema": {
        "type": "object",
        "properties": {
          "phone": {
            "type": "string",
            "description": "用户手机号",
            "pattern": "^1[3-9]\\d{9}$"
          }
        },
        "required": ["phone"]
      }
    },
    {
      "name": "query_stores",
      "description": "根据经纬度查询附近网点信息",
      "inputSchema": {
        "type": "object",
        "properties": {
          "latitude": {
            "type": "number",
            "description": "纬度",
            "minimum": -90,
            "maximum": 90
          },
          "longitude": {
            "type": "number",
            "description": "经度",
            "minimum": -180,
            "maximum": 180
          },
          "limit": {
            "type": "number",
            "description": "返回网点数量限制",
            "default": 10,
            "minimum": 1,
            "maximum": 50
          }
        },
        "required": ["latitude", "longitude"]
      }
    }
  ]
}
```

### 步骤4: 测试连接
1. 点击"测试连接"按钮
2. 系统会自动测试服务器连通性
3. 验证工具列表和基本功能

### 步骤5: 保存配置
1. 确认配置无误后，点击"保存"
2. 系统会生成连接ID和密钥
3. 记录这些信息以备后续使用

## 🧪 连接测试

### 使用测试脚本
```bash
# 运行远程测试脚本
./test-remote-server.sh

# 或指定服务器地址
./test-remote-server.sh -s http://106.53.191.184:3000
```

### 手动测试命令
```bash
# 测试服务器连通性
curl -X GET http://106.53.191.184:3000/health

# 测试工具列表
curl -X POST http://106.53.191.184:3000/tools/list \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc": "2.0", "id": 1, "method": "tools/list"}'

# 测试订单查询
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

# 测试网点查询
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

## 📋 工具使用示例

### 订单查询工具
```json
{
  "name": "query_order",
  "arguments": {
    "phone": "17798762697"
  }
}
```

**返回示例：**
```json
{
  "content": [
    {
      "type": "text",
      "text": "找到 1 个订单：\n\n订单 1:\n  手机号: 17798762697\n  订单号: PO202508281731220218\n  租借位置: 北京后海-166分店\n  租借状态: 已暂停\n  是否允许停止计费: 否\n  设备ID: D20219\n  租借开始时间: 2025-08-28 20:35:00\n  持续时间: 32分钟\n  计费: ¥3.2\n  支付方式: 微信支付"
    }
  ]
}
```

### 网点查询工具
```json
{
  "name": "query_stores",
  "arguments": {
    "latitude": 39.946613,
    "longitude": 116.370503,
    "limit": 3
  }
}
```

**返回示例：**
```json
{
  "content": [
    {
      "type": "text",
      "text": "找到 3 个附近网点：\n\n网点 1:\n  网点名称: 北京后海-110分店\n  状态: 正常\n  经纬度: 116.3705,39.94661\n  详细地址: 北京市西城区羊房胡同甲23号\n  距离: 0.00公里\n  营业时间: 9:00-22:00\n  评分: 4.5\n  联系电话: 15858905939\n  门店类型: 直营店"
    }
  ]
}
```

## 🔒 安全配置

### 防火墙设置
```bash
# 确保端口3000对外开放
sudo ufw allow 3000/tcp

# 检查防火墙状态
sudo ufw status
```

### 访问控制
```bash
# 限制访问IP（可选）
sudo ufw allow from 特定IP to any port 3000

# 查看访问日志
sudo tail -f /var/log/nginx/access.log
```

## 📊 监控和维护

### 服务状态监控
```bash
# 检查服务状态
sudo systemctl status your-mcp-service

# 查看服务日志
sudo journalctl -u your-mcp-service -f

# 检查端口占用
sudo netstat -tulpn | grep :3000
```

### 性能监控
```bash
# 查看系统资源
htop
iostat -x 1

# 查看网络连接
ss -tulpn | grep :3000
```

## 🚨 故障排除

### 常见问题

#### 1. 连接超时
```bash
# 检查服务器状态
curl -I http://106.53.191.184:3000/health

# 检查网络连通性
ping 106.53.191.184

# 检查端口是否开放
telnet 106.53.191.184 3000
```

#### 2. 工具调用失败
```bash
# 检查工具列表
curl -X POST http://106.53.191.184:3000/tools/list \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc": "2.0", "id": 1, "method": "tools/list"}'

# 查看服务器日志
tail -f /path/to/your/mcp_test/server.log
```

#### 3. 数据查询异常
```bash
# 检查数据文件
ls -la /path/to/your/mcp_test/data/

# 验证数据格式
head -5 /path/to/your/mcp_test/data/stores.tsv
head -5 /path/to/your/mcp_test/data/orders.tsv
```

## 📞 技术支持

### 联系方式
- **技术支持邮箱**: [您的邮箱]
- **GitHub Issues**: [项目地址]
- **文档**: README.md

### 支持时间
- **工作日**: 9:00-18:00
- **紧急支持**: 24/7

## 📈 后续优化建议

### 1. 性能优化
- 添加Redis缓存
- 实现数据库连接池
- 启用Gzip压缩

### 2. 安全增强
- 添加API密钥认证
- 实现请求限流
- 启用HTTPS

### 3. 监控告警
- 集成Prometheus监控
- 设置告警规则
- 实现自动恢复

### 4. 扩展功能
- 添加更多查询工具
- 实现数据同步
- 支持批量操作
