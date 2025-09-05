# AI智能客服MCP Server

这是一个基于Model Context Protocol (MCP) 的AI智能客服系统核心服务器，提供订单查询和网点查询功能。

## 功能特性

- ✅ 支持标准MCP协议，与MCP客户端通过SSE进行通信
- ✅ 提供订单查询工具：根据手机号查询订单详情
- ✅ 提供网点查询工具：根据经纬度查询附近网点信息
- ✅ 支持Excel数据文件导入
- ✅ 内置示例数据，开箱即用
- ✅ 支持与腾讯智能体开放平台ADP集成

## 系统要求

- Node.js 18.0.0 或更高版本
- npm 或 yarn 包管理器

## 环境安装

### Ubuntu 20.04 安装指南

#### 快速安装（推荐）

我们提供了一个自动安装脚本，可以一键完成所有安装步骤：

```bash
# 下载并运行自动安装脚本
chmod +x install-ubuntu.sh
./install-ubuntu.sh
```

#### 手动安装步骤

如果您希望手动控制安装过程，可以按照以下步骤操作：

#### 1. 更新系统包

```bash
sudo apt update
sudo apt upgrade -y
```

#### 2. 安装Node.js 18.x

**方法一：使用NodeSource官方仓库（推荐）**

```bash
# 添加NodeSource仓库
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -

# 安装Node.js
sudo apt-get install -y nodejs

# 验证安装
node --version
npm --version
```

**方法二：使用snap安装**

```bash
# 安装Node.js
sudo snap install node --classic

# 验证安装
node --version
npm --version
```

**方法三：使用nvm（Node Version Manager）**

```bash
# 安装nvm
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash

# 重新加载shell配置
source ~/.bashrc

# 安装Node.js 18
nvm install 18
nvm use 18
nvm alias default 18

# 验证安装
node --version
npm --version
```

#### 3. 安装必要的系统依赖

```bash
# 安装构建工具（用于编译native模块）
sudo apt-get install -y build-essential

# 安装Python（某些npm包需要）
sudo apt-get install -y python3 python3-pip

# 安装Git（如果需要从Git仓库安装依赖）
sudo apt-get install -y git

# 安装curl和wget（用于下载文件）
sudo apt-get install -y curl wget
```

#### 4. 配置npm（可选但推荐）

```bash
# 设置npm全局安装路径（避免使用sudo）
mkdir ~/.npm-global
npm config set prefix '~/.npm-global'

# 添加到PATH环境变量
echo 'export PATH=~/.npm-global/bin:$PATH' >> ~/.bashrc
source ~/.bashrc

# 设置npm镜像源（加速下载）
npm config set registry https://registry.npmmirror.com

# 验证配置
npm config get registry
```

#### 5. 安装项目依赖

```bash
# 进入项目目录
cd /path/to/mcp_test

# 安装项目依赖
npm install

# 如果遇到权限问题，可以尝试
npm install --unsafe-perm=true --allow-root
```

#### 6. 设置启动脚本权限

```bash
# 给启动脚本添加执行权限
chmod +x start.sh
```

#### 7. 验证安装

```bash
# 检查Node.js版本
node --version

# 检查npm版本
npm --version

# 检查项目依赖
npm list

# 测试启动（可选）
npm start
```

### Docker安装（推荐用于生产环境）

如果您希望使用Docker部署，可以按照以下步骤操作：

#### 1. 安装Docker

```bash
# Ubuntu 20.04安装Docker
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release

# 添加Docker官方GPG密钥
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# 添加Docker仓库
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# 安装Docker
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io

# 启动Docker服务
sudo systemctl start docker
sudo systemctl enable docker

# 将当前用户添加到docker组（可选）
sudo usermod -aG docker $USER
```

#### 2. 创建Dockerfile

```dockerfile
FROM node:18-alpine

# 设置工作目录
WORKDIR /app

# 复制package.json和package-lock.json
COPY package*.json ./

# 安装依赖
RUN npm ci --only=production

# 复制源代码
COPY . .

# 暴露端口
EXPOSE 3000

# 启动命令
CMD ["npm", "start"]
```

#### 3. 构建和运行Docker容器

```bash
# 构建Docker镜像
docker build -t ai-customer-service-mcp .

# 运行容器
docker run -d \
  --name mcp-server \
  -p 3000:3000 \
  -v $(pwd)/data:/app/data \
  ai-customer-service-mcp

# 查看容器状态
docker ps

# 查看日志
docker logs mcp-server
```

#### 4. Docker Compose部署

**快速启动（推荐）：**

```bash
# 使用快速启动脚本
chmod +x docker-start.sh
./docker-start.sh
```

**手动部署：**

创建`docker-compose.yml`文件：

