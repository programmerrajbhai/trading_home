import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/trading_controller.dart';
import '../utils/enums.dart';

class TradeControlPanel extends StatelessWidget {
  final TradingController controller = Get.find();
  final investmentSteps = [10.0, 20.0, 50.0, 100.0, 200.0];
  final durationSteps = [60, 120, 180, 300]; // in seconds

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(children: [
        _buildSelectorRow("Duration:", durationSteps, controller.tradeDurationSeconds, (sec) => controller.setTradeDuration(sec), (sec) => "${sec ~/ 60}m"),
        const SizedBox(height: 10),
        _buildSelectorRow("Amount:", investmentSteps, controller.investmentAmount, (amount) => controller.setInvestmentAmount(amount), (amount) => "\$${amount.toInt()}"),
        const SizedBox(height: 20),
        Row(children: [
          Expanded(child: _buildTradeButton(TradeDirection.down)),
          const SizedBox(width: 16),
          Expanded(child: _buildTradeButton(TradeDirection.up)),
        ]),
      ]),
    );
  }

  Widget _buildSelectorRow<T>(String label, List<T> steps, Rx<T> selectedValue, Function(T) onSelect, String Function(T) toLabel) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: const TextStyle(color: Colors.white70)),
      Obx(() => Row(
        children: steps.map((value) => GestureDetector(
          onTap: () => onSelect(value),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: selectedValue.value == value ? Colors.blue.withOpacity(0.7) : Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(toLabel(value), style: const TextStyle(color: Colors.white)),
          ),
        )).toList(),
      )),
    ]);
  }

  Widget _buildTradeButton(TradeDirection direction) {
    final isUp = direction == TradeDirection.up;
    return ElevatedButton.icon(
      onPressed: () => controller.placeTrade(direction),
      icon: Icon(isUp ? Icons.arrow_upward : Icons.arrow_downward),
      label: Text(isUp ? "Up" : "Down"),
      style: ElevatedButton.styleFrom(
        backgroundColor: isUp ? Colors.green : Colors.red,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }
}