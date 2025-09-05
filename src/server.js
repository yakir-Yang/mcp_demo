#!/usr/bin/env node

import { Server } from '@modelcontextprotocol/sdk/server/index.js';
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js';
import {
  CallToolRequestSchema,
  ListToolsRequestSchema,
} from '@modelcontextprotocol/sdk/types.js';
import { DataManager } from './data-manager.js';
import { OrderTool, StoreTool } from './tools/index.js';

class CustomerServiceMCPServer {
  constructor() {
    this.server = new Server(
      {
        name: 'ai-customer-service-mcp-server',
        version: '1.0.0',
      },
      {
        capabilities: {
          tools: {},
        },
      }
    );

    this.dataManager = new DataManager();
    this.setupHandlers();
  }

  setupHandlers() {
    // 列出可用工具
    this.server.setRequestHandler(ListToolsRequestSchema, async () => {
      return {
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
      };
    });

    // 处理工具调用
    this.server.setRequestHandler(CallToolRequestSchema, async (request) => {
      const { name, arguments: args } = request.params;

      try {
        switch (name) {
          case 'query_order':
            return await OrderTool.execute(args, this.dataManager);
          case 'query_stores':
            return await StoreTool.execute(args, this.dataManager);
          default:
            throw new Error(`未知工具: ${name}`);
        }
      } catch (error) {
        return {
          content: [
            {
              type: 'text',
              text: `错误: ${error.message}`,
            },
          ],
          isError: true,
        };
      }
    });
  }

  async start() {
    // 初始化数据
    await this.dataManager.loadData();
    
    const transport = new StdioServerTransport();
    await this.server.connect(transport);
    
    console.error('AI智能客服MCP Server已启动');
  }
}

// 启动服务器
const server = new CustomerServiceMCPServer();
server.start().catch((error) => {
  console.error('服务器启动失败:', error);
  process.exit(1);
});
