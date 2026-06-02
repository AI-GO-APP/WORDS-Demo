// ===========================================
// 沃茲後台共用資料層
// 所有資料存在 localStorage，3 個頁面共用
// ===========================================

const STORAGE_KEY = 'words_admin_data';

// Seed data：首次載入時的預設資料
const SEED_DATA = {
  venues: [
    { id: 1, name: '勤美館', code: 'QM', district: '北區', address: '404 台中市北區英才路 396 號 11 樓-2', status: 'active' },
    { id: 2, name: '忠明館', code: 'ZM', district: '南區', address: '台中市南區忠明南路 478 號 B1', status: 'active' },
    { id: 3, name: '文華館', code: 'WH', district: '西屯區', address: '台中市西屯區文心路三段 237 號 6F', status: 'active' },
    { id: 4, name: '漢口館', code: 'HK', district: '西屯區', address: '台中市西屯區四川路 87 號 B1', status: 'active' },
    { id: 5, name: '站前館', code: 'ZQ', district: '東區', address: '台中市東區自由二街 91 號', status: 'active' }
  ],
  spaces: [
    // 勤美館
    { id: 1, venue_id: 1, name: '勤美館', capacity: 30, status: 'active' },
    // 忠明館
    { id: 2, venue_id: 2, name: '忠明館', capacity: 60, status: 'active' },
    { id: 3, venue_id: 2, name: '忠明館-休息室', capacity: 10, status: 'active' },
    // 文華館
    { id: 4, venue_id: 3, name: '文華館', capacity: 40, status: 'active' },
    // 漢口館
    { id: 5, venue_id: 4, name: '漢口一館', capacity: 80, status: 'active' },
    { id: 6, venue_id: 4, name: '漢口二館', capacity: 80, status: 'active' },
    { id: 7, venue_id: 4, name: '漢口會議室', capacity: 20, status: 'active' },
    // 站前館
    { id: 8, venue_id: 5, name: '藝文展間', capacity: 60, status: 'active' },
    { id: 9, venue_id: 5, name: '階梯教室', capacity: 60, status: 'active' },
    { id: 10, venue_id: 5, name: '多功能 1 館', capacity: 60, status: 'active' },
    { id: 11, venue_id: 5, name: '多功能 2 館', capacity: 60, status: 'active' },
    { id: 12, venue_id: 5, name: '階梯+展間', capacity: 140, status: 'active' },
    { id: 13, venue_id: 5, name: '多功能全館', capacity: 140, status: 'active' },
    { id: 14, venue_id: 5, name: '藝文半展間', capacity: 40, status: 'active' },
    { id: 15, venue_id: 5, name: '會議室', capacity: 15, status: 'active' },
    { id: 16, venue_id: 5, name: '洽談室', capacity: 8, status: 'active' },
    { id: 17, venue_id: 5, name: '休息室', capacity: 8, status: 'active' },
    { id: 18, venue_id: 5, name: '站前館外廣場', capacity: 50, status: 'active' },
    { id: 19, venue_id: 5, name: '站前館外長廊', capacity: 30, status: 'active' }
  ],
  prices: [
    // 勤美館 (space_id: 1)
    {
      space_id: 1, weekday: 680, weekend: 850,
      headcount: [{ label: '15人(含)以內', price: 0 }, { label: '16人以上', price: 500 }],
      cleanup: [{ label: '15人(含)以內', price: 500 }, { label: '16人以上', price: 800 }],
      deposit: 3000, halfSetup: 600, fullSetup: 1000,
      weekdayHalf: 2600, weekdayFull: 5200, weekendHalf: 3300, weekendFull: 6480
    },
    // 忠明館 (space_id: 2)
    {
      space_id: 2, weekday: 960, weekend: 1200,
      headcount: [{ label: '30人(含)以內', price: 0 }, { label: '31-60人', price: 600 }, { label: '61人以上', price: 1000 }],
      cleanup: [{ label: '30人(含)以內', price: 800 }, { label: '31-60人', price: 1200 }, { label: '61人以上', price: 1500 }],
      deposit: 3000, halfSetup: 800, fullSetup: 1500,
      weekdayHalf: 4250, weekdayFull: 7950, weekendHalf: 5200, weekendFull: 9800
    },
    // 文華館 (space_id: 4)
    {
      space_id: 4, weekday: 760, weekend: 950,
      headcount: [{ label: '20人(含)以內', price: 0 }, { label: '21-40人', price: 600 }, { label: '41人以上', price: 1000 }],
      cleanup: [{ label: '20人(含)以內', price: 500 }, { label: '21-40人', price: 800 }, { label: '41人以上', price: 1200 }],
      deposit: 3000, halfSetup: 800, fullSetup: 1500,
      weekdayHalf: 3300, weekdayFull: 6200, weekendHalf: 4000, weekendFull: 7680
    },
    // 漢口一館 (space_id: 5)
    {
      space_id: 5, weekday: 1104, weekend: 1380,
      headcount: [{ label: '40人(含)以內', price: 0 }, { label: '41-80人', price: 800 }, { label: '81人以上', price: 1200 }],
      cleanup: [{ label: '40人(含)以內', price: 800 }, { label: '41-80人', price: 1200 }, { label: '81人以上', price: 1800 }],
      deposit: 5000, halfSetup: 1200, fullSetup: 2000,
      weekdayHalf: 5200, weekdayFull: 9450, weekendHalf: 6250, weekendFull: 11560
    },
    // 漢口二館 (space_id: 6)
    {
      space_id: 6, weekday: 1104, weekend: 1380,
      headcount: [{ label: '40人(含)以內', price: 0 }, { label: '41-80人', price: 800 }, { label: '81人以上', price: 1200 }],
      cleanup: [{ label: '40人(含)以內', price: 800 }, { label: '41-80人', price: 1200 }, { label: '81人以上', price: 1800 }],
      deposit: 5000, halfSetup: 1200, fullSetup: 2000,
      weekdayHalf: 5200, weekdayFull: 9450, weekendHalf: 6250, weekendFull: 11560
    },
    // 站前-藝文展間 (space_id: 8)
    {
      space_id: 8, weekday: 1104, weekend: 1380,
      headcount: [{ label: '30人(含)以內', price: 0 }, { label: '31-60人', price: 600 }, { label: '61人以上', price: 1000 }],
      cleanup: [{ label: '30人(含)以內', price: 800 }, { label: '31-60人', price: 1200 }, { label: '61人以上', price: 1500 }],
      deposit: 3000, halfSetup: 1000, fullSetup: 1800,
      weekdayHalf: 5120, weekdayFull: 9350, weekendHalf: 6150, weekendFull: 11460
    },
    // 站前-階梯教室 (space_id: 9)
    {
      space_id: 9, weekday: 960, weekend: 1200,
      headcount: [{ label: '30人(含)以內', price: 0 }, { label: '31-60人', price: 600 }, { label: '61人以上', price: 1000 }],
      cleanup: [{ label: '30人(含)以內', price: 800 }, { label: '31-60人', price: 1200 }, { label: '61人以上', price: 1500 }],
      deposit: 3000, halfSetup: 800, fullSetup: 1500,
      weekdayHalf: 4480, weekdayFull: 8120, weekendHalf: 5380, weekendFull: 9920
    },
    // 站前-多功能1館 (space_id: 10)
    {
      space_id: 10, weekday: 1104, weekend: 1380,
      headcount: [{ label: '30人(含)以內', price: 0 }, { label: '31-60人', price: 600 }, { label: '61人以上', price: 1000 }],
      cleanup: [{ label: '30人(含)以內', price: 800 }, { label: '31-60人', price: 1000 }, { label: '61人以上', price: 1200 }],
      deposit: 3000, halfSetup: 1000, fullSetup: 1800,
      weekdayHalf: 5000, weekdayFull: 9250, weekendHalf: 6050, weekendFull: 11360
    },
    // 站前-多功能2館 (space_id: 11)
    {
      space_id: 11, weekday: 1104, weekend: 1380,
      headcount: [{ label: '30人(含)以內', price: 0 }, { label: '31-60人', price: 600 }, { label: '61人以上', price: 1000 }],
      cleanup: [{ label: '30人(含)以內', price: 800 }, { label: '31-60人', price: 1000 }, { label: '61人以上', price: 1200 }],
      deposit: 3000, halfSetup: 1000, fullSetup: 1800,
      weekdayHalf: 5000, weekdayFull: 9250, weekendHalf: 6050, weekendFull: 11360
    },
    // 站前-階梯+展間 (space_id: 12)
    {
      space_id: 12, weekday: 1320, weekend: 1650,
      headcount: [{ label: '60人(含)以內', price: 0 }, { label: '61-100人', price: 1200 }, { label: '101-140人', price: 1800 }, { label: '141人以上', price: 2400 }],
      cleanup: [{ label: '60人(含)以內', price: 1200 }, { label: '61-100人', price: 1800 }, { label: '101-140人', price: 2400 }, { label: '141人以上', price: 3000 }],
      deposit: 5000, halfSetup: 1500, fullSetup: 2200,
      weekdayHalf: 6820, weekdayFull: 11900, weekendHalf: 8050, weekendFull: 14350
    },
    // 站前-多功能全館 (space_id: 13)
    {
      space_id: 13, weekday: 1480, weekend: 1850,
      headcount: [{ label: '60人(含)以內', price: 0 }, { label: '61-100人', price: 1200 }, { label: '101-140人', price: 1800 }, { label: '141人以上', price: 2400 }],
      cleanup: [{ label: '60人(含)以內', price: 1200 }, { label: '61-100人', price: 1800 }, { label: '101-140人', price: 2400 }, { label: '141人以上', price: 3000 }],
      deposit: 5000, halfSetup: 1500, fullSetup: 2200,
      weekdayHalf: 7450, weekdayFull: 13120, weekendHalf: 8850, weekendFull: 15950
    },
    // 站前-藝文半展間 (space_id: 14)
    {
      space_id: 14, weekday: 800, weekend: 1000,
      headcount: [{ label: '20人(含)以內', price: 0 }, { label: '21-40人', price: 600 }, { label: '41人以上', price: 1000 }],
      cleanup: [{ label: '20人(含)以內', price: 500 }, { label: '21-40人', price: 800 }, { label: '41人以上', price: 1200 }],
      deposit: 3000, halfSetup: 800, fullSetup: 1500,
      weekdayHalf: 3750, weekdayFull: 6820, weekendHalf: 4500, weekendFull: 8350
    },
    // 站前-會議室 (space_id: 15)
    {
      space_id: 15, weekday: 544, weekend: 680,
      cleanupFlat: 300, deposit: 1000,
      weekdayHalf: 2080, weekdayFull: 4160, weekendHalf: 2580, weekendFull: 5200
    },
    // 站前-洽談室 (space_id: 16)
    {
      space_id: 16, weekday: 440, weekend: 550,
      cleanupFlat: 300, deposit: 1000,
      weekdayHalf: 1680, weekdayFull: 3380, weekendHalf: 2090, weekendFull: 4210
    },
    // 站前-休息室 (space_id: 17)
    {
      space_id: 17, weekday: 384, weekend: 480,
      cleanupFlat: 300, deposit: 1000,
      weekdayHalf: 1460, weekdayFull: 2950, weekendHalf: 1850, weekendFull: 3680
    },
    // 站前-外廣場 (space_id: 18)
    {
      space_id: 18, weekday: 640, weekend: 800,
      deposit: 5000,
      weekdayHalf: 2450, weekdayFull: 4900, weekendHalf: 3050, weekendFull: 6120
    },
    // 站前-外長廊 (space_id: 19)
    {
      space_id: 19, weekday: 640, weekend: 800,
      deposit: 5000,
      weekdayHalf: 2450, weekdayFull: 4900, weekendHalf: 3050, weekendFull: 6120
    }
    // 注意：忠明館-休息室 (id 3)、漢口會議室 (id 7) 沒有價格（demo 時可加）
  ]
};

