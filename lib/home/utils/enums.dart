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