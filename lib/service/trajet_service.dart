// services/trajet_service.dart
 // Adjust path if needed
import 'package:bladi_go_client/models/trajet_models.dart'; // Adjust path if needed
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart'; // For debugPrint
import 'package:intl/intl.dart'; // For date formatting

class TrajetService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _trajetsCollection = 'trajets';
  static const String _chauffeursCollection = 'chauffeurs';

  // Get trajets based on specific pickup/delivery points and date range
  Future<List<TrajetDisplayData>> getTrajets({
    required String from,           // Specific pickup point
    required String to,             // Specific delivery point
    required String dateString,     // Input target date "YYYY/MM/DD"
    required String transportType,
    int dateRangeDays = 5,        // Search range (+/- days)
  }) async {
    debugPrint('Fetching trajets: From "$from", To "$to", Date "$dateString", Type "$transportType"');
    final DateFormat inputFormat = DateFormat('yyyy/MM/dd');

    try {
      // 1. Calculate Date Range (as strings in "YYYY/MM/DD" format)
      final DateTime targetDate = inputFormat.parseStrict(dateString);
      final DateTime startDate = targetDate.subtract(Duration(days: dateRangeDays));
      final DateTime endDate = targetDate.add(Duration(days: dateRangeDays));

      final List<String> dateStringsInRange = [];
      DateTime currentDate = startDate;
      while (!currentDate.isAfter(endDate)) {
        dateStringsInRange.add(inputFormat.format(currentDate));
        currentDate = currentDate.add(const Duration(days: 1));
      }

      if (dateStringsInRange.isEmpty) {
         debugPrint('No valid dates calculated for the range.');
         return [];
      }
      debugPrint('Searching within date strings: ${dateStringsInRange.join(', ')}');

      // 2. Initial Firestore Query: Filter by FROM point, transport type, and DATE STRINGS
      // NOTE: Requires a composite index on specificPickupPoints (array), transportType, and date (string)
      final query = _firestore
          .collection(_trajetsCollection)
          .where('specificPickupPoints', arrayContains: from) // Check if 'from' is in pickup points
          .where('transportType', isEqualTo: transportType)  // Match transport type
          .where('date', whereIn: dateStringsInRange); // Match any date within the calculated range

      final querySnapshot = await query.get();
      debugPrint('Initial Firestore query found ${querySnapshot.docs.length} potential trajets.');

      if (querySnapshot.docs.isEmpty) {
        return []; // No trajets match basic criteria
      }

      // 3. Client-Side Filtering for 'TO' point & Collect Chauffeur IDs
      final List<Trajet> potentialTrajets = [];
      final Set<String> chauffeurIds = {};

      for (var doc in querySnapshot.docs) {
          final data = doc.data() as Map<String, dynamic>?;
          if (data == null) continue;

          final List<dynamic>? deliveryPoints = data['specificDeliveryPoints'] as List<dynamic>?;

          // Check if 'to' point is in the delivery list AND chauffeurId exists
          if (deliveryPoints != null && deliveryPoints.contains(to)) {
              final trajet = Trajet.fromFirestore(doc); // Assume model handles parsing
              if (trajet.chauffeurId.isNotEmpty) { // Check for valid chauffeur ID
                  potentialTrajets.add(trajet);
                  chauffeurIds.add(trajet.chauffeurId);
              } else {
                   debugPrint('Trajet ${doc.id} matches points but missing chauffeurId.');
              }
          }
      }

      debugPrint('Filtered down to ${potentialTrajets.length} trajets containing "$to" in delivery points.');

      if (potentialTrajets.isEmpty) {
        return []; // No trajets match both 'from' and 'to'
      }
      debugPrint('Fetching details for ${chauffeurIds.length} unique chauffeurs: ${chauffeurIds.toList()}');


      // 4. Fetch Chauffeur Data (using chunks for safety with 'whereIn' limits)
      final Map<String, Chauffeur> chauffeursMap = {};
      const chunkSize = 30; // Firestore 'in' query limit (max 30)
      final List<String> chauffeurIdList = chauffeurIds.toList();

      for (int i = 0; i < chauffeurIdList.length; i += chunkSize) {
          // Get a chunk of IDs
          final chunk = chauffeurIdList.sublist(i, i + chunkSize > chauffeurIdList.length ? chauffeurIdList.length : i + chunkSize);
          if (chunk.isEmpty) continue; // Skip empty chunks

          // Fetch chauffeur documents for the current chunk
          final chauffeursQuery = await _firestore
              .collection(_chauffeursCollection)
              .where(FieldPath.documentId, whereIn: chunk)
              .get();

          // Add fetched chauffeurs to the map
          for (var doc in chauffeursQuery.docs) {
              try {
                  final chauffeur = Chauffeur.fromFirestore(doc); // Assuming model constructor
                  chauffeursMap[chauffeur.id] = chauffeur;
              } catch (e) {
                  debugPrint("Error parsing chauffeur doc ${doc.id}: $e");
              }
          }
      }
      debugPrint('Successfully fetched details for ${chauffeursMap.length} chauffeurs.');


      // 5. Combine Trajet and Chauffeur Data, Parse Date String to DateTime
      final List<TrajetDisplayData> combinedResults = [];
      for (final trajet in potentialTrajets) {
        final chauffeur = chauffeursMap[trajet.chauffeurId];
        if (chauffeur != null) {
           try {
             // **Parse the date string from the trajet model here**
             final DateTime trajetDateTime = inputFormat.parseStrict(trajet.date);
             combinedResults.add(TrajetDisplayData(
               trajet: trajet,
               chauffeur: chauffeur,
               dateTime: trajetDateTime, // Store the parsed DateTime
             ));
           } catch (e) {
             // Log error if a trajet's date string is invalid
             debugPrint("Error parsing date string '${trajet.date}' for trajet ${trajet.id}: $e. Skipping trajet.");
             continue; // Skip this trajet if date parsing fails
           }
        } else {
           // Log if chauffeur data wasn't found (might indicate data inconsistency)
           debugPrint('Chauffeur data not found for ID ${trajet.chauffeurId} (trajet ${trajet.id}), skipping combination.');
        }
      }

      // 6. Filter out past dates (Client-Side)
      final now = DateTime.now();
      // Get today's date at midnight for accurate comparison (ignores time)
      final todayAtMidnight = DateTime(now.year, now.month, now.day);

      final List<TrajetDisplayData> filteredResults = combinedResults.where((trajetData) {
        // Get the trajet's date (already parsed into DateTime)
        final trajetDate = trajetData.dateTime;
        // Compare only the date part, ignoring time
        final trajetDateAtMidnight = DateTime(trajetDate.year, trajetDate.month, trajetDate.day);
        // Keep if trajet date is today or in the future
        return !trajetDateAtMidnight.isBefore(todayAtMidnight);
      }).toList();

      debugPrint('Filtered ${combinedResults.length - filteredResults.length} past trajets. Kept ${filteredResults.length}.');

      // 7. Sort the final results by date
      filteredResults.sort((a, b) => a.dateTime.compareTo(b.dateTime));

      debugPrint('TrajetService: Returning ${filteredResults.length} final trajets.');
      return filteredResults; // Return the filtered and sorted list

    } on FormatException catch (e) {
       debugPrint('Error parsing input date string "$dateString": $e');
       throw Exception("Format de date invalide fourni: $dateString");
    } catch (e, s) { // Catch potential Firestore or other errors
      debugPrint('Erreur lors de la récupération des trajets: $e\nStackTrace: $s');
      // Rethrow a user-friendly exception
      throw Exception('Impossible de récupérer les trajets. Veuillez réessayer.');
    }
  }
}

// Ensure your TrajetDisplayData class includes the dateTime field
// Example:
// class TrajetDisplayData {
//   final Trajet trajet;
//   final Chauffeur chauffeur;
//   final DateTime dateTime; // Parsed date for filtering/sorting
//
//   TrajetDisplayData({
//     required this.trajet,
//     required this.chauffeur,
//     required this.dateTime,
//   });
// }