# MCP Server 测试总结

## 测试工具概览

我们为AI智能客服MCP Server提供了完整的测试工具集，包括：

### 1. 快速测试脚本 (`quick-test.js`)
- **用途**: 验证基本功能，无需启动服务器
- **适用场景**: 开发调试、快速验证
- **运行方式**: `node quick-test.js`

### 2. 完整测试脚本 (`test-mcp-server.sh`)
- **用途**: 全面的功能测试，包括HTTP API测试
- **适用场景**: 生产环境验证、CI/CD集成
- **运行方式**: `./test-mcp-server.sh`

### 3. 手动测试指南 (`MANUAL_TEST_GUIDE.md`)
- **用途**: 逐步验证每个功能
- **适用场景**: 问题排查、详细调试
- **运行方式**: 按照指南手动执行

## 测试覆盖范围

### 功能测试
- ✅ 数据管理器初始化
- ✅ 订单查询工具
- ✅ 网点查询工具
- ✅ 错误处理机制
- ✅ 数据查询功能

### API测试
- ✅ 工具列表接口
- ✅ 订单查询接口
- ✅ 网点查询接口
- ✅ 错误响应处理

### 性能测试
- ✅ 响应时间测试
- ✅ 并发请求测试
- ✅ 内存使用测试

### 错误处理测试
- ✅ 无效参数处理
- ✅ 网络错误处理
- ✅ 数据格式错误处理

## 测试数据

### 测试手机号
- `17798762697` - 有完整订单数据
- `17796499753` - 有订单数据
- `17796025359` - 有订单数据

### 测试坐标
- 北京后海: `39.946613, 116.370503`
- 上海外滩: `31.230416, 121.473701`
- 深圳华强北: `22.543099, 114.057868`

## 测试执行流程

### 开发阶段测试
```bash
# 1. 快速验证基本功能
node quick-test.js

# 2. 启动服务器
npm start

# 3. 运行完整测试
./test-mcp-server.sh
```

### 生产环境测试
```bash
# 1. 启动服务器
npm start

# 2. 运行完整测试
./test-mcp-server.sh -s http://your-server:3000

# 3. 性能测试
./test-mcp-server.sh --performance
```

### 问题排查测试
```bash
# 1. 查看手动测试指南
cat MANUAL_TEST_GUIDE.md

# 2. 逐步执行测试
curl -X POST http://localhost:3000/tools/list \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc": "2.0", "id": 1, "method": "tools/list"}'
```

## 测试结果解读

### 成功标准
- 所有功能测试通过
- API响应时间 < 100ms
- 错误处理正常
- 数据查询准确

### 失败处理
- 检查服务器日志
- 验证数据文件
- 检查网络连接
- 查看错误信息

## 持续集成

### GitHub Actions 示例
```yaml
name: MCP Server Tests
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: actions/setup-node@v2
        with:
          node-version: '18'
      - run: npm install
      - run: node quick-test.js
      - run: npm start &
      - run: ./test-mcp-server.sh
```

### 本地CI脚本
```bash
#!/bin/bash
# ci-test.sh
set -e

echo "Running CI tests..."
npm install
node quick-test.js
npm start &
sleep 5
./test-mcp-server.sh
echo "All tests passed!"
```

## 测试最佳实践

### 1. 测试前准备
- 确保环境干净
- 检查依赖版本
- 验证数据文件

### 2. 测试执行
- 先运行快速测试
- 再运行完整测试
- 记录测试结果

### 3. 测试后处理
- 清理测试数据
- 停止测试服务
- 生成测试报告

## 故障排除

### 常见测试失败原因
1. **服务器未启动** - 检查端口占用
2. **数据文件缺失** - 验证data目录
3. **网络连接问题** - 检查防火墙设置
4. **权限问题** - 检查文件权限

### 调试技巧
1. **查看日志** - `tail -f server.log`
2. **检查进程** - `ps aux | grep node`
3. **验证端口** - `netstat -tulpn | grep 3000`
4. **测试连接** - `curl http://localhost:3000/health`

## 测试报告模板

### 测试环境
- 操作系统: Ubuntu 20.04 LTS
- Node.js版本: v18.20.8
- 测试时间: 2025-09-05
- 测试人员: [姓名]

### 测试结果
| 测试项目 | 状态 | 响应时间 | 备注 |
|---------|------|----------|------|
| 数据管理器 | ✅ 通过 | - | 正常 |
| 订单查询 | ✅ 通过 | 50ms | 正常 |
| 网点查询 | ✅ 通过 | 80ms | 正常 |
| 错误处理 | ✅ 通过 | 30ms | 正常 |
| 性能测试 | ✅ 通过 | 平均60ms | 正常 |

### 结论
所有测试通过，系统功能正常，可以投入使用。

## 联系支持

如有测试相关问题：
- 查看README.md故障排除部分
- 检查MANUAL_TEST_GUIDE.md
- 在GitHub提交Issue
- 联系技术支持团队
