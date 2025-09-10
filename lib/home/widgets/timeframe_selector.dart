import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/trading_controller.dart';
import '../utils/enums.dart';


class TimeframeSelector extends StatelessWidget {
  final TradingController controller = Get.find();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Obx(() => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: Timeframe.values.map((tf) => GestureDetector(
            onTap: () => controller.changeTimeframe(tf),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: controller.selectedTimeframe.value == tf ? Colors.blue.withOpacity(0.7) : Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(tf.label, style: const TextStyle(color: Colors.white)),
            ),
          )).toList(),
        ),
      )),
    );
  }
}