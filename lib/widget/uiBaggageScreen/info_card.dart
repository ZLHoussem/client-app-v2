import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart'; // For animations

/// Displays the basic travel information (Date, Locations).
class InfoCardWidget extends StatelessWidget {
  final String travelDate;
  final String startLocation;
  final String endLocation;

  const InfoCardWidget({
    Key? key,
    required this.travelDate,
    required this.startLocation,
    required this.endLocation,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.blue.shade200, width: 1.5),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
           BoxShadow(
             color: Colors.grey.withOpacity(0.1),
             spreadRadius: 1,
             blurRadius: 4,
             offset: const Offset(0, 2),
           ),
        ]
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow(context, Icons.calendar_today_outlined, 'Date du Voyage', travelDate),
          const Divider(height: 20, thickness: 1),
          _buildInfoRow(context, Icons.location_on_outlined, 'Point de collecte', startLocation),
           const SizedBox(height: 10),
          _buildInfoRow(context, Icons.flag_outlined, 'Point de livraison', endLocation), // Changed icon for destination
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1);
  }

  // Helper method specific to this widget
  Widget _buildInfoRow(BuildContext context, IconData icon, String title, String subtitle) {
    return Row(
      children: [
        Icon(icon, color: Colors.blueGrey[700], size: 20),
        const SizedBox(width: 12),
        Expanded( // Use Expanded to handle potentially long text
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w500),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith( // Use theme for consistency
                  fontWeight: FontWeight.w600, // Slightly bolder
                  color: Colors.black87
                ),
                 overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}