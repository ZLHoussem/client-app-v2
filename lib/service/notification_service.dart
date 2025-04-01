// notification_service.dart
import 'package:bladi_go_client/models/notification_model.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';


class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Fetch driver name using chauffeurId from chauffeurs collection
  Future<String> _fetchDriverName(String chauffeurId) async {
    if (chauffeurId.isEmpty) {
      return 'En attente'; // Or 'Non assigné'
    }
    try {
      final userDoc = await _firestore
          .collection('chauffeurs')
          .doc(chauffeurId)
          .get();
      if (userDoc.exists) {
        final data = userDoc.data()!;
        final name = data['name'] ?? 'Inconnu';
        final lastName = data['lastName'] ?? '';
        return '$name $lastName'.trim();
      }
      return 'Chauffeur inconnu'; // Changed from non attribué for clarity
    } catch (e) {
      debugPrint('Erreur lors de la récupération du chauffeur ($chauffeurId): $e');
      return 'Erreur chauffeur'; // Indicate an error occurred
    }
  }

  // Fetch trajet details using trajetId
  Future<Map<String, dynamic>> _fetchTrajetDetails(String trajetId) async {
    try {
      final trajetDoc = await _firestore
          .collection('trajets')
          .doc(trajetId)
          .get();
      if (trajetDoc.exists) {
        final data = trajetDoc.data()!;
        // Handle potential null or incorrect format for 'value'
        final valueString = data['value'] as String?;
        final points = valueString?.contains(' → ') ?? false
            ? valueString!.split(' → ')
            : ['N/A', 'N/A'];
        return {
          'collectionPoint': points[0],
          'deliveryPoint': points.length > 1 ? points[1] : 'N/A',
          'date': data['date'] ?? 'N/A', // Consider formatting the date here if needed
        };
      }
      return {
        'collectionPoint': 'N/A',
        'deliveryPoint': 'N/A',
        'date': 'N/A',
      };
    } catch (e) {
      debugPrint('Erreur lors de la récupération du trajet ($trajetId): $e');
      return {
        'collectionPoint': 'Erreur trajet', // Indicate error
        'deliveryPoint': 'Erreur trajet',
        'date': 'N/A',
      };
    }
  }

  // Determine status message and color
  Map<String, dynamic> _getStatusInfo(String? status) {
    String statusMessage;
    Color statusColor;
    String rawStatus = status ?? 'Inconnu';

    switch (rawStatus) {
      case 'En attente':
        statusMessage = 'Vous avez une demande en attente';
        statusColor = Colors.orange;
        break;
      case 'En proposition':
        statusMessage = 'Votre demande est en proposition';
        statusColor = Colors.blue;
        break;
      case 'En accepter': // Assuming this means accepted by client
        statusMessage = 'Vous avez confirmé la demande.';
        statusColor = Colors.green;
        break;
      case 'En refuser': // Assuming this means refused by client
        statusMessage = 'Vous avez refusé la demande.';
        statusColor = Colors.red;
        break;
      case 'Confirmé': // Possibly confirmed by admin/system after acceptance?
        statusMessage = 'Demande confirmée.'; // Or more specific message
        statusColor = Colors.teal; // Example color
        break;
      case 'Payé':
        statusMessage = 'Votre paiement a été effectué avec succès.';
        statusColor = Colors.purple; // Example color
        break;
      default:
        statusMessage = 'Statut: $rawStatus'; // Display raw status if unknown
        statusColor = Colors.grey;
    }
    return {'message': statusMessage, 'color': statusColor, 'raw': rawStatus};
  }


  Future<List<NotificationModel>> fetchNotifications(String userId) async {
     if (userId.isEmpty) {
       debugPrint('User ID is empty, cannot fetch notifications.');
       return []; // Return empty list if no user ID
     }
     debugPrint('Fetching notifications for userId: $userId');

    try {
      // Get baggage documents where the user is the client
      final snapshot = await _firestore
          .collection('baggage')
          .where('userId', isEqualTo: userId)
          // Optional: Order by timestamp descending directly in the query
          .orderBy('timestamp', descending: true)
          .get();

      debugPrint('Found ${snapshot.docs.length} potential notification documents');

      final List<NotificationModel> fetchedNotifications = [];

      // Using Future.wait for potentially faster fetching of related data
      await Future.wait(snapshot.docs.map((doc) async {
          final data = doc.data();
          final String docId = doc.id;
          final String? trajetId = data['trajetId'] as String?;
          // Provide default empty string if null
          final String chauffeurId = data['chauffeurId'] as String? ?? '';
          final String rawStatus = data['status'] as String? ?? 'Inconnu';
          final Timestamp timestamp = data['timestamp'] as Timestamp? ?? Timestamp.now(); // Default timestamp

          if (trajetId == null || trajetId.isEmpty) {
            debugPrint('Skipping doc ${doc.id} - missing or empty trajetId');
            return; // Skip this document
          }

          // Fetch related data concurrently
          final trajetDetailsFuture = _fetchTrajetDetails(trajetId);
          final driverNameFuture = _fetchDriverName(chauffeurId);

          // Wait for both futures
          final trajetDetails = await trajetDetailsFuture;
          final driverName = await driverNameFuture;

          final statusInfo = _getStatusInfo(rawStatus);

          fetchedNotifications.add(
            NotificationModel(
              id: docId,
              date: trajetDetails['date'],
              collectionPoint: trajetDetails['collectionPoint'],
              deliveryPoint: trajetDetails['deliveryPoint'],
              driverName: driverName,
              statusMessage: statusInfo['message'],
              rawStatus: statusInfo['raw'],
              statusColor: statusInfo['color'],
              chauffeurId: chauffeurId,
              trajetId: trajetId,
              userId: userId, // Passed in userId
              items: data['items'] as List<dynamic>? ?? [],
              timestamp: timestamp,
            ),
          );
      }));

      // Sorting is now handled by Firestore query if orderBy is used.
      // If not using Firestore orderBy, uncomment the sort below:
      // fetchedNotifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      debugPrint('Finished processing. Returning ${fetchedNotifications.length} notifications.');
      return fetchedNotifications;

    } catch (e) {
      debugPrint('Error fetching notifications: $e');
      // Depending on requirements, you might want to throw the error
      // or return an empty list to indicate failure.
      return []; // Return empty list on error
    }
  }
}