import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:trading_home/home/widgets/account_popup.dart';
import 'package:trading_home/home/widgets/timeframe_selector.dart';
import 'package:trading_home/home/widgets/trade_control_panel.dart';
import 'package:trading_home/home/widgets/trade_history_popup.dart';

import 'chert.dart';
import 'controllers/trading_controller.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final TradingController controller = Get.find();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0E1012), Color(0xFF061B32)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              TopBar(),
              TimeframeSelector(),
              Expanded(
                child: Obx(
                      () => CandlestickChart(
                    key: controller.chartKey,
                    candles: controller.displayedCandles,
                    runningTrades: controller.runningTrades,
                    candleTimeRemaining: controller.candleTimeRemaining.value,
                    selectedTimeframe: controller.selectedTimeframe.value,
                  ),
                ),
              ),
              TradeControlPanel(),
            ],
          ),
        ),
      ),
    );
  }
}

class TopBar extends StatelessWidget {
  final TradingController controller = Get.find();

  TopBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Get.dialog(AccountPopup()),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Obx(() => Row(
                children: [
                  Icon(controller.isLiveAccount.value ? Icons.monetization_on : Icons.videogame_asset, color: Colors.greenAccent),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(controller.isLiveAccount.value ? "Live Account" : "Demo Account", style: const TextStyle(color: Colors.white, fontSize: 12)),
                      Text("\$${controller.currentBalance.toStringAsFixed(2)}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                    ],
                  ),
                  const Icon(Icons.arrow_drop_down, color: Colors.white),
                ],
              )),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.history, color: Colors.white),
            onPressed: () => Get.dialog(TradeHistoryPopup()),
          ),
        ],
      ),
    );
  }
}