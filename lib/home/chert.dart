import 'package:flutter/material.dart';
import 'package:trading_home/home/utils/enums.dart';
import 'dart:math' show max, min;

import 'candle_data.dart';
import 'models/trade_model.dart';

class CandlestickChart extends StatefulWidget {
  final List<CandleData> candles;
  final List<Trade> runningTrades;
  final int candleTimeRemaining;
  final Timeframe selectedTimeframe;

  const CandlestickChart({
    super.key,
    required this.candles,
    required this.runningTrades,
    required this.candleTimeRemaining,
    required this.selectedTimeframe,
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

  _CandlestickPainter({
    required this.candles,
    required this.scale,
    required this.horizontalOffset,
    required this.runningTrades,
    required this.candleTimeRemaining,
    required this.selectedTimeframe,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double candleWidth = 10.0 * scale;
    final double spacing = 5.0 * scale;
    final double itemWidth = candleWidth + spacing;
    final double candleDurationMs = selectedTimeframe.minutes * 60 * 1000.0;

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

    // Draw Candles
    for (int i = 0; i < visibleCandles.length; i++) {
      final candle = visibleCandles[i];
      final realIndex = firstVisibleIndex + i;
      final double x = (realIndex * itemWidth) - horizontalOffset;

      final isBullish = candle.close >= candle.open;
      final paint = Paint()..color = isBullish ? Colors.green : Colors.red;

      canvas.drawLine(Offset(x + candleWidth / 2, getY(candle.high)), Offset(x + candleWidth / 2, getY(candle.low)), paint..strokeWidth = 1.5);
      canvas.drawRect(Rect.fromLTRB(x, getY(isBullish ? candle.close : candle.open), x + candleWidth, getY(isBullish ? candle.open : candle.close)), paint);

      if (realIndex == candles.length - 1) {
        final countdownText = "${candleTimeRemaining.toString().padLeft(2, '0')}s";
        _drawText(canvas, countdownText, Offset(x + candleWidth / 2 - 15, getY(candle.high) - 20), Colors.white, 12, backgroundColor: Colors.black.withOpacity(0.5));
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
    if (candles.isNotEmpty) {
      final double lastCandlePrice = candles.last.close;

      for (final trade in runningTrades) {
        final tradeY = getY(trade.entryPrice);
        if (tradeY < 0 || tradeY > size.height) continue;

        final startCandleIndex = candles.indexWhere((c) => c.timestamp >= trade.entryTime.millisecondsSinceEpoch);
        double startX;
        if (startCandleIndex != -1) {
          final startCandle = candles[startCandleIndex];
          final startCandleMs = startCandle.timestamp;
          final tradeEntryMs = trade.entryTime.millisecondsSinceEpoch;
          final offsetInMs = tradeEntryMs - startCandleMs;
          final offsetInPixels = (offsetInMs / candleDurationMs) * itemWidth;
          startX = (startCandleIndex * itemWidth) + offsetInPixels - horizontalOffset;
        } else {
          continue;
        }

        final tradeDurationMs = trade.expiryTime.millisecondsSinceEpoch - trade.entryTime.millisecondsSinceEpoch;
        final tradeLinePixels = (tradeDurationMs / candleDurationMs) * itemWidth;
        final endX = startX + tradeLinePixels;

        // Draw entry price line across the whole chart
        final entryPriceLinePaint = Paint()
          ..color = trade.color
          ..strokeWidth = 1.0;
        _drawDashedLine(canvas, Offset(0, tradeY), Offset(size.width, tradeY), entryPriceLinePaint, 5, 5);

        // Draw profit/loss area
        final currentPriceY = getY(lastCandlePrice);
        final isProfit = (trade.direction == TradeDirection.up && lastCandlePrice > trade.entryPrice) || (trade.direction == TradeDirection.down && lastCandlePrice < trade.entryPrice);
        final profitLossPaint = Paint()..color = (isProfit ? Colors.green : Colors.red).withOpacity(0.2);
        canvas.drawRect(Rect.fromLTRB(startX, tradeY, min(endX, size.width), currentPriceY), profitLossPaint);

        // Draw the duration line from entry to expiry
        final durationLinePaint = Paint()
          ..color = trade.color
          ..strokeWidth = 2.0;
        _drawDashedLine(canvas, Offset(startX, tradeY), Offset(endX, tradeY), durationLinePaint, 5, 5);

        // Draw start arrow
        final Path path = Path();
        path.moveTo(startX, tradeY);
        path.lineTo(startX + (trade.direction == TradeDirection.up ? 10 : -10), tradeY - (trade.direction == TradeDirection.up ? 10 : -10));
        path.lineTo(startX + (trade.direction == TradeDirection.up ? 10 : -10), tradeY + (trade.direction == TradeDirection.up ? 10 : -10));
        path.close();
        final arrowPaint = Paint()..color = trade.color;
        canvas.drawPath(path, arrowPaint);

        // Draw vertical expiry line
        final expiryPaint = Paint()..color = Colors.white..strokeWidth = 2.0;
        _drawDashedLine(canvas, Offset(endX, 0), Offset(endX, size.height), expiryPaint, 10, 5);

        // Draw timer text
        final remainingDuration = trade.expiryTime.difference(DateTime.now());
        final minutes = remainingDuration.inMinutes;
        final seconds = remainingDuration.inSeconds.remainder(60);
        final timerText = "${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";
        _drawText(canvas, timerText, Offset(endX + 5, 20), Colors.white, 12, backgroundColor: Colors.black.withOpacity(0.5));

        _drawText(canvas, trade.entryPrice.toStringAsFixed(4), Offset(10, tradeY - 8), Colors.white, 12, backgroundColor: trade.color);
      }
    }
  }

  void _drawText(Canvas canvas, String text, Offset position, Color color, double fontSize, {Color? backgroundColor}) {
    final textPainter = TextPainter(
        text: TextSpan(text: text, style: TextStyle(color: color, fontSize: fontSize, backgroundColor: backgroundColor, fontWeight: FontWeight.bold)),
        textDirection: TextDirection.ltr
    )..layout();
    textPainter.paint(canvas, position);
  }

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