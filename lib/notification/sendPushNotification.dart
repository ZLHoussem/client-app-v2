import 'dart:convert';
import 'package:bladi_go_client/notification/getAccessToken.dart';
import 'package:http/http.dart' as http;


Future<void> sendPushNotification({
  required String token,
  required String title,
  required String body,

}) async {
  try {
    // Get the access token
    final accessToken = await getAccessToken();

    final response = await http.post(
      Uri.parse('https://fcm.googleapis.com/v1/projects/transporteur-aeefc/messages:send'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
      body: jsonEncode({
        'message': {
          'token': token,
          'notification': {'title': title, 'body': body},
          
        },
      }),
    );

    if (response.statusCode == 200) {
      print('Push notification sent successfully: ${response.body}');
    } else {
      print('Error sending push notification: ${response.statusCode} - ${response.body}');
    }
  } catch (e) {
    print('Exception occurred while sending push notification: $e');
  }
}