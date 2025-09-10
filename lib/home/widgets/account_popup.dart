import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/trading_controller.dart';


class AccountPopup extends StatelessWidget {
  final TradingController controller = Get.find();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      backgroundColor: const Color(0xff061b32),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAccountTile(isLive: true, balance: controller.liveBalance.value),
            const Divider(color: Colors.grey),
            _buildAccountTile(isLive: false, balance: controller.demoBalance.value),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountTile({required bool isLive, required double balance}) {
    return Obx(() => ListTile(
      leading: Icon(
        controller.isLiveAccount.value == isLive ? Icons.radio_button_checked : Icons.radio_button_unchecked,
        color: isLive ? Colors.greenAccent : Colors.blueAccent,
      ),
      title: Text(isLive ? "Live Account" : "Demo Account", style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text("\$${balance.toStringAsFixed(2)}", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      onTap: () {
        controller.switchAccount(isLive);
        Get.back();
      },
    ));
  }
}