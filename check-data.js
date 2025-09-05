#!/usr/bin/env node

// 数据检查脚本
// 用于检查Excel文件内容和数据格式

import { DataManager } from './src/data-manager.js';
import XLSX from 'xlsx';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// 颜色定义
const colors = {
    reset: '\x1b[0m',
    red: '\x1b[31m',
    green: '\x1b[32m',
    yellow: '\x1b[33m',
    blue: '\x1b[34m',
    purple: '\x1b[35m'
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

// 检查Excel文件
async function checkExcelFiles() {
    console.log('==========================================');
    console.log('  数据文件检查');
    console.log('==========================================');
    console.log();

    // 检查门店数据
    logInfo('检查门店数据文件...');
    const storesPath = path.join(__dirname, 'data/stores.xlsx');
    
    if (!fs.existsSync(storesPath)) {
        logError('门店数据文件不存在: data/stores.xlsx');
        return false;
    }

    try {
        const workbook = XLSX.readFile(storesPath);
        const sheetName = workbook.SheetNames[0];
        const worksheet = workbook.Sheets[sheetName];
        const data = XLSX.utils.sheet_to_json(worksheet);
        
        logSuccess(`门店数据文件读取成功: ${data.length} 条记录`);
        
        // 显示前几条记录
        if (data.length > 0) {
            logInfo('前3条门店记录:');
            data.slice(0, 3).forEach((store, index) => {
                console.log(`  ${index + 1}. ${store['网点名称']} - ${store['状态']} - ${store['联系电话']}`);
            });
        }
        
        // 检查必要字段
        const requiredFields = ['网点名称', '状态', '经度', '纬度', '联系电话'];
        const missingFields = requiredFields.filter(field => !data[0] || !data[0][field]);
        if (missingFields.length > 0) {
            logWarning(`缺少必要字段: ${missingFields.join(', ')}`);
        }
        
    } catch (error) {
        logError(`门店数据文件读取失败: ${error.message}`);
        return false;
    }

    console.log();

    // 检查订单数据
    logInfo('检查订单数据文件...');
    const ordersPath = path.join(__dirname, 'data/orders.xlsx');
    
    if (!fs.existsSync(ordersPath)) {
        logError('订单数据文件不存在: data/orders.xlsx');
        return false;
    }

    try {
        const workbook = XLSX.readFile(ordersPath);
        const sheetName = workbook.SheetNames[0];
        const worksheet = workbook.Sheets[sheetName];
        const data = XLSX.utils.sheet_to_json(worksheet);
        
        logSuccess(`订单数据文件读取成功: ${data.length} 条记录`);
        
        // 显示前几条记录
        if (data.length > 0) {
            logInfo('前3条订单记录:');
            data.slice(0, 3).forEach((order, index) => {
                console.log(`  ${index + 1}. ${order['订单号']} - ${order['手机号']} - ${order['租借状态']}`);
            });
        }
        
        // 检查手机号分布
        const phoneNumbers = data.map(order => order['手机号']).filter(phone => phone);
        const uniquePhones = [...new Set(phoneNumbers)];
        logInfo(`唯一手机号数量: ${uniquePhones.length}`);
        
        // 显示前10个手机号
        if (uniquePhones.length > 0) {
            logInfo('前10个手机号:');
            uniquePhones.slice(0, 10).forEach((phone, index) => {
                console.log(`  ${index + 1}. ${phone}`);
            });
        }
        
        // 检查测试手机号是否存在
        const testPhone = '17798762697';
        const testPhoneExists = phoneNumbers.includes(testPhone);
        if (testPhoneExists) {
            logSuccess(`测试手机号 ${testPhone} 存在于数据中`);
        } else {
            logWarning(`测试手机号 ${testPhone} 不存在于数据中`);
            logInfo('可用的测试手机号:');
            uniquePhones.slice(0, 5).forEach((phone, index) => {
                console.log(`  ${index + 1}. ${phone}`);
            });
        }
        
        // 检查必要字段
        const requiredFields = ['订单号', '手机号', '租借位置', '租借状态'];
        const missingFields = requiredFields.filter(field => !data[0] || !data[0][field]);
        if (missingFields.length > 0) {
            logWarning(`缺少必要字段: ${missingFields.join(', ')}`);
        }
        
    } catch (error) {
        logError(`订单数据文件读取失败: ${error.message}`);
        return false;
    }

    return true;
}

// 测试数据管理器
async function testDataManager() {
    console.log();
    console.log('==========================================');
    console.log('  数据管理器测试');
    console.log('==========================================');
    console.log();

    try {
        logInfo('初始化数据管理器...');
        const dataManager = new DataManager();
        await dataManager.loadData();
        
        logSuccess(`数据管理器加载成功: ${dataManager.stores.length} 个门店, ${dataManager.orders.length} 个订单`);
        
        // 测试订单查询
        logInfo('测试订单查询...');
        const testPhones = ['17798762697', '17796499753', '17796025359'];
        
        for (const phone of testPhones) {
            const orders = dataManager.queryOrdersByPhone(phone);
            if (orders.length > 0) {
                logSuccess(`手机号 ${phone} 找到 ${orders.length} 个订单`);
                orders.forEach((order, index) => {
                    console.log(`  ${index + 1}. ${order.orderId} - ${order.location} - ${order.status}`);
                });
            } else {
                logWarning(`手机号 ${phone} 未找到订单`);
            }
        }
        
        // 测试网点查询
        logInfo('测试网点查询...');
        const stores = dataManager.queryStoresByLocation(39.946613, 116.370503, 3);
        logSuccess(`找到 ${stores.length} 个附近网点`);
        stores.forEach((store, index) => {
            console.log(`  ${index + 1}. ${store.name} - ${store.address} - 距离: ${store.distance.toFixed(2)}km`);
        });
        
    } catch (error) {
        logError(`数据管理器测试失败: ${error.message}`);
        return false;
    }

    return true;
}

// 主函数
async function main() {
    try {
        const excelCheck = await checkExcelFiles();
        if (!excelCheck) {
            process.exit(1);
        }
        
        const managerTest = await testDataManager();
        if (!managerTest) {
            process.exit(1);
        }
        
        console.log();
        logSuccess('🎉 数据检查完成！');
        console.log();
        logInfo('建议操作:');
        console.log('1. 如果测试手机号不存在，请使用数据中存在的手机号进行测试');
        console.log('2. 如果数据格式有问题，请检查Excel文件的列标题');
        console.log('3. 重启MCP Server以加载最新数据');
        
    } catch (error) {
        logError(`检查过程出错: ${error.message}`);
        process.exit(1);
    }
}

// 运行主函数
main();
