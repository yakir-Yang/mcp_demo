# MCP Server 手动测试指南

## 测试方法概述

我们提供了三种测试方法，从简单到复杂：

1. **快速测试** - 验证基本功能
2. **完整测试** - 全面的功能测试
3. **手动测试** - 逐步验证每个功能

## 方法1: 快速测试（推荐新手）

### 运行快速测试脚本

```bash
# 运行快速测试
node quick-test.js
```

### 预期输出

```
==========================================
  AI智能客服MCP Server 快速测试
==========================================

[TEST] 测试: 数据管理器
[INFO] 初始化数据管理器...
[INFO] 数据加载成功: 6 个门店, 5 个订单
[SUCCESS] 数据管理器 测试通过

[TEST] 测试: 数据查询功能
[INFO] 测试数据查询功能...
[INFO] 找到 1 个订单
[INFO] 找到 3 个附近网点
[SUCCESS] 数据查询功能 测试通过

[TEST] 测试: 订单查询工具
[INFO] 测试订单查询工具...
[INFO] 订单查询结果:
找到 1 个订单：

订单 1:
  手机号: 17798762697
  订单号: PO202508281731220218
  ...
[SUCCESS] 订单查询工具 测试通过

[TEST] 测试: 网点查询工具
[INFO] 测试网点查询工具...
[INFO] 网点查询结果:
找到 3 个附近网点：

网点 1:
  网点名称: 北京后海-110分店
  ...
[SUCCESS] 网点查询工具 测试通过

[TEST] 测试: 错误处理
[INFO] 测试错误处理...
[INFO] 错误处理正常
[SUCCESS] 错误处理 测试通过

==========================================
  测试报告
==========================================
总测试数: 5
通过测试: 5
失败测试: 0
成功率: 100%

[SUCCESS] 🎉 所有测试通过！MCP Server功能正常。
```

## 方法2: 完整测试（推荐生产环境）

### 启动MCP Server

```bash
# 启动服务器
npm start
```

### 运行完整测试

```bash
# 运行完整测试脚本
./test-mcp-server.sh
```

### 测试选项

```bash
# 使用默认参数
./test-mcp-server.sh

# 测试远程服务器
./test-mcp-server.sh -s http://192.168.1.100:3000

# 使用指定手机号
./test-mcp-server.sh -p 13800138000

# 查看帮助
./test-mcp-server.sh -h
```

## 方法3: 手动测试（推荐开发调试）

### 步骤1: 启动MCP Server

```bash
# 启动服务器
npm start
```

服务器启动后，您应该看到：
```
AI智能客服MCP Server已启动
```

### 步骤2: 测试工具列表

```bash
# 测试工具列表
curl -X POST http://localhost:3000/tools/list \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc": "2.0", "id": 1, "method": "tools/list"}'
```

**预期响应：**
```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "result": {
    "tools": [
      {
        "name": "query_order",
        "description": "根据手机号查询订单详情",
        "inputSchema": {...}
      },
      {
        "name": "query_stores", 
        "description": "根据经纬度查询附近网点信息",
        "inputSchema": {...}
      }
    ]
  }
}
```

### 步骤3: 测试订单查询

```bash
# 测试订单查询
curl -X POST http://localhost:3000/tools/call \
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

**预期响应：**
```json
{
  "jsonrpc": "2.0",
  "id": 2,
  "result": {
    "content": [
      {
        "type": "text",
        "text": "找到 1 个订单：\n\n订单 1:\n  手机号: 17798762697\n  订单号: PO202508281731220218\n  ..."
      }
    ]
  }
}
```

### 步骤4: 测试网点查询

```bash
# 测试网点查询
curl -X POST http://localhost:3000/tools/call \
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

**预期响应：**
```json
{
  "jsonrpc": "2.0",
  "id": 3,
  "result": {
    "content": [
      {
        "type": "text",
        "text": "找到 3 个附近网点：\n\n网点 1:\n  网点名称: 北京后海-110分店\n  ..."
      }
    ]
  }
}
```

### 步骤5: 测试错误处理

```bash
# 测试无效手机号
curl -X POST http://localhost:3000/tools/call \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "id": 4,
    "method": "tools/call",
    "params": {
      "name": "query_order",
      "arguments": {
        "phone": "123"
      }
    }
  }'
```

**预期响应：**
```json
{
  "jsonrpc": "2.0",
  "id": 4,
  "result": {
    "content": [
      {
        "type": "text",
        "text": "错误: 手机号格式不正确"
      }
    ],
    "isError": true
  }
}
```

## 测试数据说明

### 可用的测试手机号

- `17798762697` - 有订单数据
- `17796499753` - 有订单数据
- `17796025359` - 有订单数据

### 可用的测试坐标

- 北京后海: `39.946613, 116.370503`
- 上海外滩: `31.230416, 121.473701`
- 深圳华强北: `22.543099, 114.057868`

## 常见问题排查

### 1. 服务器启动失败

```bash
# 检查端口是否被占用
sudo netstat -tulpn | grep :3000

# 检查Node.js版本
node --version

# 检查依赖是否安装
npm list
```

### 2. 测试请求失败

```bash
# 检查服务器是否运行
curl http://localhost:3000/health

# 检查防火墙设置
sudo ufw status

# 查看服务器日志
tail -f server.log
```

### 3. 数据查询失败

```bash
# 检查数据文件
ls -la data/

# 检查数据格式
head -5 data/stores.tsv
head -5 data/orders.tsv
```

## 性能测试

### 并发测试

```bash
# 使用ab工具进行并发测试
ab -n 100 -c 10 -p test-data.json -T application/json http://localhost:3000/tools/call
```

### 压力测试

```bash
# 使用wrk工具进行压力测试
wrk -t12 -c400 -d30s -s test-script.lua http://localhost:3000/tools/call
```

## 测试报告模板

### 测试环境信息

- 操作系统: Ubuntu 20.04 LTS
- Node.js版本: v18.20.8
- npm版本: 10.8.2
- 测试时间: 2025-09-05
- 测试人员: [您的姓名]

### 测试结果

| 测试项目 | 状态 | 响应时间 | 备注 |
|---------|------|----------|------|
| 工具列表 | ✅ 通过 | 50ms | 正常 |
| 订单查询 | ✅ 通过 | 100ms | 正常 |
| 网点查询 | ✅ 通过 | 80ms | 正常 |
| 错误处理 | ✅ 通过 | 30ms | 正常 |
| 性能测试 | ✅ 通过 | 平均60ms | 正常 |

### 结论

所有功能测试通过，MCP Server运行正常，可以投入使用。

## 联系支持

如果测试过程中遇到问题：

1. 查看README.md中的故障排除部分
2. 检查日志文件
3. 在GitHub上提交Issue
4. 联系技术支持团队
