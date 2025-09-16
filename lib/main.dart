// lib/main.dart

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'home/controllers/trading_controller.dart';
import 'home/home.dart';

void main() async { // main ফাংশনটিকে async করুন
  WidgetsFlutterBinding.ensureInitialized(); // এই লাইনটি যোগ করুন
  await Get.putAsync(() async => TradingController()); // কন্ট্রোলারকে async ভাবে লোড করুন
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Binary Trading',
      theme: ThemeData.dark(),
      home: HomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}