// ===========================================
// DataStore：所有頁面共用的 CRUD API
// ===========================================
const DataStore = {
  load() {
    const raw = localStorage.getItem(STORAGE_KEY);
    if (raw) {
      try { return JSON.parse(raw); }
      catch (e) { console.error('資料解析失敗，重置為預設值'); }
    }
    this.save(SEED_DATA);
    return JSON.parse(JSON.stringify(SEED_DATA));
  },

  save(data) {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(data));
  },

  reset() {
    localStorage.removeItem(STORAGE_KEY);
    return this.load();
  },

  // ===== Venues =====
  getVenues() { return this.load().venues; },

  getVenue(id) { return this.getVenues().find(v => v.id === id); },

  addVenue(venue) {
    const data = this.load();
    venue.id = Math.max(...data.venues.map(v => v.id), 0) + 1;
    venue.status = venue.status || 'active';
    data.venues.push(venue);
    this.save(data);
    return venue;
  },

  updateVenue(id, updates) {
    const data = this.load();
    const idx = data.venues.findIndex(v => v.id === id);
    if (idx >= 0) {
      data.venues[idx] = { ...data.venues[idx], ...updates };
      this.save(data);
    }
  },

  deleteVenue(id) {
    const data = this.load();
    const spaceIds = data.spaces.filter(s => s.venue_id === id).map(s => s.id);
    data.venues = data.venues.filter(v => v.id !== id);
    data.spaces = data.spaces.filter(s => s.venue_id !== id);
    data.prices = data.prices.filter(p => !spaceIds.includes(p.space_id));
    this.save(data);
  },

  // ===== Spaces =====
  getAllSpaces() { return this.load().spaces; },

  getSpacesByVenue(venueId) {
    return this.load().spaces.filter(s => s.venue_id === venueId);
  },

  getSpace(id) { return this.load().spaces.find(s => s.id === id); },

  addSpace(space) {
    const data = this.load();
    space.id = Math.max(...data.spaces.map(s => s.id), 0) + 1;
    space.status = space.status || 'active';
    data.spaces.push(space);
    this.save(data);
    return space;
  },

  updateSpace(id, updates) {
    const data = this.load();
    const idx = data.spaces.findIndex(s => s.id === id);
    if (idx >= 0) {
      data.spaces[idx] = { ...data.spaces[idx], ...updates };
      this.save(data);
    }
  },

  deleteSpace(id) {
    const data = this.load();
    data.spaces = data.spaces.filter(s => s.id !== id);
    data.prices = data.prices.filter(p => p.space_id !== id);
    this.save(data);
  },

  // ===== Prices =====
  getPrice(spaceId) {
    return this.load().prices.find(p => p.space_id === spaceId);
  },

  upsertPrice(spaceId, priceData) {
    const data = this.load();
    const idx = data.prices.findIndex(p => p.space_id === spaceId);
    const merged = { space_id: spaceId, ...priceData };
    if (idx >= 0) data.prices[idx] = merged;
    else data.prices.push(merged);
    this.save(data);
  },

  // ===== 統計 =====
  getStats() {
    const data = this.load();
    return {
      venues: data.venues.length,
      spaces: data.spaces.length,
      spacesWithPrice: data.prices.length
    };
  }
};

