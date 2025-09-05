#!/usr/bin/env node

// AI智能客服MCP Server 快速测试脚本
// 用于验证基本功能是否正常

import { DataManager } from './src/data-manager.js';
import { OrderTool, StoreTool } from './src/tools/index.js';

// 颜色定义
const colors = {
    reset: '\x1b[0m',
    red: '\x1b[31m',
    green: '\x1b[32m',
    yellow: '\x1b[33m',
    blue: '\x1b[34m',
    purple: '\x1b[35m'
};

// 日志函数
function log(color, prefix, message) {
    console.log(`${colors[color]}[${prefix}]${colors.reset} ${message}`);
}

function logInfo(message) {
    log('blue', 'INFO', message);
}

function logSuccess(message) {
    log('green', 'SUCCESS', message);
}

function logWarning(message) {
    log('yellow', 'WARNING', message);
}

function logError(message) {
    log('red', 'ERROR', message);
}

function logTest(message) {
    log('purple', 'TEST', message);
}

// 测试配置
const TEST_CONFIG = {
    phone: '17798762697',
    latitude: 39.946613,
    longitude: 116.370503,
    limit: 3
};

// 测试结果统计
let totalTests = 0;
let passedTests = 0;

// 运行测试
async function runTest(testName, testFunction) {
    totalTests++;
    logTest(`测试: ${testName}`);
    
    try {
        const result = await testFunction();
        if (result) {
            passedTests++;
            logSuccess(`${testName} 测试通过`);
        } else {
            logError(`${testName} 测试失败`);
        }
    } catch (error) {
        logError(`${testName} 测试异常: ${error.message}`);
    }
    
    console.log();
}

// 测试数据管理器
async function testDataManager() {
    logInfo('初始化数据管理器...');
    const dataManager = new DataManager();
    await dataManager.loadData();
    
    if (dataManager.stores.length > 0 && dataManager.orders.length > 0) {
        logInfo(`数据加载成功: ${dataManager.stores.length} 个门店, ${dataManager.orders.length} 个订单`);
        return true;
    } else {
        logError('数据加载失败');
        return false;
    }
}

// 测试订单查询工具
async function testOrderTool() {
    logInfo('测试订单查询工具...');
    const dataManager = new DataManager();
    await dataManager.loadData();
    
    const result = await OrderTool.execute({ phone: TEST_CONFIG.phone }, dataManager);
    
    if (result && result.content && result.content[0] && result.content[0].text) {
        const text = result.content[0].text;
        if (text.includes(TEST_CONFIG.phone)) {
            logInfo('订单查询结果:');
            console.log(text);
            return true;
        }
    }
    
    logError('订单查询失败');
    return false;
}

// 测试网点查询工具
async function testStoreTool() {
    logInfo('测试网点查询工具...');
    const dataManager = new DataManager();
    await dataManager.loadData();
    
    const result = await StoreTool.execute({
        latitude: TEST_CONFIG.latitude,
        longitude: TEST_CONFIG.longitude,
        limit: TEST_CONFIG.limit
    }, dataManager);
    
    if (result && result.content && result.content[0] && result.content[0].text) {
        const text = result.content[0].text;
        if (text.includes('网点名称')) {
            logInfo('网点查询结果:');
            console.log(text);
            return true;
        }
    }
    
    logError('网点查询失败');
    return false;
}

// 测试错误处理
async function testErrorHandling() {
    logInfo('测试错误处理...');
    const dataManager = new DataManager();
    await dataManager.loadData();
    
    try {
        // 测试无效手机号
        const result = await OrderTool.execute({ phone: '123' }, dataManager);
        if (result && result.isError) {
            logInfo('错误处理正常');
            return true;
        }
    } catch (error) {
        if (error.message.includes('手机号格式不正确')) {
            logInfo('错误处理正常');
            return true;
        }
    }
    
    logWarning('错误处理测试未达到预期');
    return false;
}

// 测试数据查询功能
async function testDataQueries() {
    logInfo('测试数据查询功能...');
    const dataManager = new DataManager();
    await dataManager.loadData();
    
    // 测试订单查询
    const orders = dataManager.queryOrdersByPhone(TEST_CONFIG.phone);
    if (orders.length > 0) {
        logInfo(`找到 ${orders.length} 个订单`);
    }
    
    // 测试网点查询
    const stores = dataManager.queryStoresByLocation(
        TEST_CONFIG.latitude, 
        TEST_CONFIG.longitude, 
        TEST_CONFIG.limit
    );
    if (stores.length > 0) {
        logInfo(`找到 ${stores.length} 个附近网点`);
        return true;
    }
    
    return false;
}

// 生成测试报告
function generateReport() {
    const failedTests = totalTests - passedTests;
    const successRate = Math.round((passedTests / totalTests) * 100);
    
    console.log();
    console.log('==========================================');
    console.log('  测试报告');
    console.log('==========================================');
    console.log(`总测试数: ${totalTests}`);
    console.log(`通过测试: ${passedTests}`);
    console.log(`失败测试: ${failedTests}`);
    console.log(`成功率: ${successRate}%`);
    console.log();
    
    if (failedTests === 0) {
        logSuccess('🎉 所有测试通过！MCP Server功能正常。');
    } else {
        logWarning(`⚠️  有 ${failedTests} 个测试失败，请检查日志。`);
    }
}

// 主函数
async function main() {
    console.log();
    console.log('==========================================');
    console.log('  AI智能客服MCP Server 快速测试');
    console.log('==========================================');
    console.log();
    
    // 运行所有测试
    await runTest('数据管理器', testDataManager);
    await runTest('数据查询功能', testDataQueries);
    await runTest('订单查询工具', testOrderTool);
    await runTest('网点查询工具', testStoreTool);
    await runTest('错误处理', testErrorHandling);
    
    // 生成报告
    generateReport();
    
    // 显示使用说明
    console.log();
    logInfo('下一步操作:');
    console.log('1. 启动MCP Server: npm start');
    console.log('2. 运行完整测试: ./test-mcp-server.sh');
    console.log('3. 查看使用示例: cat example-usage.md');
    console.log();
}

// 运行主函数
main().catch(error => {
    logError(`测试执行失败: ${error.message}`);
    process.exit(1);
});
