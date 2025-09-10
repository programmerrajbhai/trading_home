import 'dart:async';
import 'dart:math';

import 'candle_data.dart';

class CandlestickDataProvider {
  /// Get seconds elapsed for the running candle
  int get runningCandleSeconds {
    if (_candles.isEmpty) return 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    final lastTs = _candles.last.timestamp;
    return ((now - lastTs) / 1000).floor();
  }

  /// নতুন ক্যান্ডেল তৈরি হলে কলব্যাক
  final void Function(CandleData) onNewCandle;

  /// ক্যান্ডেল আপডেট হলে কলব্যাক
  final void Function(CandleData) onUpdateCandle;

  /// প্রাথমিক ক্যান্ডেলের সংখ্যা
  final int numberOfInitialCandles;

  /// নতুন ক্যান্ডেল কত সেকেন্ড পর পর আসবে
  final Duration newCandleInterval;

  /// লাইভ আপডেট কত ms পর পর হবে
  final Duration liveUpdateInterval;

  /// ভ্যালু কন্ট্রোল (price range)
  final double minPrice;
  final double maxPrice;

  Timer? _newCandleTimer;
  Timer? _liveCandleUpdateTimer;
  final List<CandleData> _candles = [];

  CandlestickDataProvider({
    required this.onNewCandle,
    required this.onUpdateCandle,
    this.numberOfInitialCandles = 100000,
    this.newCandleInterval = const Duration(minutes: 1),
    this.liveUpdateInterval = const Duration(milliseconds: 500),
    this.minPrice = 100,
    this.maxPrice = 200,
  });

  /// ডেটা জেনারেশন শুরু
  void startGeneratingData() {
    // --- Initial Candles ---
    double prevClose = _getRandomArbitrary(minPrice, maxPrice);
    for (int i = 0; i < numberOfInitialCandles; i++) {
      final candle = _generateCandleData(prevClose);
      _candles.add(candle);
      prevClose = candle.close;
    }
    for (var c in _candles) {
      onNewCandle(c);
    }

    // --- নতুন ক্যান্ডেল যোগ ---
    _newCandleTimer = Timer.periodic(newCandleInterval, (_) {
      final last = _candles.isNotEmpty ? _candles.last : null;
      final newCandle = _generateCandleData(last?.close);
      _candles.add(newCandle);
      onNewCandle(newCandle);
    });

    // --- লাইভ ক্যান্ডেল আপডেট ---
    _liveCandleUpdateTimer = Timer.periodic(liveUpdateInterval, (_) {
      if (_candles.isEmpty) return;
      final i = _candles.length - 1;
      final last = _candles[i];

      final double newClose = _getRandomArbitrary(
        last.close * 0.995,
        last.close * 1.005,
      );

      final updated = CandleData(
        timestamp: last.timestamp,
        open: last.open,
        high: max(last.high, newClose),
        low: min(last.low, newClose),
        close: newClose,
      );

      _candles[i] = updated;
      onUpdateCandle(updated);
    });
  }

  /// ডেটা জেনারেশন বন্ধ
  void stopGeneratingData() {
    _newCandleTimer?.cancel();
    _liveCandleUpdateTimer?.cancel();
  }

  /// Helper: Random double between [min, max]
  double _getRandomArbitrary(double min, double max) {
    return Random().nextDouble() * (max - min) + min;
  }

  /// Helper: Generate new candle
  CandleData _generateCandleData(double? prevClose) {
    final open = prevClose ?? _getRandomArbitrary(minPrice, maxPrice);
    final close = _getRandomArbitrary(open * 0.98, open * 1.02);
    final high = max(open, close) * (1 + Random().nextDouble() * 0.02);
    final low = min(open, close) * (1 - Random().nextDouble() * 0.02);
    final ts = DateTime.now().millisecondsSinceEpoch;

    return CandleData(
      timestamp: ts,
      open: open,
      high: high,
      low: low,
      close: close,
    );
  }

  /// Getter: full candle list (যদি কোথাও ব্যবহার লাগে)
  List<CandleData> get candles => List.unmodifiable(_candles);
}
