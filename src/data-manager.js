import XLSX from 'xlsx';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

export class DataManager {
  constructor() {
    this.stores = [];
    this.orders = [];
  }

  async loadData() {
    try {
      // 加载门店数据
      await this.loadStoresData();
      // 加载订单数据
      await this.loadOrdersData();
      console.error(`数据加载完成: ${this.stores.length} 个门店, ${this.orders.length} 个订单`);
    } catch (error) {
      console.error('数据加载失败:', error);
      throw error;
    }
  }

  async loadStoresData() {
    const storesPath = path.join(__dirname, '../data/stores.xlsx');
    
    if (!fs.existsSync(storesPath)) {
      console.error('门店数据文件不存在，使用示例数据');
      this.stores = this.getSampleStoresData();
      return;
    }

    try {
      // 尝试作为Excel文件读取
      const workbook = XLSX.readFile(storesPath);
      const sheetName = workbook.SheetNames[0];
      const worksheet = workbook.Sheets[sheetName];
      const data = XLSX.utils.sheet_to_json(worksheet);

      this.stores = data.map(store => ({
        name: store['网点名称'],
        status: store['状态'],
        coordinates: store['经纬度'],
        province: store['省份'],
        city: store['城市'],
        district: store['区/县'],
        address: store['详细地址'],
        longitude: parseFloat(store['经度']) || 0,
        latitude: parseFloat(store['纬度']) || 0,
        type: store['门店类型'],
        openDate: store['开业时间'],
        businessHours: store['营业时间'],
        rating: parseFloat(store['评分']) || 0,
        phone: store['联系电话']
      }));
      
      console.error(`从Excel文件加载门店数据: ${this.stores.length} 个门店`);
    } catch (error) {
      console.error('Excel文件读取失败，使用示例数据:', error.message);
      this.stores = this.getSampleStoresData();
    }
  }

  async loadOrdersData() {
    const ordersPath = path.join(__dirname, '../data/orders.xlsx');
    
    if (!fs.existsSync(ordersPath)) {
      console.error('订单数据文件不存在，使用示例数据');
      this.orders = this.getSampleOrdersData();
      return;
    }

    try {
      // 尝试作为Excel文件读取
      const workbook = XLSX.readFile(ordersPath);
      const sheetName = workbook.SheetNames[0];
      const worksheet = workbook.Sheets[sheetName];
      const data = XLSX.utils.sheet_to_json(worksheet);

      this.orders = data.map(order => ({
        orderId: order['订单号'],
        userId: order['用户id'],
        phone: order['手机号'],
        deviceId: order['设备id'],
        location: order['租借位置'],
        startTime: order['租借开始时间'],
        returnTime: order['退还时间'],
        duration: parseInt(order['持续时间/分钟']) || 0,
        returnStore: order['归还网点'],
        cost: parseFloat(order['计费']) || 0,
        status: order['租借状态'],
        paymentMethod: order['支付方式']
      }));
      
      console.error(`从Excel文件加载订单数据: ${this.orders.length} 个订单`);
    } catch (error) {
      console.error('Excel文件读取失败，使用示例数据:', error.message);
      this.orders = this.getSampleOrdersData();
    }
  }

  getSampleStoresData() {
    return [
      {
        name: '北京后海-110分店',
        status: '正常',
        coordinates: '116.370503,39.946613',
        province: '北京市',
        city: '北京市',
        district: '西城区',
        address: '北京市西城区羊房胡同甲23号',
        longitude: 116.3705,
        latitude: 39.94661,
        type: '直营店',
        openDate: '2024/3/1',
        businessHours: '9:00-22:00',
        rating: 4.5,
        phone: '15858905939'
      },
      {
        name: '北京后海-120分店',
        status: '正常',
        coordinates: '116.378818,39.944656',
        province: '北京市',
        city: '北京市',
        district: '西城区',
        address: '北京市西城区羊房胡同甲35号',
        longitude: 116.3788,
        latitude: 39.94466,
        type: '直营店',
        openDate: '2018/12/23',
        businessHours: '9:00-22:00',
        rating: 4.8,
        phone: '15890785113'
      },
      {
        name: '北京后海-125分店',
        status: '正常',
        coordinates: '116.374374,39.942185',
        province: '北京市',
        city: '北京市',
        district: '西城区',
        address: '北京市西城区羊房胡同甲31号',
        longitude: 116.3744,
        latitude: 39.94219,
        type: '直营店',
        openDate: '2016/8/31',
        businessHours: '9:00-22:00',
        rating: 4.7,
        phone: '15828386811'
      },
      {
        name: '北京后海-142分店',
        status: '正常',
        coordinates: '116.38649,39.943933',
        province: '北京市',
        city: '北京市',
        district: '西城区',
        address: '北京市西城区后海北沿50号',
        longitude: 116.3865,
        latitude: 39.94393,
        type: '直营店',
        openDate: '2019/8/4',
        businessHours: '9:00-22:00',
        rating: 4.9,
        phone: '15892847917'
      },
      {
        name: '北京后海-148分店',
        status: '正常',
        coordinates: '116.369155,39.940742',
        province: '北京市',
        city: '北京市',
        district: '西城区',
        address: '北京市西城区后海北沿70号',
        longitude: 116.3692,
        latitude: 39.94074,
        type: '直营店',
        openDate: '2020/8/21',
        businessHours: '9:00-22:00',
        rating: 4.8,
        phone: '15817929741'
      },
      {
        name: '北京后海-154分店',
        status: '正常',
        coordinates: '116.377185,39.943402',
        province: '北京市',
        city: '北京市',
        district: '西城区',
        address: '北京市西城区德内大街羊房胡同9号',
        longitude: 116.3772,
        latitude: 39.9434,
        type: '直营店',
        openDate: '2018/5/14',
        businessHours: '9:00-22:00',
        rating: 3.9,
        phone: '15813203456'
      }
    ];
  }

