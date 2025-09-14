import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter/services.dart';

import '../controllers/trading_controller.dart';
import '../models/trade_model.dart';
import '../utils/enums.dart';

class TradeControlPanel extends StatelessWidget {
  final TradingController controller = Get.find();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(children: [
        _buildCustomInputRow("Investment:", controller.investmentController, (value) {
          controller.setInvestmentAmount(double.tryParse(value) ?? 0.0);
        }),
        const SizedBox(height: 10),
        _buildCustomInputRow("Duration (s):", controller.durationController, (value) {
          controller.setTradeDuration(int.tryParse(value) ?? 0);
        }),
        const SizedBox(height: 20),
        Row(children: [
          Expanded(child: _buildTradeButton(TradeDirection.down)),
          const SizedBox(width: 16),
          Expanded(child: _buildTradeButton(TradeDirection.up)),
        ]),
      ]),
    );
  }

  Widget _buildCustomInputRow(String label, TextEditingController textController, Function(String) onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70)),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: TextField(
              controller: textController,
              keyboardType: TextInputType.number,
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.digitsOnly,
              ],
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.black.withOpacity(0.3),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
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