// ===========================================
// 空間圖片對照表（前台共用）
// ===========================================
const SPACE_IMAGES = {
  '勤美館': 'images/勤美.png',
  '忠明館': 'images/忠明館.jpeg',
  '忠明館-休息室': 'images/忠明館-休息室.jpg',
  '文華館': 'images/文華館.jpg',
  '漢口一館': 'images/漢口館-一館.png',
  '漢口二館': 'images/漢口館-二館.webp',
  '漢口會議室': 'images/漢口館-會議室.png',
  '會議室': 'images/站前館- 2F 會議室.webp',
  '洽談室': 'images/站前館- 2F 洽談室.webp',
  '休息室': 'images/站前館- 2F 休息室.jpg',
  '多功能 1 館': 'images/站前館-多功能一館.webp',
  '多功能 2 館': 'images/站前館-多功能二館.webp',
  '多功能全館': 'images/站前館-多功能全館.webp',
  '藝文展間': 'images/站前館-藝文展間.webp',
  '藝文半展間': 'images/站前館-藝文展間（前段）.webp',
  '階梯教室': 'images/站前館-靜態階梯空間.webp',
  '階梯+展間': 'images/站前館-藝文展間 + 靜態階梯空間.jpg'
};

// ===========================================
// CartStore：購物車資料層（前台用）
// ===========================================
const CART_KEY = 'words_cart';
const CartStore = {
  getAll() {
    try {
      return JSON.parse(localStorage.getItem(CART_KEY) || '[]');
    } catch (e) { return []; }
  },

  save(items) {
    localStorage.setItem(CART_KEY, JSON.stringify(items));
  },

  add(item) {
    const items = this.getAll();
    item.id = Date.now();
    item.createdAt = new Date().toLocaleString('zh-TW', { hour12: false });
    items.push(item);
    this.save(items);
    return item;
  },

  remove(id) {
    const items = this.getAll().filter(i => i.id !== id);
    this.save(items);
  },

  clear() {
    this.save([]);
  },

  count() {
    return this.getAll().length;
  },

  getSubtotal() {
    return this.getAll().reduce((sum, i) => sum + (i.subtotal || 0), 0);
  },

  getDepositTotal() {
    return this.getAll().reduce((sum, i) => sum + (i.deposit || 0), 0);
  },

  getTotal() {
    return this.getSubtotal() + this.getDepositTotal();
  }
};
