import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../controllers/trading_controller.dart';
import '../models/trade_model.dart';
import '../utils/enums.dart';


class TradeHistoryPopup extends StatelessWidget {
  final TradingController controller = Get.find();

  TradeHistoryPopup({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      backgroundColor: const Color(0xFF0E1012).withOpacity(0.9),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.6,
        width: MediaQuery.of(context).size.width * 0.9,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("All Trades", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Get.back(),
                ),
              ],
            ),
            const Divider(color: Colors.grey),
            Expanded(
              child: Obx(() {
                // +++ এখন আমরা নতুন combinedTradeList ব্যবহার করবো +++
                final trades = controller.combinedTradeList;
                if (trades.isEmpty) {
                  return const Center(child: Text("No trades yet.", style: const TextStyle(color: Colors.white70)));
                }
                return ListView.builder(
                  itemCount: trades.length,
                  itemBuilder: (context, index) {
                    final trade = trades[index];
                    return _TradeHistoryTile(
                      key: ValueKey(trade.id),
                      trade: trade,
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

// +++ এই উইজেটটিকে StatefulWidget-এ পরিণত করা হয়েছে +++
class _TradeHistoryTile extends StatefulWidget {
  final Trade trade;
  const _TradeHistoryTile({super.key, required this.trade});

  @override
  State<_TradeHistoryTile> createState() => _TradeHistoryTileState();
}

class _TradeHistoryTileState extends State<_TradeHistoryTile> {
  Timer? _timer;
  Duration _remainingTime = Duration.zero;

  final TradingController controller = Get.find();

  @override
  void initState() {
    super.initState();
    // যদি ট্রেডটি রানিং থাকে, তবে টাইমার চালু হবে
    if (widget.trade.status == TradeStatus.running) {
      _updateRemainingTime();
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        _updateRemainingTime();
      });
    }
  }

  void _updateRemainingTime() {
    if (!mounted) return; // উইজেট unmount হলে যেন error না আসে
    final now = DateTime.now();
    if (now.isAfter(widget.trade.expiryTime)) {
      _timer?.cancel();
      // কন্ট্রোলার নিজে থেকেই ট্রেড সেটেল করবে, তাই এখানে কিছু করার দরকার নেই
      if (mounted) setState(() {});
    } else {
      setState(() {
        _remainingTime = widget.trade.expiryTime.difference(now);
      });
    }
  }

  @override
  void dispose() {
    // উইজেট dispose হওয়ার সময় টাইমার বন্ধ করা জরুরি
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final trade = widget.trade;
    final icon = trade.direction == TradeDirection.up ? Icons.arrow_upward : Icons.arrow_downward;
    final timeFormat = DateFormat('HH:mm:ss');
    return Card(
      color: Colors.black.withOpacity(0.3),
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Row(children: [
              Icon(icon, color: trade.color, size: 24),
              const SizedBox(width: 10),
              Text("\$${trade.amount.toStringAsFixed(2)}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ]),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(color: trade.color, borderRadius: BorderRadius.circular(20)),
              child: Text(trade.status.name.toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10)),
            ),
          ]),
          const Divider(height: 20, color: Colors.grey),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            _buildInfoColumn("Entry", trade.entryPrice.toStringAsFixed(4)),
            // +++ এখানে মূল পরিবর্তনটি করা হয়েছে +++
            trade.status == TradeStatus.running
                ? _buildCountdownColumn() // রানিং ট্রেডের জন্য কাউন্টডাউন
                : _buildInfoColumn("Close", trade.closePrice?.toStringAsFixed(4) ?? '...'), // পুরোনো ট্রেডের জন্য ক্লোজ প্রাইস
            _buildInfoColumn("Time", timeFormat.format(trade.entryTime)),
          ]),
          // New: Early close button
          if (trade.status == TradeStatus.running)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: ElevatedButton(
                onPressed: () => controller.earlyCloseTrade(trade),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(30),
                ),
                child: const Text("Early Close"),
              ),
            ),
        ]),
      ),
    );
  }

  // রানিং ট্রেডের জন্য কাউন্টডাউন কলাম
  Widget _buildCountdownColumn() {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(_remainingTime.inMinutes.remainder(60));
    final seconds = twoDigits(_remainingTime.inSeconds.remainder(60));
    return _buildInfoColumn("Ends In", "$minutes:$seconds");
  }

  Widget _buildInfoColumn(String title, String value) {
    return Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
      Text(title, style: const TextStyle(color: Colors.white70, fontSize: 11)),
      const SizedBox(height: 4),
      Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
    ]);
  }
}