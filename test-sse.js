#!/usr/bin/env node

// SSE连接测试脚本 (Node.js版本)
// 提供详细的SSE连接分析和测试

import { EventSource } from 'eventsource';
import fetch from 'node-fetch';

// 颜色定义
const colors = {
    reset: '\x1b[0m',
    red: '\x1b[31m',
    green: '\x1b[32m',
    yellow: '\x1b[33m',
    blue: '\x1b[34m',
    purple: '\x1b[35m',
    cyan: '\x1b[36m'
};

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

function logSSE(message) {
    log('cyan', 'SSE', message);
}

// 配置
const config = {
    serverUrl: 'http://106.53.191.184:3000',
    testDuration: 30000, // 30秒
    verbose: process.argv.includes('--verbose') || process.argv.includes('-v')
};

// 测试结果统计
const testResults = {
    total: 0,
    passed: 0,
    failed: 0,
    messages: [],
    errors: []
};

// 测试SSE端点响应头
async function testSSEHeaders() {
    logTest('测试SSE端点响应头...');
    testResults.total++;
    
    try {
        const response = await fetch(`${config.serverUrl}/sse`, {
            method: 'HEAD',
            headers: {
                'User-Agent': 'TencentADP/1.0',
                'Accept': 'text/event-stream',
                'Cache-Control': 'no-cache'
            }
        });
        
        if (response.ok) {
            logSuccess('SSE端点可访问');
            
            // 检查关键响应头
            const contentType = response.headers.get('content-type');
            const cacheControl = response.headers.get('cache-control');
            const connection = response.headers.get('connection');
            const corsOrigin = response.headers.get('access-control-allow-origin');
            
            if (contentType && contentType.includes('text/event-stream')) {
                logSuccess('Content-Type正确: text/event-stream');
            } else {
                logWarning(`Content-Type可能不正确: ${contentType}`);
            }
            
            if (cacheControl && cacheControl.includes('no-cache')) {
                logSuccess('Cache-Control正确: no-cache');
            } else {
                logWarning(`Cache-Control可能不正确: ${cacheControl}`);
            }
            
            if (connection && connection.includes('keep-alive')) {
                logSuccess('Connection正确: keep-alive');
            } else {
                logWarning(`Connection可能不正确: ${connection}`);
            }
            
            if (corsOrigin) {
                logSuccess('CORS配置正确');
            } else {
                logWarning('CORS配置可能有问题');
            }
            
            testResults.passed++;
            return true;
        } else {
            logError(`SSE端点返回错误: ${response.status} ${response.statusText}`);
            testResults.failed++;
            return false;
        }
    } catch (error) {
        logError(`SSE端点测试失败: ${error.message}`);
        testResults.failed++;
        return false;
    }
}

