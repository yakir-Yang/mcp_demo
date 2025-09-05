export class StoreTool {
  static async execute(args, dataManager) {
    const { latitude, longitude, limit = 10 } = args;

    if (latitude === undefined || longitude === undefined) {
      throw new Error('经纬度参数不能为空');
    }

    // 验证经纬度范围
    if (latitude < -90 || latitude > 90) {
      throw new Error('纬度必须在-90到90之间');
    }
    if (longitude < -180 || longitude > 180) {
      throw new Error('经度必须在-180到180之间');
    }

    const stores = dataManager.queryStoresByLocation(latitude, longitude, limit);

    if (stores.length === 0) {
      return {
        content: [
          {
            type: 'text',
            text: `在坐标 (${latitude}, ${longitude}) 附近未找到任何网点。`,
          },
        ],
      };
    }

    // 格式化门店信息
    const storeDetails = stores.map(store => ({
      网点名称: store.name,
      状态: store.status,
      经纬度: `${store.longitude},${store.latitude}`,
      详细地址: store.address,
      距离: `${store.distance.toFixed(2)}公里`,
      营业时间: store.businessHours,
      评分: store.rating,
      联系电话: store.phone,
      门店类型: store.type
    }));

    const resultText = `找到 ${stores.length} 个附近网点：\n\n` +
      storeDetails.map((store, index) => 
        `网点 ${index + 1}:\n` +
        Object.entries(store)
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
}
