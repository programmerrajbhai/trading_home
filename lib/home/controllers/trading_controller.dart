import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../candle_data.dart';
import '../chert.dart';
import '../models/trade_model.dart';
import '../utils/enums.dart';

class TradingController extends GetxController {
  // +++ নতুন কোড +++
  // চার্টকে বাইরে থেকে নিয়ন্ত্রণ করার জন্য একটি গ্লোবাল কী
  final GlobalKey<CandlestickChartState> chartKey = GlobalKey<CandlestickChartState>();

  // --- চার্ট এবং ক্যান্ডেল ডেটা ---
  final RxList<CandleData> _baseM1Candles = <CandleData>[].obs;
  final RxList<CandleData> displayedCandles = <CandleData>[].obs;
  final Rx<Timeframe> selectedTimeframe = Timeframe.m1.obs;
  final RxInt candleTimeRemaining = 0.obs;
  Timer? _candleTimer;
  Timer? _liveUpdateTimer;

  // --- এই লাইনটি মুছে ফেলা হয়েছে ---
  // final ScrollController scrollController = ScrollController();

  // --- অ্যাকাউন্ট এবং ব্যালেন্স ---
  final RxDouble liveBalance = 1000.00.obs;
  final RxDouble demoBalance = 10000.00.obs;
  final RxBool isLiveAccount = false.obs;
  double get currentBalance => isLiveAccount.value ? liveBalance.value : demoBalance.value;

  // --- ট্রেডিং স্টেট ---
  final RxList<Trade> runningTrades = <Trade>[].obs;
  final RxList<Trade> tradeHistory = <Trade>[].obs;
  final RxDouble investmentAmount = 20.0.obs;
  final RxInt tradeDurationSeconds = 60.obs;
  static const double payoutPercentage = 0.85;

  List<Trade> get combinedTradeList {
    final list = [...runningTrades, ...tradeHistory];
    list.sort((a, b) => b.entryTime.compareTo(a.entryTime));
    return list;
  }

  @override
  void onInit() {
    super.onInit();
    _generateInitialCandles();
    _startCandleGeneration();
    _aggregateCandles();
    Timer.periodic(const Duration(seconds: 1), (_) {
      _checkTradeExpiries();
      _updateCandleCountdown();
    });
  }

  void _generateInitialCandles() {
    double lastClose = 150.0;
    final now = DateTime.now();
    for (int i = 200; i > 0; i--) {
      final open = lastClose;
      final close = open * (1 + (Random().nextDouble() - 0.5) * 0.01);
      lastClose = close;
      _baseM1Candles.add(
          CandleData(
              timestamp: now.subtract(Duration(minutes: i)).millisecondsSinceEpoch,
              open: open,
              high: max(open, close) * (1 + Random().nextDouble() * 0.005),
              low: min(open, close) * (1 - Random().nextDouble() * 0.005),
              close: close
          )
      );
    }
  }

  void _updateCandleCountdown() {
    candleTimeRemaining.value = 60 - (DateTime.now().second % 60);
  }

  void _startCandleGeneration() {
    _candleTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _liveUpdateTimer?.cancel();
      final lastCandle = _baseM1Candles.last;
      final newCandle = CandleData(
        timestamp: DateTime.now().millisecondsSinceEpoch,
        open: lastCandle.close,
        high: lastCandle.close,
        low: lastCandle.close,
        close: lastCandle.close,
      );
      _baseM1Candles.add(newCandle);
      _startLiveCandleUpdate();
    });
    _startLiveCandleUpdate();
  }

  void _startLiveCandleUpdate() {
    _liveUpdateTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (_baseM1Candles.isEmpty) return;
      final lastCandle = _baseM1Candles.last;
      final newClose = lastCandle.close * (1 + (Random().nextDouble() - 0.5) * 0.001);

      final updatedCandle = CandleData(
        timestamp: lastCandle.timestamp,
        open: lastCandle.open,
        high: max(lastCandle.high, newClose),
        low: min(lastCandle.low, newClose),
        close: newClose,
      );
      _baseM1Candles[_baseM1Candles.length - 1] = updatedCandle;
      _aggregateCandles();
    });
  }

  void _aggregateCandles() {
    if (_baseM1Candles.isEmpty) return;
    final List<CandleData> aggregated = [];
    final int period = selectedTimeframe.value.minutes;
    for (int i = 0; i < _baseM1Candles.length; i += period) {
      final end = min(i + period, _baseM1Candles.length);
      final chunk = _baseM1Candles.sublist(i, end);
      if (chunk.isEmpty) continue;

      aggregated.add(CandleData(
        timestamp: chunk.first.timestamp,
        open: chunk.first.open,
        close: chunk.last.close,
        high: chunk.map((c) => c.high).reduce(max),
        low: chunk.map((c) => c.low).reduce(min),
      ));
    }
    displayedCandles.value = aggregated;
    _scrollToEnd();
  }

  void placeTrade(TradeDirection direction) {
    if (currentBalance < investmentAmount.value) {
      Get.snackbar("Error", "Insufficient funds.", backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }
    if (isLiveAccount.value) liveBalance.value -= investmentAmount.value;
    else demoBalance.value -= investmentAmount.value;

    final now = DateTime.now();
    runningTrades.add(Trade(
      id: now.millisecondsSinceEpoch.toString(),
      direction: direction,
      amount: investmentAmount.value,
      entryPrice: _baseM1Candles.last.close,
      entryTime: now,
      expiryTime: now.add(Duration(seconds: tradeDurationSeconds.value)),
    ));
  }

  void _checkTradeExpiries() {
    final List<Trade> expiredTrades = runningTrades.where((t) => DateTime.now().isAfter(t.expiryTime)).toList();
    for (var trade in expiredTrades) _settleTrade(trade);
  }

  void _settleTrade(Trade trade) {
    trade.closePrice = _baseM1Candles.last.close;
    bool isWin = (trade.direction == TradeDirection.up && trade.closePrice! > trade.entryPrice) ||
        (trade.direction == TradeDirection.down && trade.closePrice! < trade.entryPrice);

    if (trade.closePrice == trade.entryPrice) {
      trade.status = TradeStatus.draw;
      if (isLiveAccount.value) liveBalance.value += trade.amount; else demoBalance.value += trade.amount;
    } else if (isWin) {
      trade.status = TradeStatus.won;
      final payout = trade.amount + (trade.amount * payoutPercentage);
      if (isLiveAccount.value) liveBalance.value += payout; else demoBalance.value += payout;
    } else {
      trade.status = TradeStatus.lost;
    }
    runningTrades.remove(trade);
    tradeHistory.insert(0, trade);
  }

  // +++ এই মেথডটি আপডেট করা হয়েছে +++
  void _scrollToEnd() {
    // এখন আমরা ScrollController এর পরিবর্তে GlobalKey ব্যবহার করছি
    chartKey.currentState?.scrollToEnd();
  }

  void changeTimeframe(Timeframe tf) { selectedTimeframe.value = tf; _aggregateCandles(); }
  void setInvestmentAmount(double amount) { investmentAmount.value = amount; }
  void setTradeDuration(int seconds) { tradeDurationSeconds.value = seconds; }
  void switchAccount(bool toLive) { isLiveAccount.value = toLive; }

  @override
  void onClose() {
    _candleTimer?.cancel();
    _liveUpdateTimer?.cancel();
    // scrollController.dispose(); // <-- এই লাইনটি মুছে ফেলা হয়েছে
    super.onClose();
  }
}