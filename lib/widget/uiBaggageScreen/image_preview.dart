// lib/uiBaggageScreen/image_preview.dart
import 'dart:io';
import 'package:flutter/material.dart';

// Base widget for the preview layout (image + remove button) - Updated Style
class _ImagePreviewBase extends StatelessWidget {
  final Widget imageChild;
  final VoidCallback onRemove;
  // Removed theme parameter

  const _ImagePreviewBase({
    required this.imageChild,
    required this.onRemove,
    // required this.theme, // Removed
  });

  @override
  Widget build(BuildContext context) {
    return Container( // Outer container for margin
      margin: const EdgeInsets.only(right: 10), // Target margin
      child: Stack( // Use Stack for overlaying remove button
        children: [
          // Image container with border
          Container(
            width: 80, // Target size
            height: 80, // Target size
            decoration: BoxDecoration(
              border: Border.all(color: Colors.blue, width: 2), // Target border
              borderRadius: BorderRadius.circular(8.0), // Target radius
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8.0), // Match container radius
              child: imageChild,
            ),
          ),
          // Remove button - Target style
          Positioned(
            top: 0, // Target position
            right: 0, // Target position (relative to Stack, margin handles outer spacing)
            child: GestureDetector( // Use GestureDetector as per target
              onTap: onRemove,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: Colors.red, // Target background
                  shape: BoxShape.circle, // Target shape
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 16), // Target icon style
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Specific preview widget for new File images - Updated Style
class FileImagePreview extends StatelessWidget {
  final File imageFile;
  final VoidCallback onRemove;
  // Removed theme parameter

  const FileImagePreview({
    super.key,
    required this.imageFile,
    required this.onRemove,
    // required this.theme, // Removed
  });

  @override
  Widget build(BuildContext context) {
    return _ImagePreviewBase(
      imageChild: Image.file(
        imageFile,
        fit: BoxFit.cover,
        width: 80, height: 80, // Target size
        // Removed errorBuilder as target doesn't specify one here
      ),
      onRemove: onRemove,
    );
  }
}

// Specific preview widget for existing URL images - Updated Style
class UrlImagePreview extends StatelessWidget {
  final String imageUrl;
  final VoidCallback onRemove;
  // Removed theme parameter

  const UrlImagePreview({
    super.key,
    required this.imageUrl,
    required this.onRemove,
    // required this.theme, // Removed
  });

  @override
  Widget build(BuildContext context) {
    return _ImagePreviewBase(
      imageChild: Image.network(
        imageUrl,
        fit: BoxFit.cover,
        width: 80, height: 80, // Target size
        // Removed loadingBuilder and errorBuilder as target doesn't specify them
      ),
      onRemove: onRemove,
    );
  }
}