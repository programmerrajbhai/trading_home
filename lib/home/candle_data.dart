import 'dart:ui';

import 'package:flutter/src/material/colors.dart';

class CandleData {
  final int timestamp;
  final double open;
  final double high;
  final double low;
  final double close;

  CandleData({
    required this.timestamp,
    required this.open,
    required this.high,
    required this.low,
    required this.close,  Color? color,
  });

  get color => null;
}