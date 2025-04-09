// import 'dart:developer';
// import 'package:cloud_firestore/cloud_firestore.dart';


// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:firebase_database/firebase_database.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:flutter/material.dart';

// import 'package:fluttertoast/fluttertoast.dart';



// import '../../notification/localnotification.dart';

// class PushNotificationSystem {
//   final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;



//   Future<void> initializeCloudMessaging() async {
//     // Request permission for notifications
//     NotificationSettings settings = await _firebaseMessaging.requestPermission(
//       alert: true,
//       announcement: true,
//       badge: true,
//       carPlay: true,
//       criticalAlert: true,
//       provisional: true,
//       sound: true,
//     );

//     if (settings.authorizationStatus == AuthorizationStatus.authorized) {
//       log('User granted permission');
//     } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
//       log('User granted provisional permission');
//     } else {
//       log('User declined or has not accepted permission');
//       return;
//     }


//     // Handle incoming messages when the app is in the foreground
//     FirebaseMessaging.onMessage.listen((RemoteMessage message) {
//       log("Foreground notification received");

//           // Navigate to chat page

//           String? title = message.notification?.title;
//           String? body = message.notification?.body;
//           title = title ?? "Notification";
//           body= body ?? "Notification body";
//           if(title!="Notification"&&body!="Notification body") {
//             LocalNotificationService.initialize();
//             LocalNotificationService.showTextNotification(
//               id: 0,
//               title: title,
//               body: body,
//             );
//           }

//     });

//     // Handle notification when the app is in the background and is opened from the notification
//     FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
//       log("Background notification opened");


//       if (message.data.containsKey('notificationType')) {
//         String notificationType = message.data['notificationType'];
//         String rideRequestId = message.data['rideRequestId'];

//         if (notificationType == "chat") {
//           // Navigate to chat page
//           String? title = message.notification?.title;
//           String? body = message.notification?.body;
//           title = title ?? "Notification";
//           body= body ?? "Notification body";
//           if(title!="Notification"&&body!="Notification body") {
//             LocalNotificationService.initialize();
//             LocalNotificationService.showTextNotification(
//               id: 0,
//               title: title,
//               body: body,
//             );
//           }
//         }
//       }
//     });

//     // Handle notification when the app is terminated and is opened from the notification
//     RemoteMessage? initialMessage =
//     await FirebaseMessaging.instance.getInitialMessage();
//     if (initialMessage != null) {
//       log("Terminated notification opened");



//     }

//     // Generate and save FCM token
//     await generateRegistrationToken();
//   }
//   Future<void> generateRegistrationToken() async {
//     String? token = await _firebaseMessaging.getToken();
//     log("FCM Registration Token: $token");

//     if (FirebaseAuth.instance.currentUser != null) {
//       FirebaseDatabase.instance
//           .ref()
//           .child("Drivers")
//           .child(FirebaseAuth.instance.currentUser!.uid)
//           .child("token")
//           .set(token);
//     }

//     _firebaseMessaging.subscribeToTopic("allDrivers");
//     _firebaseMessaging.subscribeToTopic("allUsers");
//   }


// }