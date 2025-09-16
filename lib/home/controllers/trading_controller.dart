import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../candle_data.dart';
import '../chert.dart';
import '../models/trade_model.dart';
import '../utils/enums.dart';

class TradingController extends GetxController {
  final GlobalKey<CandlestickChartState> chartKey = GlobalKey<CandlestickChartState>();

  final Map<Asset, RxList<CandleData>> _assetCandles = {};
  final Rx<Asset> selectedAsset = Asset.btcusd.obs;
  final RxList<CandleData> displayedCandles = <CandleData>[].obs;
  final Rx<Timeframe> selectedTimeframe = Timeframe.m1.obs;
  final RxInt candleTimeRemaining = 0.obs;
  Timer? _candleTimer;
  Timer? _liveUpdateTimer;

  final RxDouble liveBalance = 1000.00.obs;
  final RxDouble demoBalance = 10000.00.obs;
  final RxBool isLiveAccount = false.obs;
  double get currentBalance => isLiveAccount.value ? liveBalance.value : demoBalance.value;

  final RxList<Trade> runningTrades = <Trade>[].obs;
  final RxList<Trade> tradeHistory = <Trade>[].obs;
  final RxDouble investmentAmount = 20.0.obs;
  final RxInt tradeDurationSeconds = 60.obs;
  static const double payoutPercentage = 0.85;

  final TextEditingController investmentController = TextEditingController(text: '20.0');
  final TextEditingController durationController = TextEditingController(text: '60');

  List<Trade> get combinedTradeList {
    final list = [...runningTrades, ...tradeHistory];
    list.sort((a, b) => b.entryTime.compareTo(a.entryTime));
    return list;
  }

  @override
  void onInit() {
    super.onInit();
    _initAssets();
    _startCandleGeneration();
    _aggregateCandles();
    Timer.periodic(const Duration(seconds: 1), (_) {
      _checkTradeExpiries();
      _updateCandleCountdown();
    });
  }

  void _initAssets() {
    for(final asset in Asset.values) {
      _assetCandles[asset] = <CandleData>[].obs;
      _generateInitialCandles(asset);
    }
  }

  void _generateInitialCandles(Asset asset) {
    double lastClose = 150.0;
    final now = DateTime.now();
    for (int i = 200; i > 0; i--) {
      final open = lastClose;
      final close = open * (1 + (Random().nextDouble() - 0.5) * 0.01);
      lastClose = close;
      _assetCandles[asset]!.add(
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
    if (displayedCandles.isEmpty) return;
    final lastCandleTimestamp = displayedCandles.last.timestamp;
    final totalDurationInSeconds = selectedTimeframe.value.minutes * 60;
    final timeElapsedInSeconds = (DateTime.now().millisecondsSinceEpoch - lastCandleTimestamp) ~/ 1000;
    final remainingSeconds = totalDurationInSeconds - (timeElapsedInSeconds % totalDurationInSeconds);
    candleTimeRemaining.value = remainingSeconds.clamp(0, totalDurationInSeconds);
  }

  void _startCandleGeneration() {
    _candleTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _liveUpdateTimer?.cancel();
      for(final asset in Asset.values) {
        if (_assetCandles[asset]!.isNotEmpty) {
          final lastCandle = _assetCandles[asset]!.last;
          final newCandle = CandleData(
            timestamp: DateTime.now().millisecondsSinceEpoch,
            open: lastCandle.close,
            high: lastCandle.close,
            low: lastCandle.close,
            close: lastCandle.close,
          );
          _assetCandles[asset]!.add(newCandle);
        }
      }
      _startLiveCandleUpdate();
    });
    _startLiveCandleUpdate();
  }

