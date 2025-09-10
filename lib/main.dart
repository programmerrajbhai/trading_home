import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'home/controllers/trading_controller.dart';
import 'home/home.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialize the controller for the whole app
    Get.put(TradingController());

    return GetMaterialApp(
      title: 'Binary Trading',
      theme: ThemeData.dark(),
      home: HomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}