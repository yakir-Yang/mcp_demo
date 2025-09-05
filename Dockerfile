# AI智能客服MCP Server Docker镜像
FROM node:18-alpine

# 设置工作目录
WORKDIR /app

# 安装必要的系统依赖
RUN apk add --no-cache \
    curl \
    bash \
    && rm -rf /var/cache/apk/*

# 复制package.json和package-lock.json
COPY package*.json ./

# 安装依赖
RUN npm ci --only=production && npm cache clean --force

# 复制源代码
COPY . .

# 创建数据目录
RUN mkdir -p /app/data

# 设置文件权限
RUN chmod +x start.sh

# 创建非root用户
RUN addgroup -g 1001 -S nodejs && \
    adduser -S mcpuser -u 1001

# 更改文件所有权
RUN chown -R mcpuser:nodejs /app
USER mcpuser

# 暴露端口
EXPOSE 3000

# 健康检查
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:3000/health || exit 1

# 启动命令
CMD ["npm", "start"]