  void _startLiveCandleUpdate() {
    _liveUpdateTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      for (final asset in Asset.values) {
        if (_assetCandles[asset]!.isEmpty) continue;
        final lastCandle = _assetCandles[asset]!.last;
        final newClose = lastCandle.close * (1 + (Random().nextDouble() - 0.5) * 0.001);
        final updatedCandle = CandleData(
          timestamp: lastCandle.timestamp,
          open: lastCandle.open,
          high: max(lastCandle.high, newClose),
          low: min(lastCandle.low, newClose),
          close: newClose,
        );
        _assetCandles[asset]![_assetCandles[asset]!.length - 1] = updatedCandle;
      }
      _aggregateCandles();
    });
  }

  void _aggregateCandles() {
    final baseCandles = _assetCandles[selectedAsset.value];
    if (baseCandles == null || baseCandles.isEmpty) {
      displayedCandles.value = [];
      return;
    }

    final List<CandleData> aggregated = [];
    final int period = selectedTimeframe.value.minutes;
    final now = DateTime.now();
    final currentMinute = now.minute;
    final startOfCurrentPeriodMinute = (currentMinute ~/ period) * period;
    final startOfCurrentPeriod = DateTime(now.year, now.month, now.day, now.hour, startOfCurrentPeriodMinute);

    final relevantCandles = baseCandles.where((c) => c.timestamp < startOfCurrentPeriod.millisecondsSinceEpoch).toList();
    final currentCandleChunk = baseCandles.where((c) => c.timestamp >= startOfCurrentPeriod.millisecondsSinceEpoch).toList();

    for (int i = 0; i < relevantCandles.length; i += period) {
      final chunk = relevantCandles.sublist(i, min(i + period, relevantCandles.length));
      if (chunk.isNotEmpty) {
        aggregated.add(CandleData(
          timestamp: chunk.first.timestamp,
          open: chunk.first.open,
          close: chunk.last.close,
          high: chunk.map((c) => c.high).reduce(max),
          low: chunk.map((c) => c.low).reduce(min),
        ));
      }
    }

    if (currentCandleChunk.isNotEmpty) {
      aggregated.add(CandleData(
        timestamp: currentCandleChunk.first.timestamp,
        open: currentCandleChunk.first.open,
        close: currentCandleChunk.last.close,
        high: currentCandleChunk.map((c) => c.high).reduce(max),
        low: currentCandleChunk.map((c) => c.low).reduce(min),
      ));
    }
    displayedCandles.value = aggregated;
    _scrollToEnd();
  }

  void placeTrade(TradeDirection direction) {
    final double amount = double.tryParse(investmentController.text) ?? 20.0;
    final int duration = int.tryParse(durationController.text) ?? 60;

    if (currentBalance < amount) {
      Get.snackbar("Error", "Insufficient funds.", backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }
    if (isLiveAccount.value) liveBalance.value -= amount;
    else demoBalance.value -= amount;

    final now = DateTime.now();
    runningTrades.add(Trade(
      id: now.millisecondsSinceEpoch.toString(),
      direction: direction,
      amount: amount,
      entryPrice: _assetCandles[selectedAsset.value]!.last.close,
      entryTime: now,
      expiryTime: now.add(Duration(seconds: duration)),
    ));
    Get.snackbar("Trade Placed", "Your trade for \$${amount.toStringAsFixed(2)} has been placed.", backgroundColor: Colors.green, colorText: Colors.white);
  }

  void earlyCloseTrade(Trade trade) {
    final remainingSeconds = trade.expiryTime.difference(DateTime.now()).inSeconds;
    if (remainingSeconds <= 20) {
      Get.snackbar("Error", "Cannot close trade in the last 20 seconds.", backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }
    _settleTrade(trade);
  }

  void _checkTradeExpiries() {
    final List<Trade> expiredTrades = runningTrades.where((t) => DateTime.now().isAfter(t.expiryTime)).toList();
    for (var trade in expiredTrades) _settleTrade(trade);
  }

  void _settleTrade(Trade trade) {
    trade.closePrice = _assetCandles[selectedAsset.value]!.last.close;
    bool isWin = (trade.direction == TradeDirection.up && trade.closePrice! > trade.entryPrice) ||
        (trade.direction == TradeDirection.down && trade.closePrice! < trade.entryPrice);

    String message;
    Color color;

    if (trade.closePrice == trade.entryPrice) {
      trade.status = TradeStatus.draw;
      if (isLiveAccount.value) liveBalance.value += trade.amount; else demoBalance.value += trade.amount;
      message = "Trade ended: Draw! Your investment was returned.";
      color = Colors.grey;



    } else if (isWin) {
      trade.status = TradeStatus.won;
      final payout = trade.amount + (trade.amount * payoutPercentage);
      if (isLiveAccount.value) liveBalance.value += payout; else demoBalance.value += payout;
      message = "Trade ended: Won! You won \$${(trade.amount * payoutPercentage).toStringAsFixed(2)}.";
      color = Colors.green;
    } else {
      trade.status = TradeStatus.lost;
      message = "Trade ended: Lost. Better luck next time.";
      color = Colors.red;
    }
    runningTrades.remove(trade);
    tradeHistory.insert(0, trade);
    Get.snackbar("Trade Result", message, backgroundColor: color, colorText: Colors.white);
  }

  void _scrollToEnd() {
    chartKey.currentState?.scrollToEnd();
  }

  void changeAsset(Asset asset) {
    selectedAsset.value = asset;
    _aggregateCandles();
  }

  void changeTimeframe(Timeframe tf) {
    selectedTimeframe.value = tf;
    _aggregateCandles();
  }
  void setInvestmentAmount(double amount) { investmentAmount.value = amount; }
  void setTradeDuration(int seconds) { tradeDurationSeconds.value = seconds; }
  void switchAccount(bool toLive) { isLiveAccount.value = toLive; }

  @override
  void onClose() {
    _candleTimer?.cancel();
    _liveUpdateTimer?.cancel();
    super.onClose();
  }
}