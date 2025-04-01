// services/trajet_service.dart
import 'package:bladi_go_client/models/trajet_models.dart'; // Import models
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart'; // For debugPrint
import 'package:intl/intl.dart'; // For date formatting

class TrajetService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _trajetsCollection = 'trajets';
  static const String _chauffeursCollection = 'chauffeurs';

  // Optimized function to get trajets
  Future<List<TrajetDisplayData>> getTrajets({
    required String from,
    required String to,
    required String dateString, // Input date "YYYY/MM/DD"
    required String transportType,
    int dateRangeDays = 5, // +/- days around the target date
  }) async {
    try {
      // --- (Keep date range calculation and Firestore queries as before) ---
      final DateFormat inputFormat = DateFormat('yyyy/MM/dd');
      final DateTime targetDate = inputFormat.parse(dateString);
      final DateTime startDate = targetDate.subtract(Duration(days: dateRangeDays));
      final DateTime endDate = targetDate.add(Duration(days: dateRangeDays));

      final List<String> dateStringsInRange = [];
      DateTime currentDate = startDate;
      while (!currentDate.isAfter(endDate)) {
        dateStringsInRange.add(inputFormat.format(currentDate));
        currentDate = currentDate.add(const Duration(days: 1));
      }

      if (dateStringsInRange.isEmpty) {
         debugPrint('No dates in range calculated.');
         return [];
      }
      debugPrint('Searching for dates: ${dateStringsInRange.join(', ')}');

      final trajetsQuery = await _firestore
          .collection(_trajetsCollection)
          .where('value', isEqualTo: '$from → $to')
          .where('style', isEqualTo: transportType)
          .where('date', whereIn: dateStringsInRange)
          .get();
      debugPrint('Firestore returned ${trajetsQuery.docs.length} trajets matching criteria.');

      if (trajetsQuery.docs.isEmpty) return [];

      final List<Trajet> fetchedTrajets = [];
      final Set<String> chauffeurIds = {};
      for (var doc in trajetsQuery.docs) {
        final trajet = Trajet.fromFirestore(doc);
        if (trajet.chauffeurId.isNotEmpty) {
          fetchedTrajets.add(trajet);
          chauffeurIds.add(trajet.chauffeurId);
        } else {
          debugPrint('Trajet ${trajet.id} skipped due to missing chauffeurId.');
        }
      }
      if (chauffeurIds.isEmpty) {
         debugPrint('No valid chauffeur IDs found in fetched trajets.');
         return [];
      }
      debugPrint('Fetching details for ${chauffeurIds.length} unique chauffeurs: ${chauffeurIds.toList()}');

      final List<String> chauffeurIdList = chauffeurIds.toList();
      final Map<String, Chauffeur> chauffeursMap = {};
      const chunkSize = 30;
      for (int i = 0; i < chauffeurIdList.length; i += chunkSize) {
          final chunk = chauffeurIdList.sublist(i, i + chunkSize > chauffeurIdList.length ? chauffeurIdList.length : i + chunkSize);
          if (chunk.isEmpty) continue;
          final chauffeursQuery = await _firestore
              .collection(_chauffeursCollection)
              .where(FieldPath.documentId, whereIn: chunk)
              .get();
          for (var doc in chauffeursQuery.docs) {
              final chauffeur = Chauffeur.fromFirestore(doc);
              chauffeursMap[chauffeur.id] = chauffeur;
          }
      }
      debugPrint('Successfully fetched details for ${chauffeursMap.length} chauffeurs.');

      // --- (Combine data as before) ---
      final List<TrajetDisplayData> combinedResults = [];
      for (final trajet in fetchedTrajets) {
        final chauffeur = chauffeursMap[trajet.chauffeurId];
        if (chauffeur != null) {
           try {
             final DateTime trajetDateTime = inputFormat.parse(trajet.date);
             combinedResults.add(TrajetDisplayData(
               trajet: trajet,
               chauffeur: chauffeur,
               dateTime: trajetDateTime,
             ));
           } catch (e) {
             debugPrint("Error parsing date string '${trajet.date}' for trajet ${trajet.id}: $e");
             continue;
           }
        } else {
           debugPrint('Chauffeur data not found for ID ${trajet.chauffeurId} (trajet ${trajet.id}), skipping.');
        }
      }

      // ******** START: FILTERING LOGIC ********
      // Get the current date at midnight for accurate comparison
      final now = DateTime.now();
      final todayAtMidnight = DateTime(now.year, now.month, now.day);

      // Filter the combined results to keep only today's and future trajets
      final List<TrajetDisplayData> filteredResults = combinedResults.where((trajetData) {
        // Ensure comparison happens only at the date level (ignore time)
        final trajetDate = trajetData.dateTime;
        final trajetDateAtMidnight = DateTime(trajetDate.year, trajetDate.month, trajetDate.day);
        // Keep the trajet if its date is NOT before today's date at midnight
        return !trajetDateAtMidnight.isBefore(todayAtMidnight);
      }).toList();

      debugPrint('TrajetService: Filtered ${combinedResults.length - filteredResults.length} past trajets. Kept ${filteredResults.length}.');
      // ******** END: FILTERING LOGIC ********


      // Sort the *filtered* results by date
      filteredResults.sort((a, b) => a.dateTime.compareTo(b.dateTime));

      debugPrint('TrajetService: Returning ${filteredResults.length} sorted trajets.');
      return filteredResults; // Return the final, filtered, and sorted list

    } on FormatException catch (e) {
       debugPrint('Error parsing date string "$dateString": $e');
       throw Exception("Format de date invalide fourni: $dateString");
    } catch (e, s) {
      debugPrint('Erreur lors de la récupération des trajets: $e\nStackTrace: $s');
      throw Exception('Impossible de récupérer les trajets. Veuillez réessayer.');
    }
  }
}