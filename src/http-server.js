#!/usr/bin/env node

import express from 'express';
import cors from 'cors';
import { DataManager } from './data-manager.js';
import { OrderTool, StoreTool } from './tools/index.js';

class CustomerServiceHTTPServer {
  constructor() {
    this.app = express();
    this.port = process.env.PORT || 3000;
    this.dataManager = new DataManager();
    this.setupMiddleware();
    this.setupRoutes();
  }

  setupMiddleware() {
    // 启用CORS，支持腾讯云ADP
    this.app.use(cors({
      origin: ['https://adp.tencent.com', 'https://*.tencent.com', '*'],
      credentials: true,
      methods: ['GET', 'POST', 'OPTIONS'],
      allowedHeaders: ['Content-Type', 'Authorization', 'X-Requested-With']
    }));
    
    // 解析JSON请求体
    this.app.use(express.json());
    
    // 请求日志
    this.app.use((req, res, next) => {
      console.log(`${new Date().toISOString()} - ${req.method} ${req.path}`);
      next();
    });
  }

  setupRoutes() {
    // 健康检查端点
    this.app.get('/health', (req, res) => {
      res.json({
        status: 'healthy',
        timestamp: new Date().toISOString(),
        version: '1.0.0',
        services: {
          dataManager: this.dataManager ? 'ready' : 'not ready',
          stores: this.dataManager?.stores?.length || 0,
          orders: this.dataManager?.orders?.length || 0
        }
      });
    });

    // MCP协议 - 初始化端点
    this.app.post('/mcp/initialize', (req, res) => {
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

    // MCP协议 - SSE端点（腾讯云ADP需要）
    this.app.get('/sse', (req, res) => {
      console.log('SSE连接请求来自:', req.ip, req.get('User-Agent'));
      console.log('请求头:', JSON.stringify(req.headers, null, 2));
      
      // 检查是否是腾讯云ADP请求
      const isTencentADP = req.get('User-Agent') === 'TencentADP/1.0';
      const acceptHeader = req.get('Accept');
      
      console.log('是否为腾讯云ADP请求:', isTencentADP);
      console.log('Accept头:', acceptHeader);
      
      // 根据Accept头决定响应类型
      if (acceptHeader && acceptHeader.includes('application/json')) {
        // 腾讯云ADP可能期望JSON响应而不是SSE
        console.log('检测到JSON Accept头，返回JSON响应');
        
        res.json({
          status: 'connected',
          protocol: 'mcp',
          version: '2024-11-05',
          server: 'ai-customer-service-mcp-server',
          timestamp: new Date().toISOString(),
          capabilities: {
            tools: true,
            sse: true
          },
          tools: ['query_order', 'query_stores'],
          endpoints: {
            health: '/health',
            tools_list: '/tools/list',
            tools_call: '/tools/call'
          }
        });
        return;
      }
      
      // 标准SSE响应
      res.writeHead(200, {
        'Content-Type': 'text/event-stream; charset=utf-8',
        'Cache-Control': 'no-cache, no-store, must-revalidate, private',
        'Pragma': 'no-cache',
        'Expires': '0',
        'Connection': 'keep-alive',
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Headers': 'Cache-Control, Content-Type, Authorization, Accept',
        'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
        'Access-Control-Allow-Credentials': 'true',
        'Access-Control-Expose-Headers': 'Content-Type',
        'X-Accel-Buffering': 'no',
        'Transfer-Encoding': 'chunked',
        'Keep-Alive': 'timeout=300, max=1000'
      });

      // 立即发送连接确认
      try {
        // 发送SSE注释（保持连接活跃）
        res.write(': SSE连接已建立\n');
        
        // 发送连接事件
        res.write('event: connected\n');
        res.write('data: {"status":"connected","timestamp":"' + new Date().toISOString() + '","server":"ai-customer-service-mcp-server"}\n\n');
        
        // 发送MCP协议信息
        res.write('event: mcp-info\n');
        res.write('data: {"protocol":"mcp","version":"2024-11-05","capabilities":{"tools":true},"server":"ai-customer-service-mcp-server","version":"1.0.0"}\n\n');
        
        // 发送工具信息
        res.write('event: tools-available\n');
        res.write('data: {"tools":["query_order","query_stores"],"count":2}\n\n');
        
        console.log('SSE连接已建立，初始消息已发送');
      } catch (err) {
        console.error('SSE写入错误:', err);
        return;
      }

      // 定期发送心跳（每60秒）
      const heartbeat = setInterval(() => {
        try {
          res.write('event: heartbeat\n');
          res.write('data: {"timestamp":"' + new Date().toISOString() + '","status":"alive","uptime":' + process.uptime() + '}\n\n');
          console.log('SSE心跳已发送');
        } catch (err) {
          console.error('SSE心跳发送失败:', err);
          clearInterval(heartbeat);
        }
      }, 60000);

      // 连接管理
      let isConnected = true;
      
      const cleanup = () => {
        if (isConnected) {
          isConnected = false;
          clearInterval(heartbeat);
          console.log('SSE连接已清理');
        }
      };

      // 处理客户端断开
      req.on('close', () => {
        console.log('SSE客户端主动断开连接');
        cleanup();
      });
      
      req.on('error', (err) => {
        console.error('SSE请求错误:', err.message);
        cleanup();
      });
      
      res.on('error', (err) => {
        console.error('SSE响应错误:', err.message);
        cleanup();
      });

      // 处理客户端数据
      req.on('data', (chunk) => {
        console.log('收到SSE客户端数据:', chunk.toString());
      });

      // 设置连接超时（15分钟）
      req.setTimeout(900000, () => {
        console.log('SSE连接超时，主动断开');
        cleanup();
        try {
          res.end();
        } catch (err) {
          console.error('SSE结束错误:', err);
        }
      });

      console.log('SSE连接建立完成');
    });

    // 工具列表端点
    this.app.post('/tools/list', (req, res) => {
      try {
        const response = {
          jsonrpc: '2.0',
          id: req.body.id || 1,
          result: {
            tools: [
              {
                name: 'query_order',
                description: '根据手机号查询订单详情',
                inputSchema: {
                  type: 'object',
                  properties: {
                    phone: {
                      type: 'string',
                      description: '用户手机号',
                    },
                  },
                  required: ['phone'],
                },
              },
              {
                name: 'query_stores',
                description: '根据经纬度查询附近网点信息',
                inputSchema: {
                  type: 'object',
                  properties: {
                    latitude: {
                      type: 'number',
                      description: '纬度',
                    },
                    longitude: {
                      type: 'number',
                      description: '经度',
                    },
                    limit: {
                      type: 'number',
                      description: '返回网点数量限制',
                      default: 10,
                    },
                  },
                  required: ['latitude', 'longitude'],
                },
              },
            ],
          },
        };
        res.json(response);
      } catch (error) {
        res.status(500).json({
          jsonrpc: '2.0',
          id: req.body.id || 1,
          error: {
            code: -32603,
            message: 'Internal error',
            data: error.message,
          },
        });
      }
    });

    // 工具调用端点
    this.app.post('/tools/call', async (req, res) => {
      try {
        const { name, arguments: args } = req.body.params || req.body;
        
        if (!name) {
          return res.status(400).json({
            jsonrpc: '2.0',
            id: req.body.id || 1,
            error: {
              code: -32602,
              message: 'Invalid params',
              data: 'Missing tool name',
            },
          });
        }

        let result;
        switch (name) {
          case 'query_order':
            result = await OrderTool.execute(args, this.dataManager);
            break;
          case 'query_stores':
            result = await StoreTool.execute(args, this.dataManager);
            break;
          default:
            throw new Error(`未知工具: ${name}`);
        }

        res.json({
          jsonrpc: '2.0',
          id: req.body.id || 1,
          result: result,
        });
      } catch (error) {
        res.status(500).json({
          jsonrpc: '2.0',
          id: req.body.id || 1,
          result: {
            content: [
              {
                type: 'text',
                text: `错误: ${error.message}`,
              },
            ],
            isError: true,
          },
        });
      }
    });

    // 兼容性端点 - 直接调用工具
    this.app.post('/query_order', async (req, res) => {
      try {
        const result = await OrderTool.execute(req.body, this.dataManager);
        res.json(result);
      } catch (error) {
        res.status(500).json({
          error: error.message,
        });
      }
    });

    this.app.post('/query_stores', async (req, res) => {
      try {
        const result = await StoreTool.execute(req.body, this.dataManager);
        res.json(result);
      } catch (error) {
        res.status(500).json({
          error: error.message,
        });
      }
    });

    // 根路径
    this.app.get('/', (req, res) => {
      res.json({
        name: 'AI智能客服MCP Server',
        version: '1.0.0',
        description: '提供订单查询和网点查询功能的MCP服务器',
        endpoints: {
          health: '/health',
          tools_list: '/tools/list',
          tools_call: '/tools/call',
          query_order: '/query_order',
          query_stores: '/query_stores'
        },
        tools: ['query_order', 'query_stores']
      });
    });

    // 处理OPTIONS预检请求
    this.app.options('*', (req, res) => {
      res.header('Access-Control-Allow-Origin', '*');
      res.header('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
      res.header('Access-Control-Allow-Headers', 'Origin, X-Requested-With, Content-Type, Accept, Authorization');
      res.header('Access-Control-Max-Age', '86400');
      res.sendStatus(200);
    });

    // 404处理
    this.app.use('*', (req, res) => {
      res.status(404).json({
        error: 'Not Found',
        message: `路径 ${req.originalUrl} 不存在`,
        available_endpoints: [
          'GET /',
          'GET /health',
          'GET /sse',
          'POST /mcp/initialize',
          'POST /tools/list',
          'POST /tools/call',
          'POST /query_order',
          'POST /query_stores'
        ]
      });
    });

    // 错误处理中间件
    this.app.use((error, req, res, next) => {
      console.error('服务器错误:', error);
      res.status(500).json({
        error: 'Internal Server Error',
        message: error.message,
      });
    });
  }

  async start() {
    try {
      // 初始化数据
      await this.dataManager.loadData();
      
      // 启动HTTP服务器
      this.app.listen(this.port, '0.0.0.0', () => {
        console.log(`AI智能客服MCP Server已启动`);
        console.log(`服务器地址: http://0.0.0.0:${this.port}`);
        console.log(`健康检查: http://0.0.0.0:${this.port}/health`);
        console.log(`工具列表: http://0.0.0.0:${this.port}/tools/list`);
        console.log(`数据统计: ${this.dataManager.stores.length} 个门店, ${this.dataManager.orders.length} 个订单`);
      });
    } catch (error) {
      console.error('服务器启动失败:', error);
      process.exit(1);
    }
  }
}

// 启动服务器
const server = new CustomerServiceHTTPServer();
server.start();
