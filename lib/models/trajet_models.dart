// models/trajet_models.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Trajet {
  final String id;
  final String value; // e.g., "Paris → Lyon"
  final String style; // e.g., "Bateau" or "Avion"
  final String date; // e.g., "YYYY/MM/DD"
  final String chauffeurId;
  final String? pickup; // Derived
  final String? delivery; // Derived

  Trajet({
    required this.id,
    required this.value,
    required this.style,
    required this.date,
    required this.chauffeurId,
    this.pickup,
    this.delivery,
  });

  factory Trajet.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    final valueParts = (data['value'] as String?)?.split(' → ');
    return Trajet(
      id: doc.id,
      value: data['value'] ?? 'N/A',
      style: data['style'] ?? 'N/A',
      date: data['date'] ?? 'N/A', // Keep as String from Firestore
      chauffeurId: data['chauffeurId'] ?? '',
      pickup: valueParts != null && valueParts.isNotEmpty ? valueParts[0] : null,
      delivery: valueParts != null && valueParts.length > 1 ? valueParts[1] : null,
    );
  }
}

class Chauffeur {
  final String id;
  final String name;
  final String lastName;
  final String vehicle;
  final String vehicleColor;
  final String? vehicleImageUrl; // Make nullable if it can be missing

  String get fullName => '$name $lastName'.trim();

  Chauffeur({
    required this.id,
    required this.name,
    required this.lastName,
    required this.vehicle,
    required this.vehicleColor,
    this.vehicleImageUrl,
  });

  factory Chauffeur.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Chauffeur(
      id: doc.id,
      name: data['name'] ?? 'Inconnu',
      lastName: data['lastName'] ?? '',
      vehicle: data['vehicle'] ?? 'N/A',
      vehicleColor: data['vehicleColor'] ?? 'N/A',
      vehicleImageUrl: data['vehicleImageUrl'], // Can be null
    );
  }
}

// Combined Model for UI Display
class TrajetDisplayData {
  final Trajet trajet;
  final Chauffeur chauffeur;
  final DateTime dateTime; // Actual DateTime object for sorting/comparison

  TrajetDisplayData({
    required this.trajet,
    required this.chauffeur,
    required this.dateTime,
  });
}