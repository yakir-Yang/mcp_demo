# 快速修复指南

## npm配置错误修复

如果您在运行安装脚本时遇到以下错误：

```
npm error `timeout` is not a valid npm option
```

### 解决方案1：使用修复脚本（推荐）

```bash
# 运行修复脚本
chmod +x fix-npm-config.sh
./fix-npm-config.sh

# 然后继续安装
./install-ubuntu.sh
```

### 解决方案2：手动修复

```bash
# 删除错误的配置
npm config delete timeout

# 设置正确的超时配置
npm config set fetch-timeout 60000
npm config set fetch-retry-mintimeout 20000
npm config set fetch-retry-maxtimeout 120000

# 验证配置
npm config list

# 继续安装
npm install
```

### 解决方案3：跳过npm配置，直接安装

```bash
# 直接安装项目依赖
npm install

# 如果遇到权限问题
npm install --unsafe-perm=true --allow-root
```

## 其他常见问题快速修复

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

### 3. 网络问题

```bash
# 设置npm镜像源
npm config set registry https://registry.npmmirror.com

# 或使用淘宝镜像
npm config set registry https://registry.npm.taobao.org
```

### 4. 依赖安装失败

```bash
# 清理缓存
npm cache clean --force
rm -rf node_modules package-lock.json

# 重新安装
npm install
```

## 验证安装

安装完成后，验证功能：

```bash
# 检查Node.js和npm版本
node --version
npm --version

# 检查项目依赖
npm list

# 测试启动
npm start
```

## 获取帮助

如果问题仍然存在：

1. 查看完整日志：`cat ~/.npm/_logs/*.log`
2. 检查系统环境：`uname -a && lsb_release -a`
3. 查看README.md中的详细故障排除部分
4. 在GitHub上提交Issue

## 联系支持

- GitHub Issues: [项目地址]
- 技术支持邮箱: [邮箱地址]
- 文档: README.md
