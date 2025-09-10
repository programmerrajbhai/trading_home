import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../controllers/trading_controller.dart';
import '../models/trade_model.dart';
import '../utils/enums.dart';


class TradeHistoryScreen extends StatelessWidget {
  const TradeHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final TradingController controller = Get.find();
    return Scaffold(
      appBar: AppBar(title: const Text("Trade History"), backgroundColor: const Color(0xFF061B32)),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0E1012), Color(0xFF061B32)],
          ),
        ),
        // child: Obx(() {
        //   if (controller.tradeHistory.isEmpty) return const Center(child: Text("No trade history yet."));
        //   return ListView.builder(
        //     itemCount: controller.tradeHistory.length,
        //     itemBuilder: (context, index) => _TradeHistoryTile(trade: controller.tradeHistory[index]),
        //   );
        // }),
      ),
    );
  }
}

class _TradeHistoryTile extends StatelessWidget {
  final Trade trade;
  const _TradeHistoryTile({required this.trade});

  @override
  Widget build(BuildContext context) {
    final icon = trade.direction == TradeDirection.up ? Icons.arrow_upward : Icons.arrow_downward;
    final timeFormat = DateFormat('HH:mm:ss');
    return Card(
      color: Colors.black.withOpacity(0.3),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Row(children: [
              Icon(icon, color: trade.color, size: 28),
              const SizedBox(width: 12),
              Text("\$${trade.amount.toStringAsFixed(2)}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ]),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: trade.color, borderRadius: BorderRadius.circular(20)),
              child: Text(trade.status.name.toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
            ),
          ]),
          const Divider(height: 24),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            _buildInfoColumn("Entry", trade.entryPrice.toStringAsFixed(4)),
            _buildInfoColumn("Close", trade.closePrice?.toStringAsFixed(4) ?? 'N/A'),
            _buildInfoColumn("Time", timeFormat.format(trade.entryTime)),
          ]),
        ]),
      ),
    );
  }

  Widget _buildInfoColumn(String title, String value) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      const SizedBox(height: 4),
      Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
    ]);
  }
}