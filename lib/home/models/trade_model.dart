// lib/home/models/trade_model.dart

import 'package:flutter/material.dart';
import '../utils/enums.dart';

class Trade {
  final String id;
  final Asset asset;
  final TradeDirection direction;
  final double amount;
  final double entryPrice;
  double? closePrice;
  final DateTime entryTime;
  final DateTime expiryTime;
  TradeStatus status;
  double? pnl;

  Trade({
    required this.id,
    required this.asset,
    required this.direction,
    required this.amount,
    required this.entryPrice,
    this.closePrice,
    required this.entryTime,
    required this.expiryTime,
    this.status = TradeStatus.running,
    this.pnl,
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

  // JSON serialization জন্য নতুন দুটি মেথড যোগ করা হয়েছে
  Map<String, dynamic> toJson() => {
    'id': id,
    'asset': asset.name,
    'direction': direction.name,
    'amount': amount,
    'entryPrice': entryPrice,
    'closePrice': closePrice,
    'entryTime': entryTime.toIso8601String(),
    'expiryTime': expiryTime.toIso8601String(),
    'status': status.name,
    'pnl': pnl,
  };

  factory Trade.fromJson(Map<String, dynamic> json) => Trade(
    id: json['id'],
    asset: Asset.values.firstWhere((e) => e.name == json['asset']),
    direction: TradeDirection.values.firstWhere((e) => e.name == json['direction']),
    amount: json['amount'],
    entryPrice: json['entryPrice'],
    closePrice: json['closePrice'],
    entryTime: DateTime.parse(json['entryTime']),
    expiryTime: DateTime.parse(json['expiryTime']),
    status: TradeStatus.values.firstWhere((e) => e.name == json['status']),
    pnl: json['pnl'],
  );
}