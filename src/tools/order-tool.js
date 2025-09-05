export class OrderTool {
  static async execute(args, dataManager) {
    const { phone } = args;

    if (!phone) {
      throw new Error('手机号参数不能为空');
    }

    // 验证手机号格式
    const phoneRegex = /^1[3-9]\d{9}$/;
    if (!phoneRegex.test(phone)) {
      throw new Error('手机号格式不正确');
    }

    const orders = dataManager.queryOrdersByPhone(phone);

    if (orders.length === 0) {
      return {
        content: [
          {
            type: 'text',
            text: `未找到手机号 ${phone} 对应的订单信息。`,
          },
        ],
      };
    }

    // 格式化订单信息
    const orderDetails = orders.map(order => {
      const canStopBilling = order.status === '进行中';
      
      return {
        手机号: order.phone,
        订单号: order.orderId,
        租借位置: order.location,
        租借状态: order.status,
        是否允许停止计费: canStopBilling ? '是' : '否',
        设备ID: order.deviceId,
        租借开始时间: order.startTime,
        持续时间: order.duration ? `${order.duration}分钟` : '未计算',
        计费: order.cost ? `¥${order.cost}` : '未计费',
        支付方式: this.formatPaymentMethod(order.paymentMethod)
      };
    });

    const resultText = `找到 ${orders.length} 个订单：\n\n` +
      orderDetails.map((order, index) => 
        `订单 ${index + 1}:\n` +
        Object.entries(order)
          .map(([key, value]) => `  ${key}: ${value}`)
          .join('\n')
      ).join('\n\n');

    return {
      content: [
        {
          type: 'text',
          text: resultText,
        },
      ],
    };
  }

  static formatPaymentMethod(method) {
    const paymentMethods = {
      'wechat_pay': '微信支付',
      'alipay': '支付宝',
      'apple_pay': 'Apple Pay',
      'union_pay': '银联支付'
    };
    return paymentMethods[method] || method;
  }
}
