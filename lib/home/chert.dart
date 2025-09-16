import 'package:flutter/material.dart';
import 'package:trading_home/home/utils/enums.dart';
import 'dart:math' show max, min;
import 'package:intl/intl.dart';
import 'dart:ui' as ui;

import 'candle_data.dart';
import 'models/trade_model.dart';

class CandlestickChart extends StatefulWidget {
  final List<CandleData> candles;
  final List<Trade> runningTrades;
  final int candleTimeRemaining;
  final Timeframe selectedTimeframe;
  final ChartType selectedChartType; // নতুন প্যারামিটার

  const CandlestickChart({
    super.key,
    required this.candles,
    required this.runningTrades,
    required this.candleTimeRemaining,
    required this.selectedTimeframe,
    required this.selectedChartType, // নতুন প্যারামিটার
  });

  @override
  State<CandlestickChart> createState() => CandlestickChartState();
}

class CandlestickChartState extends State<CandlestickChart> {
  double _scale = 1.0;
  double _horizontalOffset = 0.0;
  Offset? _dragStartPosition;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => scrollToEnd(animate: false));
  }

  @override
  void didUpdateWidget(covariant CandlestickChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.candles.length > oldWidget.candles.length) {
      scrollToEnd();
    }
  }

  void scrollToEnd({bool animate = true}) {
    if (!mounted || context.size == null) return;
    final double candleWidth = 10.0 * _scale;
    final double spacing = 5.0 * _scale;
    final double contentWidth = widget.candles.length * (candleWidth + spacing);
    final double maxOffset = contentWidth - context.size!.width;
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
          if (details.scale == 1.0 && _dragStartPosition != null) {
            final dx = details.localFocalPoint.dx - _dragStartPosition!.dx;
            _horizontalOffset -= dx;
            _dragStartPosition = details.localFocalPoint;
          } else if (details.scale != 1.0) {
            final newScale = (_scale * details.scale).clamp(0.2, 5.0);
            final focalPoint = details.localFocalPoint.dx;
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
          selectedTimeframe: widget.selectedTimeframe,
          chartType: widget.selectedChartType, // নতুন প্যারামিটার পাস করুন
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
  final Timeframe selectedTimeframe;
  final ChartType chartType; // নতুন প্রপার্টি

  _CandlestickPainter({
    required this.candles,
    required this.scale,
    required this.horizontalOffset,
    required this.runningTrades,
    required this.candleTimeRemaining,
    required this.selectedTimeframe,
    required this.chartType, // নতুন প্রপার্টি
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double candleWidth = 10.0 * scale;
    final double spacing = 5.0 * scale;
    final double itemWidth = candleWidth + spacing;
    final double candleDurationMs = selectedTimeframe.minutes * 60 * 1000.0;
    const double priceLabelWidth = 60;

    canvas.clipRect(Rect.fromLTWH(0, 0, size.width, size.height));

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

    // চার্টের ধরন অনুযায়ী আঁকার জন্য switch স্টেটমেন্ট ব্যবহার করুন
    switch (chartType) {
      case ChartType.candlestick:
        _drawCandlestickChart(canvas, size, visibleCandles, firstVisibleIndex,
            getY, candleWidth, itemWidth);
        break;
      case ChartType.line:
        _drawLineChart(canvas, size, visibleCandles, firstVisibleIndex, getY,
            itemWidth);
        break;
      case ChartType.bar:
        _drawBarChart(canvas, size, visibleCandles, firstVisibleIndex, getY,
            candleWidth, itemWidth);
        break;
    }

    // Draw Current Price Line
    if (candles.isNotEmpty) {
      final lastClose = candles.last.close;
      final currentY = getY(lastClose);
      final linePaint = Paint()
        ..color = Colors.yellow
        ..strokeWidth = 2.0;

      _drawDashedLine(canvas, Offset(0, currentY), Offset(size.width - priceLabelWidth, currentY), linePaint, 8, 4);
      _drawText(canvas, lastClose.toStringAsFixed(4), Offset(size.width - priceLabelWidth, currentY - 8), Colors.white, 12, backgroundColor: linePaint.color);
    }

    // Draw Candle Countdown Timer
    if (candleTimeRemaining > 0 && candles.isNotEmpty) {
      final lastCandle = candles.last;
      final double x = ((candles.length - 1) * itemWidth) - horizontalOffset + candleWidth/2;
      final double y = getY(lastCandle.high) - 20;

      final timerText = "${(candleTimeRemaining ~/ 60).toString().padLeft(2,'0')}:${(candleTimeRemaining % 60).toString().padLeft(2,'0')}";
      final textPainter = TextPainter(
        text: TextSpan(
          text: timerText,
          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
        ),
        textDirection: ui.TextDirection.ltr,
      );
      textPainter.layout();

      final backgroundPaint = Paint()..color = Colors.black.withOpacity(0.7);
      canvas.drawRect(
        Rect.fromLTWH(x - textPainter.width/2 - 4, y - 2, textPainter.width + 8, textPainter.height + 4),
        backgroundPaint,
      );
      textPainter.paint(canvas, Offset(x - textPainter.width/2, y));
    }

    // Draw Price Axis and Time Axis
    _drawPriceAxis(canvas, size, minY, maxY, getY, priceLabelWidth);
    _drawTimeAxis(canvas, size, firstVisibleIndex, lastVisibleIndex, itemWidth, horizontalOffset, candles);

    // Draw Running Trades
    _drawRunningTrades(canvas, size, getY, priceLabelWidth, itemWidth, candleDurationMs);
  }

  void _drawCandlestickChart(
      Canvas canvas,
      Size size,
      List<CandleData> visibleCandles,
      int firstVisibleIndex,
      Function getY,
      double candleWidth,
      double itemWidth) {
    for (int i = 0; i < visibleCandles.length; i++) {
      final candle = visibleCandles[i];
      final realIndex = firstVisibleIndex + i;
      final double x = (realIndex * itemWidth) - horizontalOffset;

      final isBullish = candle.close >= candle.open;
      final paint = Paint()..color = isBullish ? Colors.green : Colors.red;

      canvas.drawLine(
        Offset(x + candleWidth / 2, getY(candle.high)),
        Offset(x + candleWidth / 2, getY(candle.low)),
        paint..strokeWidth = 1.5,
      );
      canvas.drawRect(
        Rect.fromLTRB(
            x,
            getY(isBullish ? candle.close : candle.open),
            x + candleWidth,
            getY(isBullish ? candle.open : candle.close)),
        paint,
      );
    }
  }

  void _drawLineChart(Canvas canvas, Size size, List<CandleData> visibleCandles,
      int firstVisibleIndex, Function getY, double itemWidth) {
    final linePaint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final path = Path();
    for (int i = 0; i < visibleCandles.length; i++) {
      final candle = visibleCandles[i];
      final realIndex = firstVisibleIndex + i;
      final double x =
          (realIndex * itemWidth) - horizontalOffset + (itemWidth / 4);
      final double y = getY(candle.close);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, linePaint);
  }

  void _drawBarChart(
      Canvas canvas,
      Size size,
      List<CandleData> visibleCandles,
      int firstVisibleIndex,
      Function getY,
      double candleWidth,
      double itemWidth) {
    for (int i = 0; i < visibleCandles.length; i++) {
      final candle = visibleCandles[i];
      final realIndex = firstVisibleIndex + i;
      final double x = (realIndex * itemWidth) - horizontalOffset;

      final isBullish = candle.close >= candle.open;
      final paint = Paint()
        ..color = isBullish ? Colors.green : Colors.red
        ..strokeWidth = 1.5;

      // High-low line
      canvas.drawLine(
        Offset(x + candleWidth / 2, getY(candle.high)),
        Offset(x + candleWidth / 2, getY(candle.low)),
        paint,
      );

      // Open tick
      canvas.drawLine(
        Offset(x, getY(candle.open)),
        Offset(x + candleWidth / 2, getY(candle.open)),
        paint,
      );

      // Close tick
      canvas.drawLine(
        Offset(x + candleWidth / 2, getY(candle.close)),
        Offset(x + candleWidth, getY(candle.close)),
        paint,
      );
    }
  }

  void _drawPriceAxis(Canvas canvas, Size size, double minY, double maxY, Function getY, double priceLabelWidth) {
    final gridPaint = Paint()..color = Colors.grey[800]!..strokeWidth = 0.5;
    final priceRange = maxY - minY;
    final textPainter = TextPainter(textDirection: ui.TextDirection.ltr);

    for (int i = 0; i <= 5; i++) {
      final y = size.height * i / 5;
      canvas.drawLine(Offset(0, y), Offset(size.width - priceLabelWidth, y), gridPaint);
      final price = maxY - (i / 5) * priceRange;

      textPainter.text = TextSpan(text: price.toStringAsFixed(2), style: TextStyle(color: Colors.grey[400], fontSize: 10));
      textPainter.layout();
      textPainter.paint(canvas, Offset(size.width - priceLabelWidth + 5, y - textPainter.height / 2));
    }
  }

  void _drawTimeAxis(Canvas canvas, Size size, int firstVisibleIndex, int lastVisibleIndex, double itemWidth, double horizontalOffset, List<CandleData> candles) {
    final timePaint = Paint()..color = Colors.grey[800]!..strokeWidth = 0.5;
    final textPainter = TextPainter(textDirection: ui.TextDirection.ltr);
    final timeFormat = DateFormat('HH:mm');

    for (int i = firstVisibleIndex; i < lastVisibleIndex; i++) {
      final candle = candles[i];
      final x = (i * itemWidth) - horizontalOffset + itemWidth / 2;

      if (i % 5 == 0) {
        canvas.drawLine(Offset(x, size.height), Offset(x, size.height - 10), timePaint);

        final timeText = timeFormat.format(DateTime.fromMillisecondsSinceEpoch(candle.timestamp));
        textPainter.text = TextSpan(text: timeText, style: TextStyle(color: Colors.grey[400], fontSize: 10));
        textPainter.layout();
        textPainter.paint(canvas, Offset(x - textPainter.width / 2, size.height - 20));
      }
    }
  }

  void _drawRunningTrades(Canvas canvas, Size size, Function getY, double priceLabelWidth, double itemWidth, double candleDurationMs) {
    final double lastCandlePrice = candles.last.close;
    final textPainter = TextPainter(textDirection: ui.TextDirection.ltr);

    for (final trade in runningTrades) {
      final tradeY = getY(trade.entryPrice);
      if (tradeY < 0 || tradeY > size.height) continue;

      final startCandleIndex = candles.indexWhere((c) => c.timestamp >= trade.entryTime.millisecondsSinceEpoch);
      if (startCandleIndex == -1) continue;

      final startCandle = candles[startCandleIndex];
      final startCandleMs = startCandle.timestamp;
      final tradeEntryMs = trade.entryTime.millisecondsSinceEpoch;
      final offsetInMs = tradeEntryMs - startCandleMs;
      final offsetInPixels = (offsetInMs / candleDurationMs) * itemWidth;
      final startX = (startCandleIndex * itemWidth) + offsetInPixels - horizontalOffset;

      final tradeDurationMs = trade.expiryTime.millisecondsSinceEpoch - trade.entryTime.millisecondsSinceEpoch;
      final tradeLinePixels = (tradeDurationMs / candleDurationMs) * itemWidth;
      final endX = startX + tradeLinePixels;

      final currentPriceY = getY(lastCandlePrice);
      final isProfit = (trade.direction == TradeDirection.up && lastCandlePrice > trade.entryPrice) || (trade.direction == TradeDirection.down && lastCandlePrice < trade.entryPrice);

      final entryPriceLinePaint = Paint()
        ..color = trade.color
        ..strokeWidth = 2.0;

      canvas.drawLine(Offset(startX, tradeY), Offset(endX, tradeY), entryPriceLinePaint);

      final profitLossPaint = Paint()
        ..color = (isProfit ? Colors.green : Colors.red).withOpacity(0.2);
      canvas.drawRect(Rect.fromLTRB(startX, tradeY, endX, currentPriceY), profitLossPaint);

      final expiryLinePaint = Paint()
        ..color = Colors.white
        ..strokeWidth = 2.0;
      canvas.drawLine(Offset(endX, 0), Offset(endX, size.height), expiryLinePaint);

      final priceTagPaint = Paint()..color = trade.color;
      _drawText(canvas, trade.entryPrice.toStringAsFixed(4), Offset(size.width - priceLabelWidth, tradeY - 8), Colors.white, 12, backgroundColor: priceTagPaint.color);

      final remainingDuration = trade.expiryTime.difference(DateTime.now());
      final minutes = remainingDuration.inMinutes;
      final seconds = remainingDuration.inSeconds.remainder(60);
      final timerText = "${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";

      final timerBackgroundPaint = Paint()..color = Colors.black.withOpacity(0.7);
      textPainter.text = TextSpan(text: timerText, style: const TextStyle(color: Colors.white, fontSize: 12));
      textPainter.layout();

      canvas.drawRect(
        Rect.fromLTWH(endX - textPainter.width / 2 - 5, 20, textPainter.width + 10, textPainter.height + 4),
        timerBackgroundPaint,
      );
      textPainter.paint(canvas, Offset(endX - textPainter.width / 2, 22));
    }
  }

  void _drawText(Canvas canvas, String text, Offset position, Color color, double fontSize, {Color? backgroundColor}) {
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: TextStyle(color: color, fontSize: fontSize, backgroundColor: backgroundColor, fontWeight: FontWeight.bold)),
      textDirection: ui.TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, position);
  }
  ///
  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint, double dashWidth, double dashSpace) {
    double distance = (end - start).distance;
    final double dashCount = (distance / (dashWidth + dashSpace)).floor().toDouble();
    for (int i = 0; i < dashCount; i++) {
      final startDash = start + (end - start) * (i * (dashWidth + dashSpace)) / distance;
      final endDash = start + (end - start) * (i * (dashWidth + dashSpace) + dashWidth) / distance;
      canvas.drawLine(startDash, endDash, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _CandlestickPainter old) => true;
}