import 'package:flutter/material.dart';
import 'package:trading_home/home/utils/enums.dart';
import 'dart:math' show max, min;


import 'candle_data.dart';
import 'models/trade_model.dart';

// key ব্যবহারের জন্য StatefulWidget এর নাম পরিবর্তন করা হয়েছে
class CandlestickChart extends StatefulWidget {
  final List<CandleData> candles;
  final List<Trade> runningTrades;
  final int candleTimeRemaining;

  const CandlestickChart({
    super.key,
    required this.candles,
    required this.runningTrades,
    required this.candleTimeRemaining,
  });

  @override
  State<CandlestickChart> createState() => CandlestickChartState();
}

class CandlestickChartState extends State<CandlestickChart> {
  double _scale = 1.0; // Zoom level
  double _horizontalOffset = 0.0; // Pan position
  Offset? _dragStartPosition;

  @override
  void initState() {
    super.initState();
    // চার্ট শুরুতেই শেষ প্রান্তে দেখাবে
    WidgetsBinding.instance.addPostFrameCallback((_) => scrollToEnd(animate: false));
  }

  // নতুন ক্যান্ডেল আসলে চার্টকে শেষ প্রান্তে নিয়ে যাওয়ার জন্য
  @override
  void didUpdateWidget(covariant CandlestickChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.candles.length > oldWidget.candles.length) {
      scrollToEnd();
    }
  }

  // বাইরে থেকে কল করার জন্য পাবলিক মেথড
  void scrollToEnd({bool animate = true}) {
    if (!mounted || context.size == null) return;

    final double candleWidth = 10.0 * _scale;
    final double spacing = 5.0 * _scale;
    final double contentWidth = widget.candles.length * (candleWidth + spacing);
    final double maxOffset = contentWidth - context.size!.width;

    // অ্যানিমেশনসহ স্ক্রল করার ব্যবস্থা পরে যোগ করা যেতে পারে
    setState(() {
      _horizontalOffset = maxOffset.clamp(0.0, double.infinity);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.candles.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return GestureDetector(
      onScaleStart: (details) {
        _dragStartPosition = details.localFocalPoint;
      },
      onScaleUpdate: (details) {
        setState(() {
          // Horizontal Pan (1 finger drag)
          if (details.scale == 1.0 && _dragStartPosition != null) {
            final dx = details.localFocalPoint.dx - _dragStartPosition!.dx;
            _horizontalOffset -= dx;
            _dragStartPosition = details.localFocalPoint;
          }
          // Scale (pinch zoom)
          else if (details.scale != 1.0) {
            final newScale = (_scale * details.scale).clamp(0.2, 5.0);
            final focalPoint = details.localFocalPoint.dx;

            // Zoom in/out from the focal point
            final worldFocalX = (_horizontalOffset + focalPoint) / _scale;
            _horizontalOffset = (worldFocalX * newScale) - focalPoint;
            _scale = newScale;
          }
        });
      },
      onScaleEnd: (details) {
        _dragStartPosition = null;
      },
      child: CustomPaint(
        painter: _CandlestickPainter(
          candles: widget.candles,
          scale: _scale,
          horizontalOffset: _horizontalOffset,
          runningTrades: widget.runningTrades,
          candleTimeRemaining: widget.candleTimeRemaining,
        ),
        size: Size.infinite,
      ),
    );
  }
}

class _CandlestickPainter extends CustomPainter {
  final List<CandleData> candles;
  final double scale;
  final double horizontalOffset;
  final List<Trade> runningTrades;
  final int candleTimeRemaining;

  _CandlestickPainter({
    required this.candles,
    required this.scale,
    required this.horizontalOffset,
    required this.runningTrades,
    required this.candleTimeRemaining,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double candleWidth = 10.0 * scale;
    final double spacing = 5.0 * scale;
    final double itemWidth = candleWidth + spacing;

    // ক্যানভাস ক্লিপ করা হচ্ছে যাতে বাইরে কিছু আঁকা না যায়
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width, size.height));

    // শুধুমাত্র দৃশ্যমান ক্যান্ডেলগুলো বের করা হচ্ছে
    final int firstVisibleIndex = (horizontalOffset / itemWidth).floor().clamp(0, candles.length);
    final int lastVisibleIndex = ((horizontalOffset + size.width) / itemWidth).ceil().clamp(0, candles.length);

    if (firstVisibleIndex >= lastVisibleIndex) return;

    final visibleCandles = candles.getRange(firstVisibleIndex, lastVisibleIndex).toList();

    if (visibleCandles.isEmpty) return;

    final double minY = visibleCandles.map((c) => c.low).reduce(min) * 0.995;
    final double maxY = visibleCandles.map((c) => c.high).reduce(max) * 1.005;

    double getY(double price) {
      if (maxY == minY) return size.height / 2;
      return size.height - ((price - minY) / (maxY - minY)) * size.height;
    }

    // Draw Candles
    for (int i = 0; i < visibleCandles.length; i++) {
      final candle = visibleCandles[i];
      final realIndex = firstVisibleIndex + i;
      final double x = (realIndex * itemWidth) - horizontalOffset;

      final isGreen = candle.close >= candle.open;
      final paint = Paint()..color = isGreen ? Colors.green : Colors.red;

      canvas.drawLine(Offset(x + candleWidth / 2, getY(candle.high)), Offset(x + candleWidth / 2, getY(candle.low)), paint..strokeWidth = 1.5);
      canvas.drawRect(Rect.fromLTRB(x, getY(isGreen ? candle.close : candle.open), x + candleWidth, getY(isGreen ? candle.open : candle.close)), paint);

      // +++ নতুন কোড: এখানে টাইমার আঁকা হচ্ছে +++
      if (realIndex == candles.length - 1) { // যদি এটি সর্বশেষ ক্যান্ডেল হয়
        final countdownText = "${candleTimeRemaining.toString().padLeft(2, '0')}s";
        _drawText(
          canvas,
          countdownText,
          Offset(x, getY(candle.high) - 20), // ক্যান্ডেলের উচ্চতার উপরে
          Colors.white,
          12,
          backgroundColor: Colors.black.withOpacity(0.5),
        );
      }
    }

    // Draw Right-side UI (Grid, Price)
    final gridPaint = Paint()..color = Colors.grey[800]!..strokeWidth = 0.5;
    for (int i = 0; i <= 5; i++) {
      final y = size.height * i / 5;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
      final price = maxY - (i / 5) * (maxY - minY);
      _drawText(canvas, price.toStringAsFixed(2), Offset(size.width - 50, y - 6), Colors.grey[400]!, 10);
    }

    // Draw Running Trades
    for(final trade in runningTrades) {
      final tradeY = getY(trade.entryPrice);
      if(tradeY < 0 || tradeY > size.height) continue; // শুধু দৃশ্যমান ট্রেড আঁকা হচ্ছে
      final tradePaint = Paint()..color = trade.direction == TradeDirection.up ? Colors.green : Colors.red ..strokeWidth = 1.5;
      for (double i = 0; i < size.width; i += 10) canvas.drawLine(Offset(i, tradeY), Offset(i + 5, tradeY), tradePaint);
      _drawText(canvas, trade.entryPrice.toStringAsFixed(4), Offset(size.width - 60, tradeY - 8), Colors.white, 12, backgroundColor: tradePaint.color);
    }

    // Draw Current Price Line and Countdown (এই অংশটি এখন শুধুমাত্র দাম দেখাবে)
    if(candles.isNotEmpty) {
      final lastClose = candles.last.close;
      final currentY = getY(lastClose);
      final linePaint = Paint()..color = candles.last.close >= candles.last.open ? Colors.green : Colors.red;
      for (double i = 0; i < size.width; i += 10) canvas.drawLine(Offset(i, currentY), Offset(i + 5, currentY), linePaint);

      final priceText = lastClose.toStringAsFixed(4);
      _drawText(canvas, priceText, Offset(size.width - 60, currentY - 8), Colors.white, 12, backgroundColor: linePaint.color);
    }
  }

  void _drawText(Canvas canvas, String text, Offset position, Color color, double fontSize, {Color? backgroundColor}) {
    final textPainter = TextPainter(
        text: TextSpan(text: text, style: TextStyle(color: color, fontSize: fontSize, backgroundColor: backgroundColor, fontWeight: FontWeight.bold)),
        textDirection: TextDirection.ltr
    )..layout();
    textPainter.paint(canvas, position);
  }

  @override
  bool shouldRepaint(covariant _CandlestickPainter old) => true;
}