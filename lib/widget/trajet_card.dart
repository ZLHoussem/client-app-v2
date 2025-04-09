// lib/widget/trajet_card.dart
import 'package:bladi_go_client/models/trajet_models.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TrajetCard extends StatelessWidget {
  final TrajetDisplayData trajetData;
  final DateTime? targetDate;
  final VoidCallback? onTap;

  const TrajetCard({
    super.key,
    required this.trajetData,
    this.onTap,
    this.targetDate,
  });

  String _formatTrajetDateBase(DateTime dt) {
    try {
      return DateFormat('d MMM yyyy', 'fr_FR').format(dt);
    } catch (e) {
      print("French locale not available for date formatting, using fallback. Error: $e");
      return DateFormat('yyyy/MM/dd').format(dt);
    }
  }

  String _formatDateWithDifference(DateTime trajetDate, DateTime? targetDate) {
    String baseDateStr = _formatTrajetDateBase(trajetDate);

    if (targetDate == null) {
      return baseDateStr;
    }

    final trajetDay = DateTime(trajetDate.year, trajetDate.month, trajetDate.day);
    final targetDay = DateTime(targetDate.year, targetDate.month, targetDate.day);
    final difference = trajetDay.difference(targetDay).inDays;

    if (difference == 0) {
      return baseDateStr;
    } else {
      return '$baseDateStr (${difference > 0 ? '+' : ''}$difference jour${difference.abs() > 1 ? 's' : ''})';
    }
  }

  IconData _getTransportIcon(String? transportType) {
    switch (transportType?.toLowerCase()) {
      case 'bateau':
        return Icons.sailing_rounded;
      case 'avion':
        return Icons.flight_takeoff_rounded;
      case 'voiture':
        return Icons.directions_car_filled_rounded;
      case 'bus':
        return Icons.directions_bus_filled_rounded;
      default:
        return Icons.route_rounded;
    }
  }

  Color _getTransportColor(String? transportType) {
    switch (transportType?.toLowerCase()) {
      case 'bateau':
        return const Color(0xFF01579B);
      case 'avion':
        return const Color(0xFF0097A7);
      case 'voiture':
        return const Color(0xFF3F51B5);
      case 'bus':
        return const Color(0xFF303F9F);
      default:
        return const Color(0xFF0D47A1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final trajet = trajetData.trajet;
    final theme = Theme.of(context);
    
    final bool isExactTargetDate = targetDate != null &&
        trajetData.dateTime.year == targetDate!.year &&
        trajetData.dateTime.month == targetDate!.month &&
        trajetData.dateTime.day == targetDate!.day;

    final String dateDisplayString = _formatDateWithDifference(trajetData.dateTime, targetDate);
    final String pickupPointsString = trajet.specificPickupPoints.isNotEmpty
        ? trajet.specificPickupPoints.join(' • ')
        : 'Non spécifiés';
        
    final Color transportColor = _getTransportColor(trajet.transportType);
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutQuint,
      margin: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 12.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: transportColor.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 8),
            spreadRadius: 4,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            splashColor: transportColor.withOpacity(0.1),
            highlightColor: transportColor.withOpacity(0.05),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Transport type banner
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        transportColor,
                        transportColor.withOpacity(0.9),
                        transportColor.withOpacity(0.8),
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Icon(
                              _getTransportIcon(trajet.transportType),
                              color: Colors.white,
                              size: 22,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                trajet.transportType ?? 'Transport',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isExactTargetDate)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.check_circle,
                                color: Colors.white,
                                size: 12,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Date recherchée',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),

                // Main content
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Date row with icon
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: transportColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.event_rounded,
                              color: transportColor,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Date de départ',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey[700],
                                    letterSpacing: 0.3,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  dateDisplayString,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[800],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Route info with icon
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: transportColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.route_rounded,
                              color: transportColor,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Itinéraire',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey[700],
                                    letterSpacing: 0.3,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  trajet.routePreview ?? trajet.value ?? 'Itinéraire non spécifié',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[800],
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Bottom section with pickup points
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    border: Border(
                      top: BorderSide(
                        color: Colors.grey[200]!,
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 20,
                        color: transportColor,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Points de ramassage',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[800],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              pickupPointsString,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[700],
                                height: 1.3,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}