```yaml
version: '3.8'

services:
  mcp-server:
    build: .
    container_name: ai-customer-service-mcp
    ports:
      - "3000:3000"
    volumes:
      - ./data:/app/data
    environment:
      - NODE_ENV=production
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
```

启动服务：

```bash
# 启动服务
docker-compose up -d

# 查看服务状态
docker-compose ps

# 查看日志
docker-compose logs -f
```

### 其他Linux发行版

**CentOS/RHEL 8+:**

```bash
# 安装Node.js
sudo dnf module install nodejs:18

# 或使用NodeSource仓库
curl -fsSL https://rpm.nodesource.com/setup_18.x | sudo bash -
sudo dnf install -y nodejs
```

**Debian 11+:**

```bash
# 使用NodeSource仓库
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs
```

## 快速开始

### 1. 安装依赖

```bash
npm install
```

### 2. 启动服务器

```bash
# 使用启动脚本
./start.sh

# 或直接使用npm
npm start

# 开发模式（自动重启）
npm run dev
```

### 3. 配置MCP客户端

将以下配置添加到您的MCP客户端配置文件中：

```json
{
  "mcpServers": {
    "ai-customer-service": {
      "command": "node",
      "args": ["src/server.js"],
      "cwd": "/path/to/your/mcp_test",
      "env": {
        "NODE_ENV": "production"
      }
    }
  }
}
```

## 可用工具

### 1. 订单查询工具 (query_order)

根据手机号查询用户的订单详情。

**输入参数：**
- `phone` (string): 用户手机号

**返回信息：**
- 手机号
- 订单号
- 租借位置
- 租借状态
- 是否允许停止计费
- 设备ID
- 租借开始时间
- 持续时间
- 计费金额
- 支付方式

**使用示例：**
```json
{
  "name": "query_order",
  "arguments": {
    "phone": "17798762697"
  }
}
```

### 2. 网点查询工具 (query_stores)

根据经纬度查询附近的网点信息。

**输入参数：**
- `latitude` (number): 纬度 (-90 到 90)
- `longitude` (number): 经度 (-180 到 180)
- `limit` (number, 可选): 返回网点数量限制，默认10个

**返回信息：**
- 网点名称
- 状态
- 经纬度
- 详细地址
- 距离（公里）
- 营业时间
- 评分
- 联系电话
- 门店类型

**使用示例：**
```json
{
  "name": "query_stores",
  "arguments": {
    "latitude": 39.946613,
    "longitude": 116.370503,
    "limit": 5
  }
}
```

## 数据管理

### 数据文件位置

- 门店数据：`data/stores.xlsx`
- 订单数据：`data/orders.xlsx`

### 数据格式

#### 门店数据格式
| 字段名 | 类型 | 说明 |
|--------|------|------|
| 网点名称 | string | 门店名称 |
| 状态 | string | 营业状态 |
| 经纬度 | string | 坐标信息 |
| 省份 | string | 所属省份 |
| 城市 | string | 所属城市 |
| 区/县 | string | 所属区县 |
| 详细地址 | string | 具体地址 |
| 经度 | number | 经度值 |
| 纬度 | number | 纬度值 |
| 门店类型 | string | 门店类型 |
| 开业时间 | string | 开业日期 |
| 营业时间 | string | 营业时间段 |
| 评分 | number | 门店评分 |
| 联系电话 | string | 联系电话 |

#### 订单数据格式
| 字段名 | 类型 | 说明 |
|--------|------|------|
| 订单号 | string | 唯一订单标识 |
| 用户id | string | 用户标识 |
| 手机号 | string | 用户手机号 |
| 设备id | string | 设备标识 |
| 租借位置 | string | 租借门店 |
| 租借开始时间 | string | 开始时间 |
| 退还时间 | string | 退还时间 |
| 持续时间/分钟 | number | 使用时长 |
| 归还网点 | string | 归还门店 |
| 计费 | number | 费用金额 |
| 租借状态 | string | 订单状态 |
| 支付方式 | string | 支付方式 |

### 更新数据

1. 替换 `data/` 目录下的Excel文件
2. 重启MCP Server
3. 数据将自动重新加载

## 项目结构

```
mcp_test/
├── src/
│   ├── server.js              # MCP服务器主文件
│   ├── data-manager.js        # 数据管理器
│   └── tools/
│       ├── index.js           # 工具导出
│       ├── order-tool.js      # 订单查询工具
│       └── store-tool.js      # 网点查询工具
├── data/
│   ├── stores.xlsx            # 门店数据
│   └── orders.xlsx            # 订单数据
├── package.json               # 项目配置
├── mcp-config.json           # MCP配置示例
├── start.sh                  # 启动脚本
└── README.md                 # 项目文档
```

## 开发说明

### 添加新工具

