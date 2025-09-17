// lib/home/models/leaderboard_user.dart

import 'package:get/get.dart';

class LeaderboardUser {
  final String id;
  final String name;
  double balance;
  RxDouble pnl; // Changed to RxDouble for reactivity

  LeaderboardUser({
    required this.id,
    required this.name,
    required this.balance,
    double? initialBalance,  RxDouble? pnl,
  }) : pnl = (balance - (initialBalance ?? 10000.0)).obs; // Initialize pnl

  // JSON serialization
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'balance': balance,
    'pnl': pnl.value,
  };

  factory LeaderboardUser.fromJson(Map<String, dynamic> json) => LeaderboardUser(
    id: json['id'],
    name: json['name'],
    balance: json['balance'],
    pnl: (json['pnl'] as double).obs,
  );
}