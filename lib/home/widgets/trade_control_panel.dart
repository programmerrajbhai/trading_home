import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter/services.dart';

import '../controllers/trading_controller.dart';
import '../models/trade_model.dart';
import '../utils/enums.dart';

class TradeControlPanel extends StatelessWidget {
  final TradingController controller = Get.find();

  TradeControlPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildInvestmentInputRow(),
          const SizedBox(height: 12),
          _buildDurationInputRow(),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _buildTradeButton(TradeDirection.down)),
              const SizedBox(width: 16),
              Expanded(child: _buildTradeButton(TradeDirection.up)),
            ],
          ),
        ],
      ),
    );
  }

  // Helper function to update the text controller and notify the main controller
  void _updateTextController(TextEditingController textCtl, String newValue, Function(String) onChanged) {
    textCtl.text = newValue;
    textCtl.selection = TextSelection.fromPosition(TextPosition(offset: textCtl.text.length));
    onChanged(newValue);
  }

  // Updated Investment Row with quick add buttons
  Widget _buildInvestmentInputRow() {
    return Row(
      children: [
        const Text("Investment:", style: TextStyle(color: Colors.white70, fontSize: 14)),
        const SizedBox(width: 10),
        Expanded(
          child: TextField(
            controller: controller.investmentController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
            decoration: _inputDecoration(),
            onChanged: (value) => controller.setInvestmentAmount(double.tryParse(value) ?? 0.0),
          ),
        ),
        const SizedBox(width: 10),
        _buildQuickButton("+10", () {
          double currentValue = double.tryParse(controller.investmentController.text) ?? 0;
          _updateTextController(controller.investmentController, (currentValue + 10).toStringAsFixed(2),
                  (value) => controller.setInvestmentAmount(double.tryParse(value) ?? 0.0));
        }),
        _buildQuickButton("+50", () {
          double currentValue = double.tryParse(controller.investmentController.text) ?? 0;
          _updateTextController(controller.investmentController, (currentValue + 50).toStringAsFixed(2),
                  (value) => controller.setInvestmentAmount(double.tryParse(value) ?? 0.0));
        }),
        _buildQuickButton("+100", () {
          double currentValue = double.tryParse(controller.investmentController.text) ?? 0;
          _updateTextController(controller.investmentController, (currentValue + 100).toStringAsFixed(2),
                  (value) => controller.setInvestmentAmount(double.tryParse(value) ?? 0.0));
        }),
      ],
    );
  }

  // Updated Duration Row with quick select buttons
  Widget _buildDurationInputRow() {
    return Row(
      children: [
        const Text("Duration (s):", style: TextStyle(color: Colors.white70, fontSize: 14)),
        const SizedBox(width: 10),
        Expanded(
          child: TextField(
            controller: controller.durationController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
            decoration: _inputDecoration(),
            onChanged: (value) => controller.setTradeDuration(int.tryParse(value) ?? 0),
          ),
        ),
        const SizedBox(width: 10),
        _buildQuickButton("30s", () {
          _updateTextController(controller.durationController, "30",
                  (value) => controller.setTradeDuration(int.tryParse(value) ?? 0));
        }),
        _buildQuickButton("1m", () {
          _updateTextController(controller.durationController, "60",
                  (value) => controller.setTradeDuration(int.tryParse(value) ?? 0));
        }),
        _buildQuickButton("2m", () {
          _updateTextController(controller.durationController, "120",
                  (value) => controller.setTradeDuration(int.tryParse(value) ?? 0));
        }),
      ],
    );
  }

  // Common InputDecoration for TextFields
  InputDecoration _inputDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: Colors.black.withOpacity(0.3),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    );
  }

  // Reusable widget for quick action buttons
  Widget _buildQuickButton(String text, VoidCallback onPressed) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.4),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(text, style: const TextStyle(color: Colors.white70)),
        ),
      ),
    );
  }

  // Trade button (Up/Down)
  Widget _buildTradeButton(TradeDirection direction) {
    final isUp = direction == TradeDirection.up;
    return ElevatedButton.icon(
      onPressed: () => controller.placeTrade(direction),
      icon: Icon(isUp ? Icons.arrow_upward : Icons.arrow_downward, size: 28),
      label: Text(isUp ? "Up" : "Down", style: const TextStyle(fontSize: 20)),
      style: ElevatedButton.styleFrom(
        backgroundColor: isUp ? const Color(0xFF26A69A) : const Color(0xFFEF5350),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 5,
      ),
    );
  }
}