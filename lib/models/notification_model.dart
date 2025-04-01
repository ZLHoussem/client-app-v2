// notification_model.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String id; // Document ID from Firestore
  final String date;
  final String collectionPoint;
  final String deliveryPoint;
  final String driverName;
  final String statusMessage; // User-friendly status message
  final String rawStatus; // Original status string (e.g., 'En attente')
  final Color statusColor;
  final String chauffeurId;
  final String trajetId;
  final String userId;
  final List<dynamic> items;
  final Timestamp timestamp; // For sorting

  NotificationModel({
    required this.id,
    required this.date,
    required this.collectionPoint,
    required this.deliveryPoint,
    required this.driverName,
    required this.statusMessage,
    required this.rawStatus,
    required this.statusColor,
    required this.chauffeurId,
    required this.trajetId,
    required this.userId,
    required this.items,
    required this.timestamp,
  });
}