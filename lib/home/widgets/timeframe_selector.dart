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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildAssetSelector(),
          const SizedBox(width: 10),
          _buildChartTypeSelector(), // নতুন চার্ট টাইপ সিলেক্টর
          const SizedBox(width: 10),
          Expanded(
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
          ),
        ],
      ),
    );
  }

  Widget _buildAssetSelector() {
    return Obx(() => Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<Asset>(
          value: controller.selectedAsset.value,
          dropdownColor: Colors.black.withOpacity(0.8),
          icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
          style: const TextStyle(color: Colors.white),
          onChanged: (Asset? newValue) {
            if (newValue != null) {
              controller.changeAsset(newValue);
            }
          },
          items: Asset.values.map<DropdownMenuItem<Asset>>((Asset value) {
            return DropdownMenuItem<Asset>(
              value: value,
              child: Text(value.label),
            );
          }).toList(),
        ),
      ),
    ));
  }

  // নতুন এই উইজেটটি যোগ করা হয়েছে
  Widget _buildChartTypeSelector() {
    return Obx(() => Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<ChartType>(
          value: controller.selectedChartType.value,
          dropdownColor: Colors.black.withOpacity(0.8),
          icon: const Icon(Icons.show_chart, color: Colors.white),
          style: const TextStyle(color: Colors.white),
          onChanged: (ChartType? newValue) {
            if (newValue != null) {
              controller.changeChartType(newValue);
            }
          },
          items: ChartType.values
              .map<DropdownMenuItem<ChartType>>((ChartType value) {
            return DropdownMenuItem<ChartType>(
              value: value,
              child: Text(value.name[0].toUpperCase() +
                  value.name.substring(1)),
            );
          }).toList(),
        ),
      ),
    ));
  }
}