import 'package:flutter/material.dart';

import '../utils/enums.dart';

class Trade {
  final String id;
  final TradeDirection direction;
  final double amount;
  final double entryPrice;
  double? closePrice;
  final DateTime entryTime;
  final DateTime expiryTime;
  TradeStatus status;

  Trade({
    required this.id,
    required this.direction,
    required this.amount,
    required this.entryPrice,
    this.closePrice,
    required this.entryTime,
    required this.expiryTime,
    this.status = TradeStatus.running,
  });

  Color get color {
    switch (status) {
      case TradeStatus.running:
        return Colors.blue;
      case TradeStatus.won:
        return Colors.green;
      case TradeStatus.lost:
        return Colors.red;
      case TradeStatus.draw:
        return Colors.grey;
    }
  }
}