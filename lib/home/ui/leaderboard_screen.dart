// lib/home/ui/leaderboard_screen.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/trading_controller.dart';
import '../models/leaderboard_user.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final TradingController controller = Get.find();

    // রিয়েল-টাইম আপডেটের জন্য Obx ব্যবহার করে লিডারবোর্ড সর্ট করা হয়েছে
    return Obx(() {
      controller.sortLeaderboard();
      return Scaffold(
        appBar: AppBar(
          title: const Text("Leaderboard (Demo)"),
          backgroundColor: const Color(0xFF061B32),
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
            if (controller.leaderboardUsers.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }
            return ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: controller.leaderboardUsers.length,
              itemBuilder: (context, index) {
                final user = controller.leaderboardUsers[index];
                final isCurrentUser = user.id == 'user_1';
                return _LeaderboardTile(
                  user: user,
                  rank: index + 1,
                  isCurrentUser: isCurrentUser,
                );
              },
            );
          }),
        ),
      );
    });
  }
}

class _LeaderboardTile extends StatelessWidget {
  final LeaderboardUser user;
  final int rank;
  final bool isCurrentUser;

  const _LeaderboardTile({
    required this.user,
    required this.rank,
    required this.isCurrentUser,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final pnl = user.pnl.value;
      final isProfit = pnl >= 0;
      final pnlColor = isProfit ? Colors.greenAccent : Colors.redAccent;
      final pnlText = '${isProfit ? '+' : ''}\$${pnl.toStringAsFixed(2)}';

      return Card(
        color: isCurrentUser ? Colors.blue.withOpacity(0.3) : Colors.black.withOpacity(0.2),
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Text(
                '#$rank',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isCurrentUser ? Colors.white : Colors.white70,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.normal,
                        color: isCurrentUser ? Colors.greenAccent : Colors.white,
                      ),
                    ),
                    Text(
                      pnlText,
                      style: TextStyle(
                        fontSize: 12,
                        color: pnlColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '\$${user.balance.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}