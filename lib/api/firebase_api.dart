import 'package:bladi_go_client/main.dart';
import 'package:bladi_go_client/provider/user.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';

class FirebaseApi {
  // Create instance of Firebase Messaging
  final _firebaseMessaging = FirebaseMessaging.instance;
  String? _fcmToken; // Store the FCM token

  // Getter to access the FCM token
  String? get fcmToken => _fcmToken;

  // Function to initialize notifications
  Future<void> initNotifications(BuildContext context) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userId = userProvider.userId;

    // Request permission from user (will prompt user to allow or deny)
    await _firebaseMessaging.requestPermission();

    // Fetch the FCM token for this device
    _fcmToken = await _firebaseMessaging.getToken();

    // Save the FCM token to Firestore
    if (userId != null && _fcmToken != null) {
      
      await FirebaseFirestore.instance.collection('users').doc(userId).set(
        {'fcmToken': _fcmToken},
        SetOptions(merge: true),
         // Use set with merge to avoid errors if the document doesn't exist
      );print('FCM token saved to Firestore.');
    } else {
      throw Exception('User ID or FCM token is null. Cannot save FCM token.');
    }

    // Initialize further settings for push notifications
    await initPushNotification(); // Fixed typo and added await
  }

  // Function to handle received messages
  void handleMessage(RemoteMessage? message) {
    // If the message is null, do nothing
    if (message == null) return;

    // Navigate to a new screen when a message is received and the user taps the notification
    navigatorKey.currentState?.pushNamed(
      '/notification_screen',
      
    );
  }

  // Function to handle background settings
  Future<void> initPushNotification() async {
    // Handle notification if the app was terminated and now opened
    FirebaseMessaging.instance.getInitialMessage().then(
      (message) => handleMessage(message),
      onError: (error) {
        print('Error handling initial message: $error');
      },
    );

    // Attach event listener for when a notification opens the app
    FirebaseMessaging.onMessageOpenedApp.listen(
      handleMessage,
      onError: (error) {
        print('Error handling onMessageOpenedApp: $error');
      },
    );
  }
}