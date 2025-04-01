import 'package:bladi_go_client/provider/user.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:bladi_go_client/pages/notificationpage/detailbg.dart';
import 'package:provider/provider.dart';


class NotificationScreen extends StatefulWidget {

  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  List<Map<String, dynamic>> notifications = [];
  bool isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  // Fetch driver name using chauffeurId from chauffeurs collection
  Future<String> _fetchDriverName(String chauffeurId) async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('chauffeurs')
          .doc(chauffeurId)
          .get();
      if (userDoc.exists) {
        final data = userDoc.data()!;
        final name = data['name'] ?? 'Inconnu';
        final lastName = data['lastName'] ?? '';
        return '$name $lastName'.trim();
      }
      return 'Chauffeur non attribué';
    } catch (e) {
      debugPrint('Erreur lors de la récupération du chauffeur: $e');
      return 'Chauffeur non attribué';
    }
  }

  // Fetch trajet details using trajetId
  Future<Map<String, dynamic>> _fetchTrajetDetails(String trajetId) async {
    try {
      final trajetDoc = await FirebaseFirestore.instance
          .collection('trajets')
          .doc(trajetId)
          .get();
      if (trajetDoc.exists) {
        final data = trajetDoc.data()!;
        final value = data['value']?.split(' → ') ?? ['N/A', 'N/A'];
        return {
          'collectionPoint': value[0],
          'deliveryPoint': value[1],
          'date': data['date'] ?? 'N/A',
        };
      }
      return {
        'collectionPoint': 'N/A',
        'deliveryPoint': 'N/A',
        'date': 'N/A',
      };
    } catch (e) {
      debugPrint('Erreur lors de la récupération du trajet: $e');
      return {
        'collectionPoint': 'N/A',
        'deliveryPoint': 'N/A',
        'date': 'N/A',
      };
    }
  }

  Future<void> _fetchNotifications() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    setState(() {
      isLoading = true;
    });
    
    try {
      debugPrint('Fetching notifications for userId: ${userProvider.userId}');
      
      // Get baggage documents where the user is the client
      final snapshot = await FirebaseFirestore.instance
          .collection('baggage')
          .where('userId', isEqualTo: userProvider.userId)
          .get();
      
      debugPrint('Found ${snapshot.docs.length} documents');

      final List<Map<String, dynamic>> newNotifications = [];
      final Map<String, Map<String, dynamic>> uniqueNotifications = {};

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final String docId = doc.id;
        final String? trajetId = data['trajetId'] as String?;
        final String chauffeurId = data['chauffeurId'] ?? '';
        
        if (trajetId == null) {
          debugPrint('Skipping doc ${doc.id} - missing trajetId');
          continue;
        }

        final trajetDetails = await _fetchTrajetDetails(trajetId);
        String driverName = 'En attente';
        
        if (chauffeurId.isNotEmpty) {
          driverName = await _fetchDriverName(chauffeurId);
        }
        
        final status = data['status'] ?? 'Statut inconnu';

        // Define status message and color based on the status
        String statusMessage;
        Color statusColor;
        
        switch (status) {
          case 'En attente':
            statusMessage = 'Vous avez une demande en attente';
            statusColor = Colors.orange;
            break;
          case 'En proposition':
            statusMessage = 'Votre demande est en proposition';
            statusColor = Colors.blue;
            break;
          case 'En accepter':
            statusMessage = 'Vous avez confirmé la demande correctement.';
            statusColor = Colors.green;
            break;
          case 'En refuser':
            statusMessage = 'Vous avez  refusée le demande';
            statusColor = Colors.red;
            break;

          case 'Payé':
            statusMessage = 'Votre paiement a été effectué avec succès';
            statusColor = Colors.blue;
            break;
          default:
            statusMessage = status;
            statusColor = const Color.fromARGB(255, 165, 165, 165);
        }

        // Create a unique key for this notification using the document ID
        // This ensures we don't lose notifications with the same trajetId but different status
        uniqueNotifications[docId] = {
          'id': docId,
          'date': trajetDetails['date'],
          'collectionPoint': trajetDetails['collectionPoint'],
          'deliveryPoint': trajetDetails['deliveryPoint'],
          'driverName': driverName,
          'status': statusMessage,
          'rawStatus': status, // Store raw status for condition checking
          'statusColor': '#${statusColor.value.toRadixString(16).padLeft(8, '0').substring(2)}',
          'chauffeurId': chauffeurId,
          'trajetId': trajetId,
          'userId': userProvider.userId,
          'items': data['items'] as List<dynamic>? ?? [],
          'timestamp': data['timestamp'] ?? Timestamp.now(),
        };
      }

      // Convert the map to a list and sort by timestamp (newest first)
      newNotifications.addAll(uniqueNotifications.values.toList());
      newNotifications.sort((a, b) {
        final Timestamp timestampA = a['timestamp'] as Timestamp;
        final Timestamp timestampB = b['timestamp'] as Timestamp;
        return timestampB.compareTo(timestampA);
      });

      setState(() {
        notifications = newNotifications;
        isLoading = false;
        debugPrint('State updated with ${notifications.length} notifications');
      });
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Notifications',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.black87,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: _fetchNotifications,
          ),
        ],
      ),
      body: isLoading
          ? _buildLoadingState()
          : notifications.isEmpty
              ? _buildEmptyState()
              : _buildNotificationList(
                  notifications,
                  context
                 
                ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_off_outlined,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Aucune notification',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Vous serez notifié lorsque vous aurez des mises à jour',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
        ],
      ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1),
    );
  }

  Widget _buildNotificationList(
    List<Map<String, dynamic>> notifications,
    BuildContext context,

  ) {
    debugPrint('Building notification list with ${notifications.length} items');
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: notifications.length,
      itemBuilder: (context, index) {
        debugPrint('Rendering item at index $index');
        var notification = notifications[index];
        Color statusColor = Color(
          int.parse(notification['statusColor'].replaceAll('#', '0xFF')),
        );

        return Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          margin: const EdgeInsets.only(bottom: 16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              gradient: LinearGradient(
                colors: [Colors.white, Colors.grey.shade50],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.local_shipping,
                        color: statusColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        notification['status'].toUpperCase(),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today_outlined,
                              size: 18,
                              color: Colors.blueGrey.shade700,
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Date', style: _labelStyle()),
                                const SizedBox(height: 4),
                                Text(
                                  notification['date'],
                                  style: _valueStyle(),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.person_outline,
                              size: 18,
                              color: Colors.blueGrey.shade700,
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Chauffeur', style: _labelStyle()),
                                const SizedBox(height: 4),
                                Text(
                                  notification['driverName'],
                                  style: _valueStyle(),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              size: 18,
                              color: Colors.blueGrey.shade700,
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Point de collecte', style: _labelStyle()),
                                const SizedBox(height: 4),
                                Text(
                                  notification['collectionPoint'],
                                  style: _valueStyle(),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 18,
                              color: Colors.blueGrey.shade700,
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Point de livraison',
                                  style: _labelStyle(),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  notification['deliveryPoint'],
                                  style: _valueStyle(),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                // Action buttons based on status
                _buildActionButton(notification, context),
              ],
            ),
          ),
        ).animate(delay: (50 * index).ms).fadeIn().slideX(begin: 0.1, end: 0);
      },
    );
  }

  Widget _buildActionButton(Map<String, dynamic> notification, BuildContext context) {
    // Check the raw status to determine which button to show
    final String rawStatus = notification['rawStatus'] ?? '';
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    switch (rawStatus) {
      case 'En attente':
        return _buildStatusButton(
          'Voir les détails',
          Colors.orange.shade600,
          () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ModernBaggageScreen(
                  userId: userProvider.userId,
                  selectedDate: notification['date'],
                  collectionPoint: notification['collectionPoint'],
                  deliveryPoint: notification['deliveryPoint'],
                ),
              ),
            ).then((_) {
              // Refresh notifications when returning from detail page
              _fetchNotifications();
            });
          },
        );
        
      case 'En proposition':
        return _buildStatusButton(
          'Voir la proposition',
          Colors.blue,
          () {
            Navigator.push(
              context,
              MaterialPageRoute(
                 builder: (context) => ModernBaggageScreen(
                  userId: userProvider.userId,
                  selectedDate: notification['date'],
                  collectionPoint: notification['collectionPoint'],
                  deliveryPoint: notification['deliveryPoint'],
                ),
              ),
            ).then((_) {
              // Refresh notifications when returning from proposal page
              _fetchNotifications();
            });
          },
        );
        
      case 'En accepter':
        return _buildStatusButton(
          'Voir les détails',
          Colors.green,
          () {Navigator.push(
              context,
              MaterialPageRoute(
                 builder: (context) => ModernBaggageScreen(
                  userId: userProvider.userId,
                  selectedDate: notification['date'],
                  collectionPoint: notification['collectionPoint'],
                  deliveryPoint: notification['deliveryPoint'],
                ),
              ),
            ).then((_) {
              // Refresh notifications when returning from proposal page
              _fetchNotifications();
            });
          },
        );
        
      case 'En refuser':
        return _buildStatusButton(
          'Voir les détails',
          Colors.red,
          () {
            // Add implementation for viewing rejected request details
            // Return to this screen and refresh after viewing
            _fetchNotifications();
          },
        );
        
      case 'Confirmé':
        return _buildStatusButton(
          'Voir la confirmation',
          Colors.green,
          () {
            // Add implementation for viewing confirmed request details
            // Return to this screen and refresh after viewing
            _fetchNotifications();
          },
        );
        
      case 'Payé':
        return _buildStatusButton(
          'Position du chauffeur',
          Colors.blue,
          () {
            // Add implementation for driver position tracking
            // For example:
            // Navigator.push(
            //   context,
            //   MaterialPageRoute(
            //     builder: (context) => DriverTrackingScreen(
            //       chauffeurId: notification['chauffeurId'],
            //     ),
            //   ),
            // ).then((_) {
            //   _fetchNotifications();
            // });
          },
        );
        
      default:
        // No button for unknown statuses
        return const SizedBox.shrink();
    }
  }

  Widget _buildStatusButton(String label, Color color, VoidCallback onPressed) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Center(
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 10,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  TextStyle _labelStyle() => TextStyle(
        fontSize: 12,
        color: Colors.grey.shade600,
        fontWeight: FontWeight.w500,
      );

  TextStyle _valueStyle() => const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      );
}