1. 在 `src/tools/` 目录下创建新的工具文件
2. 实现工具类，包含静态方法 `execute(args, dataManager)`
3. 在 `src/tools/index.js` 中导出新工具
4. 在 `src/server.js` 中注册新工具

### 自定义数据源

修改 `src/data-manager.js` 中的 `loadStoresData()` 和 `loadOrdersData()` 方法，支持其他数据源（如数据库、API等）。

## 错误处理

服务器包含完整的错误处理机制：

- 参数验证
- 数据格式检查
- 异常捕获和报告
- 友好的错误消息

## 性能优化

- 数据预加载和缓存
- 高效的距离计算算法
- 内存优化的数据结构

## 故障排除

### 常见问题及解决方案

#### 1. Node.js安装问题

**问题：** `node: command not found`

**解决方案：**
```bash
# 检查Node.js是否已安装
which node

# 如果未安装，重新安装
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs

# 检查PATH环境变量
echo $PATH
```

#### 2. npm配置问题

**问题：** `npm error 'timeout' is not a valid npm option`

**解决方案：**
```bash
# 使用修复脚本
chmod +x fix-npm-config.sh
./fix-npm-config.sh

# 或手动修复
npm config delete timeout
npm config set fetch-timeout 60000
npm config set fetch-retry-mintimeout 20000
npm config set fetch-retry-maxtimeout 120000
```

#### 3. npm权限问题

**问题：** `EACCES: permission denied`

**解决方案：**
```bash
# 方法1：使用npm配置全局路径
mkdir ~/.npm-global
npm config set prefix '~/.npm-global'
echo 'export PATH=~/.npm-global/bin:$PATH' >> ~/.bashrc
source ~/.bashrc

# 方法2：使用sudo（不推荐）
sudo npm install -g

# 方法3：使用nvm管理Node.js版本
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
source ~/.bashrc
nvm install 18
nvm use 18
```

#### 4. 依赖安装失败

**问题：** `npm ERR! peer dep missing`

**解决方案：**
```bash
# 清理npm缓存
npm cache clean --force

# 删除node_modules和package-lock.json
rm -rf node_modules package-lock.json

# 重新安装
npm install

# 如果仍有问题，尝试使用yarn
npm install -g yarn
yarn install
```

#### 5. 构建工具缺失

**问题：** `gyp ERR! build error`

**解决方案：**
```bash
# 安装构建工具
sudo apt-get install -y build-essential

# 安装Python开发工具
sudo apt-get install -y python3-dev

# 安装其他可能需要的工具
sudo apt-get install -y libssl-dev libffi-dev
```

#### 6. 网络连接问题

**问题：** `npm ERR! network timeout`

**解决方案：**
```bash
# 设置npm镜像源
npm config set registry https://registry.npmmirror.com

# 或使用淘宝镜像
npm config set registry https://registry.npm.taobao.org

# 增加超时时间
npm config set fetch-timeout 60000
npm config set fetch-retry-mintimeout 20000
npm config set fetch-retry-maxtimeout 120000

# 使用代理（如果需要）
npm config set proxy http://proxy-server:port
npm config set https-proxy http://proxy-server:port
```

#### 7. 端口占用问题

**问题：** `EADDRINUSE: address already in use`

**解决方案：**
```bash
# 查找占用端口的进程
sudo netstat -tulpn | grep :3000

# 或使用lsof
sudo lsof -i :3000

# 杀死占用端口的进程
sudo kill -9 <PID>

# 或使用不同的端口
PORT=3001 npm start
```

#### 8. 内存不足问题

**问题：** `JavaScript heap out of memory`

**解决方案：**
```bash
# 增加Node.js内存限制
export NODE_OPTIONS="--max-old-space-size=4096"

# 或在启动时指定
node --max-old-space-size=4096 src/server.js

# 检查系统内存
free -h
```

#### 9. 文件权限问题

**问题：** `Permission denied`

**解决方案：**
```bash
# 检查文件权限
ls -la start.sh

# 添加执行权限
chmod +x start.sh

# 检查目录权限
ls -la

# 修改目录权限（如果需要）
chmod 755 /path/to/mcp_test
```

### 日志和调试

#### 启用详细日志

```bash
# 设置调试模式
export DEBUG=*
npm start

# 或使用Node.js调试模式
node --inspect src/server.js
```

#### 检查系统资源

```bash
# 检查CPU使用率
top

# 检查内存使用
free -h

# 检查磁盘空间
df -h

# 检查网络连接
netstat -tulpn
```

### 获取帮助

如果遇到其他问题，可以：

1. 查看项目日志文件
2. 检查系统日志：`journalctl -u your-service`
3. 在GitHub上提交Issue
4. 联系技术支持团队

## 许可证

MIT License

## 支持

如有问题或建议，请提交Issue或联系开发团队。