// 测试SSE数据流
async function testSSEStream() {
    logTest(`测试SSE数据流 (${config.testDuration/1000}秒)...`);
    testResults.total++;
    
    return new Promise((resolve) => {
        const startTime = Date.now();
        let messageCount = 0;
        let eventTypes = new Set();
        let lastMessageTime = 0;
        
        try {
            const eventSource = new EventSource(`${config.serverUrl}/sse`, {
                headers: {
                    'User-Agent': 'TencentADP/1.0',
                    'Accept': 'text/event-stream',
                    'Cache-Control': 'no-cache'
                }
            });
            
            eventSource.onopen = () => {
                logSuccess('SSE连接已建立');
            };
            
            eventSource.onmessage = (event) => {
                messageCount++;
                eventTypes.add('message');
                lastMessageTime = Date.now();
                
                if (config.verbose) {
                    logSSE(`收到消息: ${event.data}`);
                }
                
                testResults.messages.push({
                    type: 'message',
                    data: event.data,
                    timestamp: new Date().toISOString()
                });
            };
            
            eventSource.addEventListener('connected', (event) => {
                messageCount++;
                eventTypes.add('connected');
                lastMessageTime = Date.now();
                
                logSSE('收到连接事件');
                testResults.messages.push({
                    type: 'connected',
                    data: event.data,
                    timestamp: new Date().toISOString()
                });
            });
            
            eventSource.addEventListener('mcp-info', (event) => {
                messageCount++;
                eventTypes.add('mcp-info');
                lastMessageTime = Date.now();
                
                logSSE('收到MCP信息事件');
                testResults.messages.push({
                    type: 'mcp-info',
                    data: event.data,
                    timestamp: new Date().toISOString()
                });
            });
            
            eventSource.addEventListener('heartbeat', (event) => {
                messageCount++;
                eventTypes.add('heartbeat');
                lastMessageTime = Date.now();
                
                if (config.verbose) {
                    logSSE('收到心跳事件');
                }
                
                testResults.messages.push({
                    type: 'heartbeat',
                    data: event.data,
                    timestamp: new Date().toISOString()
                });
            });
            
            eventSource.addEventListener('tools-available', (event) => {
                messageCount++;
                eventTypes.add('tools-available');
                lastMessageTime = Date.now();
                
                logSSE('收到工具信息事件');
                testResults.messages.push({
                    type: 'tools-available',
                    data: event.data,
                    timestamp: new Date().toISOString()
                });
            });
            
            eventSource.onerror = (error) => {
                logError(`SSE连接错误: ${error.message || 'Unknown error'}`);
                testResults.errors.push({
                    type: 'error',
                    message: error.message || 'Unknown error',
                    timestamp: new Date().toISOString()
                });
            };
            
            // 设置测试超时
            setTimeout(() => {
                eventSource.close();
                
                const duration = Date.now() - startTime;
                logSuccess(`SSE测试完成，持续 ${duration/1000} 秒，收到 ${messageCount} 条消息`);
                
                // 分析消息
                analyzeMessages(eventTypes, messageCount, duration);
                
                if (messageCount > 0) {
                    testResults.passed++;
                } else {
                    testResults.failed++;
                }
                
                resolve(messageCount > 0);
            }, config.testDuration);
            
        } catch (error) {
            logError(`SSE流测试失败: ${error.message}`);
            testResults.failed++;
            resolve(false);
        }
    });
}

// 分析消息
function analyzeMessages(eventTypes, messageCount, duration) {
    logTest('分析SSE消息...');
    
    logInfo(`消息统计:`);
    logInfo(`  总消息数: ${messageCount}`);
    logInfo(`  事件类型: ${Array.from(eventTypes).join(', ')}`);
    logInfo(`  平均频率: ${(messageCount / (duration / 1000)).toFixed(2)} 消息/秒`);
    
    // 统计各类型消息数量
    const messageStats = {};
    testResults.messages.forEach(msg => {
        messageStats[msg.type] = (messageStats[msg.type] || 0) + 1;
    });
    
    Object.entries(messageStats).forEach(([type, count]) => {
        logInfo(`  ${type}: ${count} 条`);
    });
    
    // 检查消息格式
    const validMessages = testResults.messages.filter(msg => msg.data && msg.data.trim());
    const validRatio = messageCount > 0 ? (validMessages.length / messageCount * 100).toFixed(1) : 0;
    
    logInfo(`有效消息比例: ${validRatio}%`);
    
    if (validRatio > 80) {
        logSuccess('SSE消息格式正确');
    } else {
        logWarning('SSE消息格式可能有问题');
    }
}

// 测试连接稳定性
async function testConnectionStability() {
    logTest('测试连接稳定性...');
    testResults.total++;
    
    const testCount = 5;
    let successCount = 0;
    
    for (let i = 1; i <= testCount; i++) {
        logInfo(`稳定性测试 ${i}/${testCount}...`);
        
        try {
            const eventSource = new EventSource(`${config.serverUrl}/sse`);
            let messageReceived = false;
            
            const timeout = setTimeout(() => {
                eventSource.close();
            }, 5000);
            
            eventSource.onmessage = () => {
                messageReceived = true;
            };
            
            eventSource.onopen = () => {
                setTimeout(() => {
                    eventSource.close();
                    clearTimeout(timeout);
                    
                    if (messageReceived) {
                        logSuccess(`测试 ${i} 成功`);
                        successCount++;
                    } else {
                        logWarning(`测试 ${i} 失败，没有收到消息`);
                    }
                }, 2000);
            };
            
            eventSource.onerror = () => {
                clearTimeout(timeout);
                logWarning(`测试 ${i} 失败，连接错误`);
            };
            
        } catch (error) {
            logWarning(`测试 ${i} 失败: ${error.message}`);
        }
        
        // 等待1秒再进行下一次测试
        await new Promise(resolve => setTimeout(resolve, 1000));
    }
    
    const successRate = (successCount / testCount * 100).toFixed(1);
    logInfo(`稳定性测试结果: ${successCount}/${testCount} 成功 (${successRate}%)`);
    
    if (successRate >= 80) {
        logSuccess('SSE连接稳定性良好');
        testResults.passed++;
        return true;
    } else {
        logWarning('SSE连接稳定性需要改进');
        testResults.failed++;
        return false;
    }
}

