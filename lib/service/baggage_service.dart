import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'dart:convert';
import 'package:bladi_go_client/models/article_data.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart' show MediaType;
import 'package:image/image.dart' as img;
import 'package:flutter/material.dart'; // For debugPrint

// Keep ArticleData definition accessible or redefine if needed
// If it's used across features, consider moving it to a 'models' directory

class BaggageService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // Make uploadUrl configurable or constant
  static const String _uploadUrl = 'http://192.168.1.6:5000/upload';
  // Consider making the FCM key a configurable constant

  static const String _fcmServerKey = 'BIGJTQVQk-CHbM6ZqaKxhmLjRVh_lLUKUtIeTBJfgPMhbKOKIUXwWpy2IOmD4WAL3T4NbuvPy7QAOMBC7qA-LkQ'; 

  Future<List<ArticleData>> loadExistingBaggage(String? baggageId) async {
    try {
      final doc = await _firestore.collection('baggage').doc(baggageId).get();
      if (doc.exists) {
        final data = doc.data()!;
        final items = data['items'] as List<dynamic>;
        List<ArticleData> loadedArticles = [];
        for (var item in items) {
          loadedArticles.add(ArticleData(
            initialDescription: item['description'] ?? '',
            initialUrls: item['imageUrls'] != null ? List<String>.from(item['imageUrls']) : [],
          ));
        }
        return loadedArticles;
      } else {
        throw Exception("Baggage document not found.");
      }
    } catch (e) {
      debugPrint('Error loading existing baggage: $e');
      rethrow; // Rethrow to be caught by the UI layer
    }
  }

  Future<String> _uploadImage(File image) async {
    String ext = image.path.split('.').last.toLowerCase();
    File uploadFile = image;

    // Basic validation (can be enhanced)
     final validExtensions = ['jpg', 'jpeg', 'png', 'gif'];
     if (!validExtensions.contains(ext)) {
        // Attempt conversion if possible, otherwise throw
        try {
            final rawImage = img.decodeImage(await image.readAsBytes());
            if (rawImage == null) throw Exception('Failed to decode image for conversion.');
            final jpegImage = img.encodeJpg(rawImage);
            uploadFile = File('${image.path}.jpg')..writeAsBytesSync(jpegImage);
            ext = 'jpg';
            debugPrint('Converted image to JPG for upload.');
        } catch(e) {
             throw Exception('Unsupported image format: $ext. Only ${validExtensions.join(', ')} are allowed.');
        }
     }


    final request = http.MultipartRequest('POST', Uri.parse(_uploadUrl));
    final mimeType = ext == 'png' ? 'image/png' : (ext == 'gif' ? 'image/gif' : 'image/jpeg');
    request.files.add(
      await http.MultipartFile.fromPath(
        'image',
        uploadFile.path,
        contentType: MediaType.parse(mimeType),
      ),
    );

    try {
        final response = await request.send().timeout(const Duration(seconds: 30));
        final responseData = await http.Response.fromStream(response);

        if (response.statusCode == 200) {
             final decodedBody = jsonDecode(responseData.body);
             if (decodedBody['url'] != null) {
                return decodedBody['url'];
             } else {
                 throw Exception('Image upload succeeded but URL not found in response.');
             }
        } else {
             throw Exception(
                'Image upload failed: ${response.statusCode} - ${responseData.body}',
             );
        }
    } on TimeoutException {
         throw Exception('Image upload timed out. Check server connection.');
    } catch (e) {
        debugPrint("Error during image upload: $e");
        rethrow; // Rethrow to be handled by the caller
    }

  }

  Future<String?> fetchFcmToken(String chauffeurId) async {
    try {
      final userDoc = await _firestore.collection('chauffeurs').doc(chauffeurId).get();
      if (userDoc.exists && userDoc.data() != null) {
        return userDoc.data()!['fcmToken'] as String?;
      } else {
        debugPrint('Chauffeur document $chauffeurId not found or missing fcmToken.');
        return null;
      }
    } catch (e) {
      debugPrint('Error fetching FCM token for $chauffeurId: $e');
      return null; // Don't throw, allow process to continue without notification maybe
    }
  }

  Future<void> sendPushNotification({
     required String token,
    required String title,
    required String body,
    Map<String, String>? data, // Accept optional data payload
  }) async {
    // Uses the _fcmServerKey defined above
    final String url = 'https://fcm.googleapis.com/fcm/send';
    final Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Authorization': 'key=$_fcmServerKey', // Use the class member
    };

    // Include data payload if provided
    final Map<String, dynamic> dataPayload = {
      'type': 'baggage_request', // Default type
      'click_action': 'FLUTTER_NOTIFICATION_CLICK', // Standard action
      ...?data, // Merge provided data
    };

    final Map<String, dynamic> requestBodyMap = {
      'to': token,
      'notification': {'title': title, 'body': body, 'sound': 'default'},
      'data': dataPayload,
      'priority': 'high',
    };

    try {
       log('Sending legacy FCM notification to: $token');
      final response = await http.post(
          Uri.parse(url),
          headers: headers,
          body: json.encode(requestBodyMap),
       ).timeout(const Duration(seconds: 20)); // Increased timeout slightly

      log('Legacy FCM Response Status: ${response.statusCode}');
       // Avoid logging full body in production if it might contain sensitive info
       // log('Legacy FCM Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
         // Check for errors within the FCM response itself
         if (responseData['failure'] == 1) {
            log('Legacy FCM notification failed (reported by FCM): ${responseData['results']?[0]?['error']}');
         } else {
            log('Legacy FCM notification sent successfully: ${responseData['results']?[0]?['message_id']}');
         }
      } else {
        log('Error sending legacy FCM notification: ${response.statusCode} - ${response.body}');
      }
    } on TimeoutException {
        log('Error sending legacy FCM notification: Request timed out.');
    } catch (e) {
      log('Exception while sending legacy FCM notification: $e');
    }
  }

  Future<void> submitBaggageData({
      required String userId,
      required String chauffeurId,
      required String trajetId,
      required List<ArticleData> articles,
      String? existingBaggageId, // Use this to determine create vs update
  }) async {

      // 1. Prepare baggage items (uploading new images)
      final List<Map<String, dynamic>> baggageItemsForFirestore = [];
      try {
          for (int i = 0; i < articles.length; i++) {
              final article = articles[i];
              final List<String> newlyUploadedUrls = [];

              // Upload only the new images (Files)
              for (final imageFile in article.images) {
                 final url = await _uploadImage(imageFile);
                 newlyUploadedUrls.add(url);
              }

              // Combine existing URLs and newly uploaded URLs for this article
              final allImageUrls = [...article.existingImageUrls, ...newlyUploadedUrls];

              final baggageNumber = 'Bagage ${i + 1}'; // Or use a unique ID if needed

              baggageItemsForFirestore.add({
                'baggageNumber': baggageNumber, // Optional: You might not need this field
                'description': article.descriptionController.text.trim(),
                'imageUrls': allImageUrls,
              });
          }
      } catch (e) {
           debugPrint("Error during image upload preparation: $e");
           throw Exception("Failed to upload one or more images. Please try again. Details: $e"); // Propagate error
      }


      // 2. Create or Update Firestore document
       final baggageData = {
          'userId': userId,
          'chauffeurId': chauffeurId,
          'items': baggageItemsForFirestore,
          'trajetId': trajetId,
          'status': 'En attente', // Reset status on update? Or handle differently?
          'timestamp': FieldValue.serverTimestamp(),
       };

       try {
           if (existingBaggageId == null) {
             // Create New
             final docRef = await _firestore.collection('baggage').add(baggageData);
             debugPrint("New baggage created with ID: ${docRef.id}");

             // Send notification only for new requests
             final chauffeurFcmToken = await fetchFcmToken(chauffeurId);
             if (chauffeurFcmToken != null) {
                 await sendPushNotification(
                   token: chauffeurFcmToken,
                   title: 'Nouvelle demande',
                   body: 'Vous avez une nouvelle demande de bagages.',
                 );
             }

           } else {
             // Update Existing
             // Decide which fields to update. Maybe status shouldn't be reset here?
             // Let's update items and timestamp. Status logic might be elsewhere.
             await _firestore.collection('baggage').doc(existingBaggageId).update({
                'items': baggageItemsForFirestore,
                'timestamp': FieldValue.serverTimestamp(),
                // Maybe update status to 'Modifié' or keep as is? Depends on workflow.
                // 'status': 'Modifié',
             });
              debugPrint("Baggage $existingBaggageId updated.");
              // Optionally send an "updated" notification?
           }
       } catch (e) {
           debugPrint("Error saving baggage data to Firestore: $e");
           throw Exception("Failed to save baggage details. Please try again. Details: $e");
       }
  }

   bool isValidImageExtension(String path) {
      final ext = path.split('.').last.toLowerCase();
      return ['jpg', 'jpeg', 'png', 'gif'].contains(ext);
   }
}