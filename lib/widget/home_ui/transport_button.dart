// widgets/transport_button.dart
import 'package:flutter/material.dart';

class TransportButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const TransportButton({
    super.key,
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color selectedColor = Colors.blue; // Use theme color
    final Color unselectedColor = Colors.white;
    final Color selectedTextColor = Colors.white;
    final Color unselectedTextColor = Colors.black;
    final Color selectedIconColor = Colors.white;
    final Color unselectedIconColor = Colors.blue; // Use theme color

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? selectedColor : unselectedColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min, // Prevent row from taking extra space
          children: [
            Icon(icon, color: isSelected ? selectedIconColor : unselectedIconColor),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? selectedTextColor : unselectedTextColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}