// lib/models/trajet_models.dart

import 'package:cloud_firestore/cloud_firestore.dart';

// --- Trajet Class (Keep previous fixes including routePreview) ---
class Trajet {
  final String id;
  final String chauffeurId;
  final String date; // YYYY/MM/DD string
  final String transportType;
  final String? style; // Keep if different from transportType
  final String? value; // Purpose still unclear, ensure handled if nullable
  final String? routePreview; // Keep this addition
  final List<String> specificPickupPoints;
  final List<String> specificDeliveryPoints;
  final String status;
  // final Timestamp timestamp; // Add back if you parse the timestamp string from Firestore

  Trajet({
    required this.id,
    required this.chauffeurId,
    required this.date,
    required this.transportType,
    this.style,
    this.value, // Handle null in widgets if necessary
    this.routePreview,
    required this.specificPickupPoints,
    required this.specificDeliveryPoints,
    required this.status,
    // this.timestamp,
  });

  factory Trajet.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    List<String> _dynamicListToStringList(List<dynamic>? dynamicList) {
      return dynamicList?.whereType<String>().toList() ?? []; // Simpler/Safer way
    }

    return Trajet(
      id: doc.id,
      chauffeurId: data['chauffeurId'] ?? '',
      date: data['date'] ?? '', // YYYY/MM/DD string
      transportType: data['transportType'] ?? '',
      style: data['style'], // Only if different from transportType
      value: data['value'], // Allow null
      routePreview: data['routePreview'],
      specificPickupPoints: _dynamicListToStringList(data['specificPickupPoints']),
      specificDeliveryPoints: _dynamicListToStringList(data['specificDeliveryPoints']),
      status: data['status'] ?? 'inconnu',
      // timestamp: data['timestamp'], // If parsing timestamp string later
    );
  }
}


// --- Chauffeur Class (MODIFIED) ---
class Chauffeur {
  final String id;
  final String nom;
  final String prenom;
  final String telephone;
  // Removed: vehicleImageUrl, vehicle, vehicleColor

  // Add other relevant chauffeur fields available in Firestore

  Chauffeur({
    required this.id,
    required this.nom,
    required this.prenom,
    required this.telephone,
    // other fields...
  });

  // Add a getter for full name
  String get fullName => '$prenom $nom'.trim();

  factory Chauffeur.fromFirestore(DocumentSnapshot doc) {
     Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
     return Chauffeur(
        id: doc.id,
        nom: data['nom'] ?? '',
        prenom: data['prenom'] ?? '',
        telephone: data['telephone'] ?? '',
        // Map other fields...
     );
  }
}


// --- TrajetDisplayData Class (Keep as is) ---
class TrajetDisplayData {
  final Trajet trajet;
  final Chauffeur chauffeur;
  final DateTime dateTime; // Parsed date for filtering/sorting

  TrajetDisplayData({
    required this.trajet,
    required this.chauffeur,
    required this.dateTime,
  });
}