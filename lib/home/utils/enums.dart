enum TradeDirection { up, down }

enum TradeStatus { running, won, lost, draw }

enum Timeframe {
  m1(1, '1M'),
  m2(2, '2M'),
  m5(5, '5M'),
  m10(10, '10M'),
  m20(20, '20M'),
  m30(30, '30M');

  const Timeframe(this.minutes, this.label);
  final int minutes;
  final String label;
}

// চার্টের ধরনের জন্য enum
enum ChartType { candlestick, line, bar }

// এখানে Asset-এর তালিকা আপডেট করা হয়েছে
enum Asset {
  // Currency Pairs
  eurusd('EUR/USD OTC'),
  gbpusd('GBP/USD OTC'),
  usdjpy('USD/JPY OTC'),
  usdbdt('USD/BDT OTC'),
  eurbdt('EUR/BDT OTC'),
  gbpbdt('GBP/BDT OTC'),
  audusd('AUD/USD OTC'),
  usdcad('USD/CAD OTC'),
  usdchf('USD/CHF OTC'),

  // Commodities
  gold('Gold OTC'),
  silver('Silver OTC'),
  oil('Oil OTC'),

  // Bangladeshi Stocks
  dsex('DSEX Index OTC'),
  beximco('Beximco Ltd OTC'),
  grameenphone('Grameenphone OTC'),
  square('Square Pharma OTC'),
  bashundhara('Bashundhara Group OTC'),

  // International Stocks & Groups
  emaar('Emaar Properties OTC'),
  emirates('Emirates Group OTC'),
  apple('Apple OTC'),
  tesla('Tesla OTC'),
  amazon('Amazon OTC');

  const Asset(this.label);
  final String label;
}