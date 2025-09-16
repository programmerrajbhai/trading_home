// lib/home/ui/trade_history_screen.dart

import 'dart:async';
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
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Trade History"),
          backgroundColor: const Color(0xFF061B32),
          bottom: const TabBar(
            indicatorColor: Colors.blueAccent,
            indicatorWeight: 3.0,
            tabs: [
              Tab(child: Text("Running", style: TextStyle(fontSize: 16))),
              Tab(child: Text("History", style: TextStyle(fontSize: 16))),
            ],
          ),
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0E1012), Color(0xFF061B32)],
            ),
          ),
          child: Obx(() {
            final runningTrades = controller.runningTrades.reversed.toList();
            final historyTrades = controller.tradeHistory;

            return TabBarView(
              children: [
                // Running Trades Tab
                runningTrades.isEmpty
                    ? const Center(
                    child: Text("No running trades.",
                        style: TextStyle(color: Colors.white70)))
                    : ListView.builder(
                  padding: const EdgeInsets.only(top: 8),
                  itemCount: runningTrades.length,
                  itemBuilder: (context, index) =>
                      _TradeHistoryTile(trade: runningTrades[index]),
                ),
                // History Trades Tab
                historyTrades.isEmpty
                    ? const Center(
                    child: Text("No trade history yet.",
                        style: TextStyle(color: Colors.white70)))
                    : ListView.builder(
                  padding: const EdgeInsets.only(top: 8),
                  itemCount: historyTrades.length,
                  itemBuilder: (context, index) =>
                      _TradeHistoryTile(trade: historyTrades[index]),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}

class _TradeHistoryTile extends StatefulWidget {
  final Trade trade;
  const _TradeHistoryTile({required this.trade});

  @override
  State<_TradeHistoryTile> createState() => _TradeHistoryTileState();
}

class _TradeHistoryTileState extends State<_TradeHistoryTile> {
  Timer? _timer;
  Duration _remainingTime = Duration.zero;

  @override
  void initState() {
    super.initState();
    if (widget.trade.status == TradeStatus.running) {
      _updateRemainingTime();
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        _updateRemainingTime();
      });
    }
  }

  void _updateRemainingTime() {
    if (!mounted || widget.trade.status != TradeStatus.running) {
      _timer?.cancel();
      return;
    }
    final now = DateTime.now();
    if (now.isAfter(widget.trade.expiryTime)) {
      setState(() {
        _remainingTime = Duration.zero;
      });
      _timer?.cancel();
    } else {
      setState(() {
        _remainingTime = widget.trade.expiryTime.difference(now);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final trade = widget.trade;
    final timeFormat = DateFormat('HH:mm:ss dd/MM');

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    trade.direction == TradeDirection.up
                        ? Icons.arrow_upward
                        : Icons.arrow_downward,
                    color: trade.direction == TradeDirection.up
                        ? Colors.greenAccent
                        : Colors.redAccent,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    trade.asset.label,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                ],
              ),
              trade.status == TradeStatus.running
                  ? _buildCountdown()
                  : _buildStatusChip(trade),
            ],
          ),
          const Divider(height: 20, color: Colors.white24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildInfoColumn(
                  'Amount', '\$${trade.amount.toStringAsFixed(2)}'),
              _buildPriceInfoColumn(
                  'Entry', 'Close', trade.entryPrice, trade.closePrice),
              _buildInfoColumn(
                  trade.status == TradeStatus.running
                      ? 'Placed At'
                      : 'Result',
                  trade.status == TradeStatus.running
                      ? timeFormat.format(trade.entryTime)
                      : '${trade.pnl! >= 0 ? '+' : ''}\$${trade.pnl!.toStringAsFixed(2)}',
                  valueColor: trade.pnl == null
                      ? Colors.white
                      : (trade.pnl! >= 0
                      ? Colors.greenAccent
                      : Colors.redAccent)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(Trade trade) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
          color: trade.color.withOpacity(0.8),
          borderRadius: BorderRadius.circular(20)),
      child: Text(
        trade.status.name.toUpperCase(),
        style: const TextStyle(
            color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10),
      ),
    );
  }

  Widget _buildCountdown() {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(_remainingTime.inMinutes.remainder(60));
    final seconds = twoDigits(_remainingTime.inSeconds.remainder(60));
    return Text(
      'Ends in: $minutes:$seconds',
      style: const TextStyle(color: Colors.blueAccent, fontSize: 12),
    );
  }

  Widget _buildInfoColumn(String title, String value,
      {Color valueColor = Colors.white}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(color: Colors.white70, fontSize: 11)),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
                color: valueColor,
                fontWeight: FontWeight.bold,
                fontSize: 14)),
      ],
    );
  }

  Widget _buildPriceInfoColumn(
      String title1, String title2, double price1, double? price2) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          children: [
            Text(title1,
                style: const TextStyle(color: Colors.white70, fontSize: 11)),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_forward, color: Colors.white24, size: 12),
            const SizedBox(width: 4),
            Text(title2,
                style: const TextStyle(color: Colors.white70, fontSize: 11)),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '${price1.toStringAsFixed(4)} -> ${price2?.toStringAsFixed(4) ?? "..."}',
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
        ),
      ],
    );
  }
}