  getSampleOrdersData() {
    return [
      {
        orderId: 'PO202508281731220218',
        userId: 'U10058',
        phone: '17798762697',
        deviceId: 'D20219',
        location: '北京后海-166分店',
        startTime: '2025-08-28 20:35:00',
        returnTime: '',
        duration: 32,
        returnStore: '',
        cost: 3.2,
        status: '已暂停',
        paymentMethod: 'wechat_pay'
      },
      {
        orderId: 'PO202508281731220253',
        userId: 'U10007',
        phone: '17796499753',
        deviceId: 'D20254',
        location: '深圳华强北店',
        startTime: '2025-08-28 23:20:00',
        returnTime: '',
        duration: 239,
        returnStore: '',
        cost: 23.9,
        status: '已暂停',
        paymentMethod: 'apple_pay'
      },
      {
        orderId: 'PO202508281731220067',
        userId: 'U10080',
        phone: '17796025359',
        deviceId: 'D20068',
        location: '北京三里屯太古里-34分店',
        startTime: '2025-08-28 15:28:00',
        returnTime: '',
        duration: 7,
        returnStore: '',
        cost: 0.7,
        status: '进行中',
        paymentMethod: 'wechat_pay'
      },
      {
        orderId: 'PO202508281731220282',
        userId: 'U10045',
        phone: '17794866582',
        deviceId: 'D20283',
        location: '上海外滩-150分店',
        startTime: '2025-08-28 21:16:00',
        returnTime: '',
        duration: 128,
        returnStore: '',
        cost: 12.8,
        status: '已暂停',
        paymentMethod: 'alipay'
      },
      {
        orderId: 'PO202508281731220099',
        userId: 'U10031',
        phone: '17792350608',
        deviceId: 'D20100',
        location: '上海外滩-171分店',
        startTime: '2025-08-28 22:14:00',
        returnTime: '',
        duration: 157,
        returnStore: '',
        cost: 15.7,
        status: '已暂停',
        paymentMethod: 'alipay'
      }
    ];
  }

  // 根据手机号查询订单
  queryOrdersByPhone(phone) {
    return this.orders.filter(order => order.phone === phone);
  }

  // 根据经纬度查询附近门店
  queryStoresByLocation(latitude, longitude, limit = 10) {
    const storesWithDistance = this.stores.map(store => {
      const distance = this.calculateDistance(latitude, longitude, store.latitude, store.longitude);
      return { ...store, distance };
    });

    return storesWithDistance
      .sort((a, b) => a.distance - b.distance)
      .slice(0, limit);
  }

  // 计算两点间距离（使用Haversine公式）
  calculateDistance(lat1, lon1, lat2, lon2) {
    const R = 6371; // 地球半径（公里）
    const dLat = this.toRadians(lat2 - lat1);
    const dLon = this.toRadians(lon2 - lon1);
    const a = 
      Math.sin(dLat/2) * Math.sin(dLat/2) +
      Math.cos(this.toRadians(lat1)) * Math.cos(this.toRadians(lat2)) * 
      Math.sin(dLon/2) * Math.sin(dLon/2);
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));
    return R * c;
  }

  toRadians(degrees) {
    return degrees * (Math.PI/180);
  }
}
