// widgets/trajet_card.dart
import 'package:bladi_go_client/models/trajet_models.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For date formatting

class TrajetCard extends StatelessWidget {
  final TrajetDisplayData trajetData;
  final DateTime? targetDate; // The user's originally searched date
  final VoidCallback onTap;

  const TrajetCard({
    super.key,
    required this.trajetData,
    required this.onTap,
    this.targetDate,
  });

  // Helper to format date difference (remains the same)
  String _formatDateDifference(DateTime trajetDate, DateTime? targetDate) {
    String baseDateStr = DateFormat('dd/MM/yyyy').format(trajetDate); // Display format
    if (targetDate == null) return baseDateStr; // No target date to compare

    final trajetDay = DateTime(trajetDate.year, trajetDate.month, trajetDate.day);
    final targetDay = DateTime(targetDate.year, targetDate.month, targetDate.day);
    final difference = trajetDay.difference(targetDay).inDays;

    if (difference == 0) {
      return baseDateStr; // Same day
    } else {
      return '$baseDateStr (${difference > 0 ? '+' : ''}$difference jour${difference.abs() > 1 ? 's' : ''})';
    }
  }

  @override
  Widget build(BuildContext context) {
    final trajet = trajetData.trajet;
    final chauffeur = trajetData.chauffeur;
    // Use blue color from theme or fallback for icon
    final Color iconColor =  Colors.blue.shade700;
    final transportIcon = trajet.style == 'Bateau' ? Icons.directions_boat : Icons.flight;
    final formattedDate = _formatDateDifference(trajetData.dateTime, targetDate);
    final imageUrl = chauffeur.vehicleImageUrl ?? 'assets/images/placeholder_vehicle.png'; // Provide a placeholder

    return GestureDetector( // Use GestureDetector instead of InkWell for custom background
      onTap: onTap,
      child: Container(
        // Apply the original outer gradient container style
        margin: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 8.0), // Original margin
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: const LinearGradient(
            colors: [Color(0xFF0D47A1), Color(0xFF1976D2), Color(0xFF42A5F5)], // Original Blue Gradient
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [ // Optional: Add a subtle shadow like Card would have
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 4,
                offset: const Offset(0, 2),
              )
          ]
        ),
        child: Container(
          // Apply the original inner white container style
          margin: const EdgeInsets.all(2.0), // Original inner margin for the border effect
          decoration: BoxDecoration(
            color: Colors.white, // Inner background is white
            borderRadius: BorderRadius.circular(10), // Slightly smaller radius
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0), // Original padding
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(transportIcon, size: 20, color: iconColor), // Use dynamic icon color
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              trajet.value, // "From → To"
                              // Use slightly darker text for better contrast on white
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.black87 // Ensure good contrast
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _buildDetailRow(context, Icons.person_outline, 'Chauffeur:', chauffeur.fullName),
                      const SizedBox(height: 6),
                      _buildDetailRow(context, Icons.calendar_today_outlined, 'Date:', formattedDate),
                      const SizedBox(height: 6),
                      _buildDetailRow(
                        context,
                        Icons.directions_car_filled_outlined,
                        'Véhicule:',
                        '${chauffeur.vehicle} (${chauffeur.vehicleColor})',
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                _buildImage(imageUrl), // Use the existing image helper
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper for detail rows within the card (remains the same)
  Widget _buildDetailRow(BuildContext context, IconData icon, String label, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.grey[700]),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              // Use default text style from theme for consistency
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.black54),
              children: [
                TextSpan(
                  text: '$label ',
                  style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87),
                ),
                TextSpan(
                  text: text,
                  // Inherits style from parent TextSpan
                ),
              ],
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // Helper for building the image part of the card (remains the same)
  Widget _buildImage(String imageUrl) {
    bool isNetwork = imageUrl.startsWith('http');
    Widget imageWidget;

    if (isNetwork) {
      imageWidget = Image.network(
        imageUrl,
        width: 75, height: 75, fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            width: 75, height: 75, color: Colors.grey[200],
            child: Center(
              child: CircularProgressIndicator(
                strokeWidth: 2.0,
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                    : null,
              )
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          debugPrint('Erreur de chargement image réseau $imageUrl: $error');
          return _buildErrorImagePlaceholder();
        },
      );
    } else {
      imageWidget = Image.asset(
        imageUrl,
        width: 75, height: 75, fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          debugPrint('Erreur de chargement image asset $imageUrl: $error');
          return Image.asset(
            'assets/images/placeholder_vehicle.png',
            width: 75, height: 75, fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _buildErrorImagePlaceholder(),
          );
        },
      );
    }

    return Container(
      width: 75, height: 75,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300, width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(7),
        child: imageWidget,
      ),
    );
  }

  Widget _buildErrorImagePlaceholder() {
    return Container(
      width: 75, height: 75,
      color: Colors.grey.shade300,
      child: Icon(Icons.no_photography_outlined, size: 40, color: Colors.grey[600]),
    );
  }
}