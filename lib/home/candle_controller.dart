import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'candle_data.dart'; // নিশ্চিত করুন আপনার CandleData মডেলে 'Color? color' আছে

class CandleController extends GetxController {
  // আপনার গেটারগুলো ঠিক আছে
  int get runningCandleSeconds {
    if (candles.isEmpty) return 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    final lastTs = candles.last.timestamp;
    return ((now - lastTs) / 1000).floor();
  }

  // ... অন্যান্য ভেরিয়েবল ...
  final RxInt candleTimeRemaining = 0.obs;

  // +++ নতুন কোড: ব্লিঙ্ক করার অবস্থা নিয়ন্ত্রণের জন্য +++
  final RxBool isTimerBlinking = false.obs;

  // ... অন্যান্য কোড ...

  void _updateCandleCountdown() {
    final remaining = 60 - (DateTime.now().second % 60);
    candleTimeRemaining.value = remaining;

    // +++ নতুন কোড: ব্লিঙ্ক লজিক +++
    // যদি বাকি সময় ৫ সেকেন্ড বা তার কম হয়
    if (remaining <= 5) {
      // প্রতি সেকেন্ডে isTimerBlinking এর মান পরিবর্তন হবে (true/false)
      isTimerBlinking.value = !isTimerBlinking.value;
    } else {
      // যদি সময় ৫ সেকেন্ডের বেশি থাকে, তবে ব্লিঙ্ক বন্ধ থাকবে
      isTimerBlinking.value = false;
    }
  }


  // runningCandleElapsedSeconds এবং runningCandleRemainingSeconds এর জন্য Rx variable
  final RxInt _elapsedSeconds = 0.obs;
  final RxInt _remainingSeconds = 60.obs; // ডিফল্ট ১ মিনিট ক্যান্ডেল

  int get runningCandleElapsedSeconds => _elapsedSeconds.value;
  int get runningCandleRemainingSeconds => _remainingSeconds.value;


  final RxList<CandleData> candles = <CandleData>[].obs;
  final ScrollController scrollController = ScrollController();
  Timer? _newCandleTimer; // নতুন ক্যান্ডেল যোগ করার টাইমার
  Timer? _liveCandleUpdateTimer; // সর্বশেষ ক্যান্ডেলকে লাইভ আপডেট করার টাইমার
  Timer? _countdownTimer; // UI তে কাউন্টডাউন দেখানোর টাইমার

  int _demoCandleIndex = 0; // ডেমো ক্যান্ডেলের জন্য ইনডেক্স

  // আপনার ডেমো ক্যান্ডেল লিস্ট
  final List<CandleData> demoCandles = [
    CandleData(timestamp: DateTime.now().subtract(const Duration(minutes: 14)).millisecondsSinceEpoch, open: 150, high: 155, low: 145, close: 152),
    CandleData(timestamp: DateTime.now().subtract(const Duration(minutes: 13)).millisecondsSinceEpoch, open: 152, high: 160, low: 150, close: 158),
    CandleData(timestamp: DateTime.now().subtract(const Duration(minutes: 12)).millisecondsSinceEpoch, open: 158, high: 159, low: 153, close: 154),
    CandleData(timestamp: DateTime.now().subtract(const Duration(minutes: 11)).millisecondsSinceEpoch, open: 154, high: 157, low: 148, close: 156),
    CandleData(timestamp: DateTime.now().subtract(const Duration(minutes: 10)).millisecondsSinceEpoch, open: 156, high: 165, low: 155, close: 162),
    CandleData(timestamp: DateTime.now().subtract(const Duration(minutes: 9)).millisecondsSinceEpoch, open: 162, high: 168, low: 160, close: 164),
    CandleData(timestamp: DateTime.now().subtract(const Duration(minutes: 8)).millisecondsSinceEpoch, open: 164, high: 170, low: 162, close: 168),
    CandleData(timestamp: DateTime.now().subtract(const Duration(minutes: 7)).millisecondsSinceEpoch, open: 168, high: 172, low: 166, close: 170),
    CandleData(timestamp: DateTime.now().subtract(const Duration(minutes: 6)).millisecondsSinceEpoch, open: 170, high: 173, low: 167, close: 171),
    CandleData(timestamp: DateTime.now().subtract(const Duration(minutes: 5)).millisecondsSinceEpoch, open: 171, high: 174, low: 169, close: 170),
    CandleData(timestamp: DateTime.now().subtract(const Duration(minutes: 4)).millisecondsSinceEpoch, open: 170, high: 175, low: 170, close: 174),
    CandleData(timestamp: DateTime.now().subtract(const Duration(minutes: 3)).millisecondsSinceEpoch, open: 174, high: 177, low: 172, close: 172),
    CandleData(timestamp: DateTime.now().subtract(const Duration(minutes: 2)).millisecondsSinceEpoch, open: 172, high: 179, low: 174, close: 178),
    CandleData(timestamp: DateTime.now().subtract(const Duration(minutes: 1)).millisecondsSinceEpoch, open: 178, high: 181, low: 176, close: 177),
    // সর্বশেষ ক্যান্ডেলটি বর্তমান সময়ের কাছাকাছি রাখুন
    // CandleData(timestamp: DateTime.now().millisecondsSinceEpoch, open: 177, high: 183, low: 178, close: 182),
  ];

