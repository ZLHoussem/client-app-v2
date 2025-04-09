// widgets/home_header.dart

import 'package:flutter/material.dart';

class HomeHeader extends StatelessWidget {
  final int pendingRequests;
  final VoidCallback onNotificationTap; // More generic callback

  const HomeHeader({
    super.key,
    required this.pendingRequests,
    required this.onNotificationTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.35,
      width: double.infinity,
      child: Stack(
        children: [
          Image.asset(
            'assets/images/bg.png', // Consider defining assets paths as constants
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            errorBuilder: (context, error, stackTrace) => Container(
              color: Colors.grey[300], // Placeholder color on error
              child: const Center(child: Icon(Icons.error_outline, color: Colors.red)),
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: onNotificationTap,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.notifications, size: 30, color: Colors.blue),
                  if (pendingRequests > 0) _buildNotificationBadge(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationBadge() {
    return Positioned(
      right: 0,
      top: 0,
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: Colors.blue, // Use theme color if available
          borderRadius: BorderRadius.circular(10),
        ),
        constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
        child: Text(
          '$pendingRequests',
          style: const TextStyle(color: Colors.white, fontSize: 10),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}