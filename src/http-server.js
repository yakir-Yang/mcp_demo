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
      // 设置SSE响应头
      res.writeHead(200, {
        'Content-Type': 'text/event-stream',
        'Cache-Control': 'no-cache',
        'Connection': 'keep-alive',
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Headers': 'Cache-Control'
      });

      // 发送初始连接确认
      res.write('data: {"type":"connection","status":"connected","timestamp":"' + new Date().toISOString() + '"}\n\n');

      // 定期发送心跳
      const heartbeat = setInterval(() => {
        res.write('data: {"type":"heartbeat","timestamp":"' + new Date().toISOString() + '"}\n\n');
      }, 30000); // 每30秒发送一次心跳

      // 处理客户端断开连接
      req.on('close', () => {
        clearInterval(heartbeat);
        console.log('SSE客户端断开连接');
      });

      req.on('error', (err) => {
        clearInterval(heartbeat);
        console.error('SSE连接错误:', err);
      });
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

    // 404处理
    this.app.use('*', (req, res) => {
      res.status(404).json({
        error: 'Not Found',
        message: `路径 ${req.originalUrl} 不存在`,
        available_endpoints: [
          'GET /',
          'GET /health',
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
