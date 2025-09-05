# 数据更新指南

## 📊 数据文件说明

### 当前配置
- **门店数据**: `data/stores.xlsx`
- **订单数据**: `data/orders.xlsx`
- **数据格式**: Excel (.xlsx) 文件
- **加载方式**: 自动从Excel文件加载，失败时使用示例数据

### 数据文件结构

#### 门店数据 (stores.xlsx)
| 列名 | 类型 | 说明 | 示例 |
|------|------|------|------|
| 网点名称 | string | 门店名称 | 北京后海-110分店 |
| 状态 | string | 营业状态 | 正常 |
| 经纬度 | string | 坐标信息 | 116.370503,39.946613 |
| 省份 | string | 所属省份 | 北京市 |
| 城市 | string | 所属城市 | 北京市 |
| 区/县 | string | 所属区县 | 西城区 |
| 详细地址 | string | 具体地址 | 北京市西城区羊房胡同甲23号 |
| 经度 | number | 经度值 | 116.3705 |
| 纬度 | number | 纬度值 | 39.94661 |
| 门店类型 | string | 门店类型 | 直营店 |
| 开业时间 | string | 开业日期 | 2024/3/1 |
| 营业时间 | string | 营业时间段 | 9:00-22:00 |
| 评分 | number | 门店评分 | 4.5 |
| 联系电话 | string | 联系电话 | 15858905939 |

#### 订单数据 (orders.xlsx)
| 列名 | 类型 | 说明 | 示例 |
|------|------|------|------|
| 订单号 | string | 唯一订单标识 | PO202508281731220218 |
| 用户id | string | 用户标识 | U10058 |
| 手机号 | string | 用户手机号 | 17798762697 |
| 设备id | string | 设备标识 | D20219 |
| 租借位置 | string | 租借门店 | 北京后海-166分店 |
| 租借开始时间 | string | 开始时间 | 2025-08-28 20:35:00 |
| 退还时间 | string | 退还时间 | (空) |
| 持续时间/分钟 | number | 使用时长 | 32 |
| 归还网点 | string | 归还门店 | (空) |
| 计费 | number | 费用金额 | 3.2 |
| 租借状态 | string | 订单状态 | 已暂停 |
| 支付方式 | string | 支付方式 | wechat_pay |

## 🔄 数据更新流程

### 方法1: 直接更新Excel文件（推荐）

1. **编辑Excel文件**
   ```bash
   # 在本地编辑Excel文件
   # 使用Excel、WPS或其他电子表格软件
   ```

2. **上传到CVM**
   ```bash
   # 上传更新后的文件到CVM
   scp data/stores.xlsx ubuntu@106.53.191.184:~/mcp_demo/data/
   scp data/orders.xlsx ubuntu@106.53.191.184:~/mcp_demo/data/
   ```

3. **重启服务**
   ```bash
   # 登录CVM
   ssh ubuntu@106.53.191.184
   
   # 进入项目目录
   cd ~/mcp_demo
   
   # 重启服务
   pm2 restart mcp-http-server
   
   # 或者如果使用npm start
   pkill -f "node src/http-server.js"
   npm start
   ```

### 方法2: 使用数据同步脚本

创建一个数据同步脚本：

```bash
#!/bin/bash
# sync-data.sh

echo "同步数据文件到CVM..."

# 上传文件
scp data/stores.xlsx ubuntu@106.53.191.184:~/mcp_demo/data/
scp data/orders.xlsx ubuntu@106.53.191.184:~/mcp_demo/data/

# 重启服务
ssh ubuntu@106.53.191.184 "cd ~/mcp_demo && pm2 restart mcp-http-server"

echo "数据同步完成！"
```

## 🧪 验证数据更新

### 1. 检查数据加载日志
```bash
# 查看服务日志
pm2 logs mcp-http-server

# 应该看到类似输出：
# 从Excel文件加载门店数据: X 个门店
# 从Excel文件加载订单数据: Y 个订单
```

### 2. 测试数据查询
```bash
# 测试订单查询
curl -X POST http://106.53.191.184:3000/tools/call \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "id": 1,
    "method": "tools/call",
    "params": {
      "name": "query_order",
      "arguments": {
        "phone": "您的测试手机号"
      }
    }
  }'

# 测试网点查询
curl -X POST http://106.53.191.184:3000/tools/call \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "id": 2,
    "method": "tools/call",
    "params": {
      "name": "query_stores",
      "arguments": {
        "latitude": 39.946613,
        "longitude": 116.370503,
        "limit": 5
      }
    }
  }'
```

### 3. 运行完整测试
```bash
# 运行测试脚本
./test-http-server.sh
```

## 📋 数据格式要求

### Excel文件要求
1. **文件格式**: .xlsx (Excel 2007+)
2. **编码**: UTF-8
3. **第一行**: 必须包含列标题
4. **数据行**: 从第二行开始

### 数据验证规则

#### 门店数据验证
- 网点名称: 不能为空
- 经度: 必须在-180到180之间
- 纬度: 必须在-90到90之间
- 评分: 必须在0到5之间
- 联系电话: 必须是有效的手机号格式

#### 订单数据验证
- 订单号: 不能为空，必须唯一
- 手机号: 必须是11位数字，以1开头
- 计费: 必须是非负数
- 租借状态: 必须是有效状态（进行中、已暂停、已完成等）

## 🚨 常见问题

### 1. 数据加载失败
```bash
# 检查文件是否存在
ls -la data/

# 检查文件权限
ls -la data/*.xlsx

# 查看错误日志
pm2 logs mcp-http-server
```

### 2. 数据格式错误
```bash
# 检查Excel文件格式
file data/stores.xlsx
file data/orders.xlsx

# 验证数据内容
head -5 data/stores.xlsx
head -5 data/orders.xlsx
```

### 3. 服务重启失败
```bash
# 检查服务状态
pm2 status

# 查看详细错误
pm2 logs mcp-http-server --lines 50

# 手动重启
pm2 stop mcp-http-server
pm2 start src/http-server.js --name mcp-http-server
```

## 🔧 数据管理工具

### 创建数据备份
```bash
#!/bin/bash
# backup-data.sh

DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="backups/$DATE"

mkdir -p $BACKUP_DIR
cp data/*.xlsx $BACKUP_DIR/

echo "数据备份完成: $BACKUP_DIR"
```

### 数据验证脚本
```bash
#!/bin/bash
# validate-data.sh

echo "验证数据文件..."

# 检查文件存在
if [ ! -f "data/stores.xlsx" ]; then
    echo "错误: stores.xlsx 文件不存在"
    exit 1
fi

if [ ! -f "data/orders.xlsx" ]; then
    echo "错误: orders.xlsx 文件不存在"
    exit 1
fi

# 检查文件大小
if [ ! -s "data/stores.xlsx" ]; then
    echo "错误: stores.xlsx 文件为空"
    exit 1
fi

if [ ! -s "data/orders.xlsx" ]; then
    echo "错误: orders.xlsx 文件为空"
    exit 1
fi

echo "数据文件验证通过！"
```

## 📞 技术支持

如果数据更新遇到问题：

1. 查看服务日志：`pm2 logs mcp-http-server`
2. 检查文件格式和内容
3. 运行数据验证脚本
4. 联系技术支持团队

## 🎯 最佳实践

1. **定期备份**: 更新数据前先备份
2. **测试验证**: 更新后立即测试功能
3. **版本控制**: 记录数据更新历史
4. **监控告警**: 设置数据异常告警
5. **文档更新**: 及时更新数据文档
