// services/home_service.dart
import 'dart:async';
import 'package:bladi_go_client/api/firebase_api.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart'; // Needed for BuildContext in initNotifications

class HomeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseApi _firebaseApi = FirebaseApi(); // Assuming FirebaseApi is a singleton or can be instantiated

  // Fetch client name based on user ID
  Future<String?> fetchClientName(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        return userDoc.data()?['name'] as String? ?? 'Utilisateur';
      } else {
        // Consider throwing a specific exception or returning null/default
        debugPrint("User document not found for ID: $userId");
        return 'Utilisateur'; // Or null if you want to handle it differently
      }
    } catch (e) {
      debugPrint('Error fetching client name: $e');
      // Re-throw or return null/default based on error handling strategy
      throw Exception('Erreur lors du chargement du nom du client');
    }
  }

  // Get a stream of pending baggage requests count for the user
  Stream<int> getPendingRequestsStream(String userId) {
    try {
      return _firestore
          .collection('baggage')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'pending')
          .snapshots()
          .map((snapshot) => snapshot.docs.length) // Map snapshots to count
          .handleError((error) {
            debugPrint("Error listening to pending requests: $error");
            // Return 0 or emit an error state if needed
            return 0;
          });
    } catch (e) {
      debugPrint("Error setting up pending requests stream: $e");
      // Return a stream with an initial error or empty state
      return Stream.value(0); // Or Stream.error(e);
    }
  }

  // Initialize notifications
  Future<void> initializeNotifications(BuildContext context) async {
    try {
      await _firebaseApi.initNotifications(context);
      debugPrint('Notifications initialized successfully via HomeService');
    } catch (e) {
      debugPrint('Error initializing notifications via HomeService: $e');
      if (context.mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  "Impossible d'initialiser les notifications. Certaines fonctionnalités peuvent être limitées.",
                ),
                backgroundColor: Colors.orange,
              ),
            );
      }
    }
  }
}