import 'dart:io';

import 'package:flutter/material.dart';

class ArticleData {
  final List<File> images = [];
  List<String> existingImageUrls = [];
  final TextEditingController descriptionController = TextEditingController();

  void dispose() => descriptionController.dispose();

  // Add a constructor to potentially initialize from existing data if needed later
  ArticleData({String initialDescription = '', List<String>? initialUrls}) {
      descriptionController.text = initialDescription;
      existingImageUrls = initialUrls ?? [];
  }

  // Method to easily convert to Map for Firestore
   Map<String, dynamic> toMap(List<String> uploadedImageUrls) {
    return {
      'description': descriptionController.text.trim(),
      'imageUrls': [...existingImageUrls, ...uploadedImageUrls], // Combine existing and new
    };
  }
}