  // কনস্ট্রাক্টর এর পরিবর্তে onInit ব্যবহার করা ভালো GetX এ
  @override
  void onInit() {
    super.onInit();
    _loadInitialCandles();
    _startNewCandleTimer(); // প্রতি মিনিটে নতুন ক্যান্ডেল
    _startLiveCandleUpdate(); // সর্বশেষ ক্যান্ডেলের লাইভ মুভমেন্ট
    _startCountdownTimer(); // UI তে টাইমার দেখানোর জন্য
  }

  void _loadInitialCandles() {
    // ডেমো ক্যান্ডেল থেকে লোড করুন
    // timestamp গুলোকে ಹಿಂದಿನ நிமிடಗಳಿಗೆ ಹೊಂದಿಸಿ
    // এতে চার্টে একটি হিস্টোরি দেখা যাবে
    candles.assignAll(demoCandles); // সব ডেমো ক্যান্ডেল লোড করুন
    _demoCandleIndex = demoCandles.length; // পরবর্তী ক্যান্ডেলের জন্য ইনডেক্স

    if (candles.isNotEmpty) {
      _updateCandleTimers(); // ক্যান্ডেল টাইমার আপডেট করুন
    }
    _scrollToEnd(isInitial: true);
  }

  void _startNewCandleTimer() {
    _newCandleTimer?.cancel();
    _newCandleTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _addNextCandle();
    });
  }

  void _addNextCandle() {
    CandleData newCandle;
    final now = DateTime.now().millisecondsSinceEpoch;

    if (candles.isNotEmpty) {
      final lastCandle = candles.last;
      double openPrice = lastCandle.close;

      // ডেমো ক্যান্ডেল শেষ হলে র‍্যান্ডম ক্যান্ডেল জেনারেট করুন
      // অথবা, আপনি _demoCandleIndex ব্যবহার করে demoCandles থেকে নিতে পারেন
      // যদি চান যে ডেমো ক্যান্ডেলগুলো রিপিট হোক বা নতুন ডেমো ক্যান্ডেল যোগ হোক
      // এই উদাহরণে, আমরা নতুন র‍্যান্ডম ক্যান্ডেল তৈরি করব
      newCandle = _generateRandomCandle(openPrice, now);

    } else {
      // যদি candles খালি থাকে, একটি প্রাথমিক র‍্যান্ডম ক্যান্ডেল
      double initialPrice = demoCandles.isNotEmpty ? demoCandles.first.open : 150.0;
      newCandle = _generateRandomCandle(initialPrice, now);
    }

    candles.add(newCandle);
    _updateCandleTimers();
    _scrollToEnd();

    // নতুন ক্যান্ডেল তৈরি হলে লাইভ আপডেট টাইমার রিস্টার্ট করা হতে পারে
    // অথবা নিশ্চিত করুন যে এটি সর্বশেষ ক্যান্ডেলকেই আপডেট করছে
    _startLiveCandleUpdate();
  }

  CandleData _generateRandomCandle(double prevClose, int timestamp) {
    double open = prevClose;
    // বাস্তবসম্মত মুভমেন্টের জন্য ছোট পরিবর্তন
    double close = open + (Random().nextDouble() * 2 - 1) * (open * 0.01); // +/- 1% of open
    if (close <= 0) close = 0.1;

    double highVariance = Random().nextDouble() * (open * 0.005); // 0.5% variance for high
    double lowVariance = Random().nextDouble() * (open * 0.005);  // 0.5% variance for low

    double high = max(open, close) + highVariance;
    double low = min(open, close) - lowVariance;
    if (low <= 0) low = 0.05;
    if (high < low) high = low + 0.1; // Ensure high > low

    return CandleData(
      timestamp: timestamp,
      open: open,
      high: high,
      low: low,
      close: close,
    );
  }

  void _startLiveCandleUpdate() {
    _liveCandleUpdateTimer?.cancel(); // আগেরটা থাকলে বন্ধ করুন
    _liveCandleUpdateTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) { // Update interval
      if (candles.isEmpty) return;

      final lastIndex = candles.length - 1;
      final currentLastCandle = candles[lastIndex];

      // আগের _startLiveCandleUpdate মেথডের লজিক এখানে ব্যবহার করুন
      final double baseVolatility = _getRandomArbitrary(0.999, 1.001); // খুব ছোট পরিবর্তন
      final double trend = _getRandomArbitrary(-0.1, 0.1); // ছোট ট্রেন্ড
      final double noise = _getRandomArbitrary(-0.05, 0.05); // আরও কম নয়েজ
      double newClose = (currentLastCandle.close * baseVolatility) + trend + noise;

      if (newClose <= 0) newClose = currentLastCandle.close; // ০ বা নেগেটিভ হওয়া থেকে বাঁচানো

      double newHigh = currentLastCandle.high;
      double newLow = currentLastCandle.low;

      if (newClose > currentLastCandle.high) {
        newHigh = newClose + _getRandomArbitrary(0, 0.05); // উইকের জন্য ছোট মান
      } else {
        newHigh = max(currentLastCandle.high, currentLastCandle.open); // নিশ্চিত করুন হাই ওপেনের থেকে কম না হয়
      }

      if (newClose < currentLastCandle.low) {
        newLow = newClose - _getRandomArbitrary(0, 0.05);
      } else {
        newLow = min(currentLastCandle.low, currentLastCandle.open); // নিশ্চিত করুন লো ওপেনের থেকে বেশি না হয়
      }
      if (newHigh < newLow) { // এটি প্রায় ঘটবে না, তবে সেফটি চেক
        final temp = newHigh;
        newHigh = newLow;
        newLow = temp;
        if (newLow > newClose) newLow = newClose - 0.01;
        if (newHigh < newClose) newHigh = newClose + 0.01;
      }


      final updatedCandle = CandleData(
        timestamp: currentLastCandle.timestamp,
        open: currentLastCandle.open,
        high: newHigh,
        low: newLow,
        close: newClose,
        color: currentLastCandle.color, // রঙ বজায় রাখুন
      );
      candles[lastIndex] = updatedCandle;
    });
  }

  double _getRandomArbitrary(double min, double max) {
    return Random().nextDouble() * (max - min) + min;
  }

  void _scrollToEnd({bool isInitial = false}) {
    if (scrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (scrollController.hasClients) { // আবার চেক করুন, কারণ callback এ client চলে যেতে পারে
          scrollController.animateTo(
            scrollController.position.maxScrollExtent,
            duration: Duration(milliseconds: isInitial ? 0 : 300), // শুরুতে এনিমেশন ছাড়া
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  void _updateCandleTimers() {
    if (candles.isEmpty) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    final lastCandleTimestamp = candles.last.timestamp;
    const int candleDurationMs = 60000; // 1 minute

    final elapsedMs = now - lastCandleTimestamp;
    _elapsedSeconds.value = (elapsedMs / 1000).floor();
    _remainingSeconds.value = ((candleDurationMs - elapsedMs) / 1000).clamp(0, 60).floor();
  }


  void _startCountdownTimer() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateCandleTimers(); // প্রতি সেকেন্ডে elapsed এবং remaining সময় আপডেট করুন
      if (_remainingSeconds.value <= 0) {
        // নতুন ক্যান্ডেল _newCandleTimer থেকে তৈরি হবে,
        // তখন _updateCandleTimers আবার কল হবে এবং _remainingSeconds রিসেট হবে।
        // এখানে আর কিছু করার দরকার নেই, যদি _newCandleTimer ঠিকভাবে কাজ করে।
      }
    });
  }


  // --- আপনার আগের মেথডগুলো (কিছু পরিবর্তন সহ) ---

  void makeCurrentCandleRed() {
    _cancelGradualUpdates(); // গ্র্যাজুয়াল আপডেট বন্ধ করুন
    if (candles.isNotEmpty) {
      final lastCandle = candles.last;
      candles[candles.length - 1] = CandleData(
        timestamp: lastCandle.timestamp,
        open: lastCandle.open,
        high: lastCandle.high,
        low: lastCandle.low,
        close: lastCandle.close,
        color: Colors.red, // রঙ যোগ করা হলো
      );
    }
  }

  void makeCurrentCandleGreen() {
    _cancelGradualUpdates();
    if (candles.isNotEmpty) {
      final lastCandle = candles.last;
      candles[candles.length - 1] = CandleData(
        timestamp: lastCandle.timestamp,
        open: lastCandle.open,
        high: lastCandle.high,
        low: lastCandle.low,
        close: lastCandle.close,
        color: Colors.green, // রঙ যোগ করা হলো
      );
    }
  }

  Timer? _gradualUpdateTimer; // গ্র্যাজুয়াল আপডেটের জন্য আলাদা টাইমার

  void _cancelGradualUpdates() {
    _gradualUpdateTimer?.cancel();
    _gradualUpdateTimer = null;
    // গ্র্যাজুয়াল আপডেট বন্ধ হলে, সাধারণ লাইভ আপডেট আবার শুরু করুন
    if (_liveCandleUpdateTimer == null || !_liveCandleUpdateTimer!.isActive) {
      _startLiveCandleUpdate();
    }
  }

  void graduallyDecreaseCandle() {
    if (candles.isEmpty) return;
    _liveCandleUpdateTimer?.cancel(); // সাধারণ লাইভ আপডেট বন্ধ করুন
    _gradualUpdateTimer?.cancel(); // আগের গ্র্যাজুয়াল টাইমার থাকলে বন্ধ করুন

    final lastIndex = candles.length - 1;
    _gradualUpdateTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (candles.length <= lastIndex) { // যদি ক্যান্ডেল লিস্ট ছোট হয়ে যায়
        timer.cancel();
        _startLiveCandleUpdate(); // স্বাভাবিক আপডেট শুরু করুন
        return;
      }
      final lastCandle = candles[lastIndex];
      final newClose = (lastCandle.close - 0.1).clamp(0.01, double.infinity); // খুব ছোট স্টেপ, 0 এর নিচে না যায়

      candles[lastIndex] = CandleData(
        timestamp: lastCandle.timestamp,
        open: lastCandle.open,
        high: lastCandle.high, // হাই পরিবর্তন না করা ভালো, অথবা newClose এর সাথে সামঞ্জস্যপূর্ণ করুন
        low: newClose < lastCandle.low ? newClose : lastCandle.low, // লো newClose এর থেকে নিচে যেতে পারে
        close: newClose,
        color: Colors.red.withOpacity(0.7),
      );

      // একটি নির্দিষ্ট সীমা পর্যন্ত কমানো, অথবা একটি নির্দিষ্ট সময় পর বন্ধ করা
      // উদাহরণ: যদি ওপেন প্রাইসের থেকে ১০% কমে যায়
      if (newClose <= lastCandle.open * 0.98 || newClose <= 0.1) {
        timer.cancel();
        _startLiveCandleUpdate(); // স্বাভাবিক আপডেট শুরু করুন
      }
    });
  }

  void graduallyIncreaseCandle() {
    if (candles.isEmpty) return;
    _liveCandleUpdateTimer?.cancel();
    _gradualUpdateTimer?.cancel();

    final lastIndex = candles.length - 1;
    _gradualUpdateTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (candles.length <= lastIndex) {
        timer.cancel();
        _startLiveCandleUpdate();
        return;
      }
      final lastCandle = candles[lastIndex];
      final newClose = lastCandle.close + 0.1; // খুব ছোট স্টেপ

      candles[lastIndex] = CandleData(
        timestamp: lastCandle.timestamp,
        open: lastCandle.open,
        high: newClose > lastCandle.high ? newClose : lastCandle.high,
        low: lastCandle.low,
        close: newClose,
        color: Colors.green.withOpacity(0.7),
      );

      // উদাহরণ: যদি ওপেন প্রাইসের থেকে ১০% বেড়ে যায়
      if (newClose >= lastCandle.open * 1.02) {
        timer.cancel();
        _startLiveCandleUpdate();
      }
    });
  }


  @override
  void onClose() {
    _newCandleTimer?.cancel();
    _liveCandleUpdateTimer?.cancel();
    _countdownTimer?.cancel();
    _gradualUpdateTimer?.cancel();
    scrollController.dispose();
    super.onClose();
  }
}