// 生成测试报告
function generateReport() {
    console.log();
    console.log(`${colors.blue}==========================================`);
    console.log('  SSE连接测试报告');
    console.log('==========================================');
    console.log(`${colors.reset}`);
    console.log(`服务器地址: ${colors.blue}${config.serverUrl}${colors.reset}`);
    console.log(`测试持续时间: ${colors.blue}${config.testDuration/1000}秒${colors.reset}`);
    console.log(`总测试数: ${colors.blue}${testResults.total}${colors.reset}`);
    console.log(`通过测试: ${colors.green}${testResults.passed}${colors.reset}`);
    console.log(`失败测试: ${colors.red}${testResults.failed}${colors.reset}`);
    console.log(`成功率: ${colors.blue}${testResults.total > 0 ? (testResults.passed / testResults.total * 100).toFixed(1) : 0}%${colors.reset}`);
    console.log();
    
    if (testResults.failed === 0) {
        logSuccess('🎉 所有SSE测试通过！服务器与腾讯云ADP兼容。');
        console.log();
        console.log(`${colors.blue}腾讯云ADP配置建议:${colors.reset}`);
        console.log(`- 服务器URL: ${config.serverUrl}`);
        console.log('- 超时时间: 120秒');
        console.log('- SSE读取超时: 600秒');
        console.log('- 支持的事件: connected, mcp-info, heartbeat, tools-available');
    } else {
        logWarning(`⚠️  有 ${testResults.failed} 个测试失败，请检查服务器配置。`);
        console.log();
        console.log(`${colors.blue}故障排除建议:${colors.reset}`);
        console.log('1. 检查服务器是否正常运行');
        console.log('2. 检查SSE端点实现');
        console.log('3. 检查CORS配置');
        console.log('4. 查看服务器日志');
        console.log('5. 检查网络连接');
    }
    
    if (testResults.errors.length > 0) {
        console.log();
        console.log(`${colors.red}错误详情:${colors.reset}`);
        testResults.errors.forEach((error, index) => {
            console.log(`  ${index + 1}. ${error.type}: ${error.message}`);
        });
    }
}

// 主函数
async function main() {
    console.log(`${colors.blue}`);
    console.log('==========================================');
    console.log('  SSE连接测试 (Node.js版本)');
    console.log(`  服务器: ${config.serverUrl}`);
    console.log(`  持续时间: ${config.testDuration/1000}秒`);
    console.log('==========================================');
    console.log(`${colors.reset}`);
    
    console.log();
    logInfo('开始执行SSE测试...');
    console.log();
    
    // 执行测试
    await testSSEHeaders();
    console.log();
    
    await testSSEStream();
    console.log();
    
    await testConnectionStability();
    console.log();
    
    // 生成报告
    generateReport();
}

// 显示帮助信息
function showHelp() {
    console.log('SSE连接测试脚本 (Node.js版本)');
    console.log();
    console.log('用法: node test-sse.js [选项]');
    console.log();
    console.log('选项:');
    console.log('  -v, --verbose    详细输出模式');
    console.log('  -h, --help       显示帮助信息');
    console.log();
    console.log('示例:');
    console.log('  node test-sse.js                # 基本测试');
    console.log('  node test-sse.js --verbose      # 详细输出');
}

// 检查命令行参数
if (process.argv.includes('--help') || process.argv.includes('-h')) {
    showHelp();
    process.exit(0);
}

// 运行测试
main().catch(error => {
    logError(`测试执行失败: ${error.message}`);
    process.exit(1);
});
