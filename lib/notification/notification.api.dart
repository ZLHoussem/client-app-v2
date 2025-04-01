// notification_api.dart (or wherever you placed the class)
import 'dart:convert';
import 'dart:developer';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationApi {
  final FirebaseMessaging _firebaseMessaging;

  NotificationApi({
    FirebaseMessaging? firebaseMessaging,
  }) : _firebaseMessaging = firebaseMessaging ?? FirebaseMessaging.instance;

  // --- Client-Side Initialization (For Receiving Notifications) ---
  Future<void> initialize() async {
    try {
      // Request notification permissions
      await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      // Get FCM token for this device
      final token = await _firebaseMessaging.getToken();
      log('FCM Token (This Device): $token'); // Log the token of the current device

      // Set up foreground notification settings
      await _firebaseMessaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // Handle token refresh for this device
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        log('FCM Token refreshed (This Device): $newToken');
        // TODO: Implement logic to update this device's token on your server/database if necessary
      });
    } catch (e) {
      log('Error initializing FCM for receiving messages: $e');
    }
  }

  // --- Server-Side Sending Logic (Using Service Account) ---

  // IMPORTANT SECURITY WARNING:
  // Embedding service account keys directly in client-side code is highly insecure.
  // This key allows administrative access to your Firebase project.
  // Ideally, notification sending should be handled by a backend server.
  // If you must do it from the client, consider using Firebase Functions callable functions
  // or load the key securely (e.g., from a restricted configuration file NOT in version control).
  static const Map<String, dynamic> _serviceAccountCredentialsJson = {
    "type": "service_account",
    "project_id": "transporteur-aeefc",
    "private_key_id": "0401c14d8bb5ad0b9c0bd50942afd339ad2daf84",
    // Keep the private key format exactly as provided
    "private_key": "-----BEGIN PRIVATE KEY-----\nMIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQCjTb7E6IzLpUb5\nNdPf3aLKJQXWARbZh9rYIlL7NqzQVnw7dcI82Xri4HWVMrfV0FpKL8pAUhf6b/3i\ngrlveY2+8gKWALel3gzgyeNVubwiUsxCXMzurEP91OWS8znHxmRqJH7yhWKcMgAm\n0VxXOZYy6a3XTeelOqUsED3+leunaFzB1q3wjmLPoWDqQg9qWrgZD/vcG4tKbv9m\nRfMH7mQx/ZK1uIbOCKZGBbh921T2U+WjWJibeYkwk6JpiGTfXvjsYFbjBneErIWC\n3l607u7r4eo0tQO1E+71RsLigVW1Fy4MhwnWxTD1XFcVEKyeujecD9fadReGQ7lW\nLEzCZjMRAgMBAAECggEAAue7l1leGd21SHKLSVNc1Z+jfdtpRTzxaStxJ6bLxm1n\ndTpYK94gSCAp+gRxOKSl2pCE7AXZ3IV4sjp/ozVPJCto3YjNO5jv8zbRlyFAW372\nwyPPVzFUM1RB3Pj77pXVDFNdDnejhGJaVivJgAQWVo5e3p1Jm/WnYcQ3NMvaKaap\nH5Bqvdfrbb/XD5BEnDSI5EBJaud0w3kXkUMw6+SR6q7V3JF+sNKAF2KRIB4N0K+h\nXD5SuhvIypxtlh7MVUqEQuJmfGUQro/fLk/eUmq4+xTbvTsxv72SIXZfj+kbXc4r\nQe2vepDfqrJV0ickUsV1xqSWchk9KVRK/+BAIcvTDQKBgQDTxMV8LnpVnPfYvJza\nbuLmIpwt+3cKhsXRSYLZDtU5mqN9dS1PASEcfvBUsw6cn0ce+vqBwum51RVDhHJ/\ncpmkidUx2/IcU/exVumo12gRrne5gB5MlfutiWZK5SYqKrycszdYzHvGVOHfhIC8\nADzePNgWotnlC+PGZhh0tzueFQKBgQDFaY/3IXbaYqJT7G8i6Qdqci1lIy6AmM2j\nW6FgG20e00aRcJ/fs5yqZAErNmeDY6s40zdu4937AGWuPYrmhXyyCOxxSBj3+MJa\nKQ3XDJiwrHX+snG438B5Z4VqQlZMCajsC97fE4qF0dzipOYgUkX4dtVLfKgvqd3k\nOeO4RNl8DQKBgQCv5sF3Xg/lr0W79SeA1RyJtnPuSfNefgYwypPygjyg5Y8ptbxV\n5IVBaztrz3OyqybjV+ve/y0vXAyWkZydum5e2tKI4L5hw2l6F8xsn8hk73upTP9d\n9DMiuX+LdH3YBrm2m7K8gtXJL1aTWDeqcbQdkYKYgtrlQ5QGh2WHBXBy5QKBgBMO\nK31ZV5Wg67ZaHigqgjK+Lq+Sg8yZ80+ParZSL2hIUIl9a5E2TysLWCmJqNg/6Kkl\nijZD/Itb8HSvMBcsT2sH/Xq50N8uvePiDpnxd1OmcgVRyDRmNLgDTBeDq7zPOeT/\nCFZUFozwQvgFnskD6Akhv1j4AWwIY4jCJb8FtlCJAoGACV6xTOpWGYcD6MGTxRvS\npG1Pk2s/tOnHikkuwY1l+XASG+ewBlBPCTTcfphoOo3k3M/zdPL1SAwZmeVYVMIs\nchplTDY+9fE1gAbASn6Rd0QCwQktdT2b5n2Sjk04FXH/iusgJDXyeheGkgm6aZ2M\nlFiU+EaIgcL+JYhF0uRTnPQ=\n-----END PRIVATE KEY-----\n",
    "client_email": "firebase-adminsdk-fbsvc@transporteur-aeefc.iam.gserviceaccount.com",
    "client_id": "100472804201778417805",
    "auth_uri": "https://accounts.google.com/o/oauth2/auth",
    "token_uri": "https://oauth2.googleapis.com/token",
    "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
    "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/firebase-adminsdk-fbsvc%40transporteur-aeefc.iam.gserviceaccount.com",
    "universe_domain": "googleapis.com"
  };

  static Future<String?> _getAccessToken() async {
    try {
      final ServiceAccountCredentials credentials =
          ServiceAccountCredentials.fromJson(_serviceAccountCredentialsJson);

      final client = await clientViaServiceAccount(
          credentials, ['https://www.googleapis.com/auth/firebase.messaging']);
      final AccessCredentials accessCredentials = client.credentials;
      // log('Access Token Generated: ${accessCredentials.accessToken.data}'); // Optional: Log token generation
      client.close(); // Close the client after getting credentials
      return accessCredentials.accessToken.data;
    } catch (e) {
      log('Error getting service account access token: $e');
      return null;
    }
  }

  /// Generic function to send a notification using FCM v1 API.
  static Future<Map<String, dynamic>> sendNotification({
    required String targetToken, // The FCM token of the recipient device
    required String title,
    required String body,
    Map<String, String>? data, // Optional data payload
  }) async {
    final String? accessToken = await _getAccessToken();
    if (accessToken == null) {
      log('Failed to send notification: Could not get access token.');
      return {
        'success': false,
        'message': 'Failed to get access token',
      };
    }

    log('Attempting to send notification to token: $targetToken');

    final String fcmEndpoint =
        'https://fcm.googleapis.com/v1/projects/transporteur-aeefc/messages:send'; // Use your project ID

    final Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $accessToken',
    };

    final Map<String, dynamic> notificationPayload = {
      "title": title,
      "body": body,
    };

    // Basic Android and APNS (iOS) configurations for high priority
    final Map<String, dynamic> androidConfig = {"priority": "high"};
    final Map<String, dynamic> apnsConfig = {
      "headers": {"apns-priority": "10"} // iOS high priority (5 for normal)
    };

    // Add default click action if not provided in data
    final Map<String, String> dataPayload = {
      ...?data, // Spread existing data
      "click_action": "FLUTTER_NOTIFICATION_CLICK", // Standard action
    };

    final Map<String, dynamic> message = {
      "token": targetToken,
      "notification": notificationPayload,
      "data": dataPayload,
      "android": androidConfig,
      "apns": apnsConfig,
    };

    final Map<String, dynamic> fcmPayload = {
      "message": message,
    };

    try {
      final response = await http.post(
        Uri.parse(fcmEndpoint),
        headers: headers,
        body: json.encode(fcmPayload),
      );

      log('FCM Send API Response Status: ${response.statusCode}');
      log('FCM Send API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': 'Notification sent successfully',
          'response': json.decode(response.body),
        };
      } else {
        // Try to parse error message
        String errorMessage = 'Failed to send notification.';
        try {
          final decodedBody = json.decode(response.body);
          if (decodedBody['error'] != null && decodedBody['error']['message'] != null) {
             errorMessage += ' Reason: ${decodedBody['error']['message']}';
          }
        } catch (_) {
           errorMessage += ' Status: ${response.statusCode}. Body: ${response.body}';
        }
         log('Error sending notification: $errorMessage');
        return {
          'success': false,
          'message': errorMessage,
          'statusCode': response.statusCode,
          'responseBody': response.body,
        };
      }
    } catch (e) {
      log('Exception caught sending notification: $e');
      return {
        'success': false,
        'message': 'Exception occurred during sending',
        'error': e.toString(),
      };
    }
  }

  // You can keep the specific methods if you like, but they should ideally call the generic one
   static Future<Map<String, dynamic>> sendDriverNotificationchat({
    required String chat,
    required String driverToken,

  }) async {
     return sendNotification(
       targetToken: driverToken,
       title: "Client Message", // Specific title for this case
       body: chat,
       data: {"notificationType": "chat"} // Specific data for this case
     );
   }

    static Future<Map<String, dynamic>> sendDriverNotificationarrive({
    required String chat,
    required String driverToken,
  }) async {
     return sendNotification(
       targetToken: driverToken,
       title: "Chauffeur Message", // Specific title for this case
       body: chat,
       data: {"notificationType": "arrival"} // Specific data for this case
     );
   }

}