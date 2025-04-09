// import 'dart:ui';

// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:timezone/timezone.dart' as tz;
// import 'package:timezone/data/latest.dart' as tz;

// class LocalNotificationService {
//   static final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
//   FlutterLocalNotificationsPlugin();

//   static Future<void> initialize() async {
//     // Initialiser timezone
//     tz.initializeTimeZones();

//     const AndroidInitializationSettings androidInitialize =
//     AndroidInitializationSettings("@mipmap/ic_launcher");

//     const DarwinInitializationSettings iosInitialize = DarwinInitializationSettings(
//       requestSoundPermission: true,
//       requestBadgePermission: true,
//       requestAlertPermission: true,
//     );

//     final InitializationSettings initializationSettings = InitializationSettings(
//       android: androidInitialize,
//       iOS: iosInitialize,
//     );

//     await flutterLocalNotificationsPlugin.initialize(
//       initializationSettings,
//       onDidReceiveNotificationResponse: (NotificationResponse details) {
//         // Gérer le tap sur la notification
//         print("Notification tapped: ${details.payload}");
//       },
//     );
//   }

//   static NotificationDetails _notificationDetails() {
//     // Configuration Android
//     final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
//       'channel_id', // ID du canal
//       'Default Channel', // Nom du canal
//       importance: Importance.max,
//       priority: Priority.high,
//       playSound: true,
//       enableVibration: true,
//       sound: RawResourceAndroidNotificationSound('simplenotificationtaxi'),
//       enableLights: true,
//       color: const Color.fromARGB(255, 255, 255, 255),
//       ledColor: const Color.fromARGB(255, 255, 255, 255),
//       ledOnMs: 1000,
//       ledOffMs: 500,
//     );

//     // Configuration iOS
//     const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
//       presentSound: true,
//       presentAlert: true,
//       presentBadge: true,
//       sound: 'simplenotificationtaxi.wav', // Le fichier son pour iOS
//       badgeNumber: 1,
//     );

//     return NotificationDetails(
//       android: androidDetails,
//       iOS: iosDetails,
//     );
//   }

//   // Afficher une notification immédiate
//   static Future<void> showTextNotification({
//     int id = 0,
//     required String title,
//     required String body,
//     String? payload,
//   }) async {
//     try {
//       await flutterLocalNotificationsPlugin.show(
//         id,
//         title,
//         body,
//         _notificationDetails(),
//         payload: payload,
//       );
//     } catch (e) {
//       print("Erreur lors de l'affichage de la notification: $e");
//     }
//   }

//   // Planifier une notification
//   static Future<void> scheduleNotification({
//     int id = 0,
//     required String title,
//     required String body,
//     required DateTime scheduledTime,
//     String? payload,
//   }) async {
//     try {
//       final tz.TZDateTime tzScheduledTime = tz.TZDateTime.from(
//         scheduledTime,
//         tz.local,
//       );

//       await flutterLocalNotificationsPlugin.zonedSchedule(
//         id,
//         title,
//         body,
//         tzScheduledTime,
//         _notificationDetails(),
//         uiLocalNotificationDateInterpretation:
//         UILocalNotificationDateInterpretation.absoluteTime,
//         androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
//         payload: payload,
//       );
//     } catch (e) {
//       print("Erreur lors de la planification de la notification: $e");
//     }
//   }

//   // Planifier une notification périodique
//   static Future<void> schedulePeriodicNotification({
//     int id = 0,
//     required String title,
//     required String body,
//     required RepeatInterval repeatInterval,
//     String? payload,
//   }) async {
//     try {
//       await flutterLocalNotificationsPlugin.periodicallyShow(
//         id,
//         title,
//         body,
//         repeatInterval,
//         _notificationDetails(),
//         androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
//         payload: payload,
//       );
//     } catch (e) {
//       print("Erreur lors de la planification de la notification périodique: $e");
//     }
//   }

//   // Vérifier les permissions de notification
//   static Future<bool> checkPermissions() async {
//     final bool? result = await flutterLocalNotificationsPlugin
//         .resolvePlatformSpecificImplementation<
//         IOSFlutterLocalNotificationsPlugin>()
//         ?.requestPermissions(
//       alert: true,
//       badge: true,
//       sound: true,
//     );
//     return result ?? false;
//   }

//   // Annuler une notification spécifique
//   static Future<void> cancelNotification(int id) async {
//     await flutterLocalNotificationsPlugin.cancel(id);
//   }

//   // Annuler toutes les notifications
//   static Future<void> cancelAllNotifications() async {
//     await flutterLocalNotificationsPlugin.cancelAll();
//   }
// }