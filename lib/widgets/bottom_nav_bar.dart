import 'package:flutter/material.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTap;

  const CustomBottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => onTap(0),
          ),
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline),
            onPressed: () => onTap(1),
          ),
          const SizedBox(width: 48), // مكان الزر الأصفر
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () => onTap(2),
          ),
          TextButton(
            onPressed: () => onTap(3),
            child: const Text(
              "Do",
              style: TextStyle(color: Colors.blue),
            ),
          ),
        ],
      ),
    );
  }
}