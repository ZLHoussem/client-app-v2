// lib/uiBaggageScreen/article_card.dart
import 'package:bladi_go_client/models/article_data.dart';
import 'package:flutter/material.dart';
import 'dart:io'; // For File type used in ArticleData

// Assuming ArticleData is defined elsewhere (e.g., models/article_data.dart)
// If not, define it here or import it.
// Example: import 'package:bladi_go_client/models/article_data.dart';

// Import your specific image preview widgets if they differ from the generic ones below

/// Displays the details for a single baggage article, including images and description.

/// Displays the details for a single baggage article, including images and description.
/// Styled according to the target design provided.
class ArticleCardWidget extends StatelessWidget {
  final int index; // Index of this article in the list
  final ArticleData article;
  final int maxImagesPerArticle; // Use this to control add button visibility
  final VoidCallback?
  onDelete; // Callback when the delete button is pressed (nullable to control visibility)
  final VoidCallback onPickImages; // Callback to trigger image picking
  final Function(int imageIndex, bool isExisting)
  onRemoveImage; // Callback to remove an image

  const ArticleCardWidget({
    Key? key,
    required this.index,
    required this.article,
    required this.maxImagesPerArticle, // Keep using this standard prop name
    this.onDelete, // If null, delete button won't show
    required this.onPickImages,
    required this.onRemoveImage,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Use maxImagesPerArticle for consistency with other parts of the code
    final totalImages =
        article.images.length + article.existingImageUrls.length;
    final bool canAddMoreImages = totalImages < maxImagesPerArticle;

    // Use Container with margin and decoration matching the target _buildArticleCard
    return Container(
      margin: const EdgeInsets.only(bottom: 16), // Target margin
      decoration: BoxDecoration(
        // Target border style from the second definition
        border: Border.all(color: Colors.blue, width: 2),
        borderRadius: BorderRadius.circular(10), // Target radius
        color:
            Colors
                .white, // Ensure background is white if needed (TextField is white)
      ),
      padding: const EdgeInsets.all(16), // Target padding
      child: Stack(
        // Use Stack to position the delete button
        clipBehavior: Clip.none, // Allow button overflow slightly
        children: [
          // Main content column
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Image Section --- (No "Article X" title in target design)
              SingleChildScrollView(
                // Target layout
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    // Existing Images (Using ImagePreviewWidget, assuming it styles correctly)
                    ...article.existingImageUrls.asMap().entries.map(
                      (entry) => ImagePreviewWidget(
                        // Use the standard preview widget
                        key: ValueKey('existing_${entry.key}_${entry.value}'),
                        imageUrl: entry.value,
                        onRemove: () => onRemoveImage(entry.key, true),
                      ),
                    ),
                    // New Images (Using ImagePreviewWidget)
                    ...article.images.asMap().entries.map(
                      (entry) => ImagePreviewWidget(
                        // Use the standard preview widget
                        key: ValueKey('new_${entry.key}_${entry.value.path}'),
                        imageFile: entry.value,
                        onRemove: () => onRemoveImage(entry.key, false),
                      ),
                    ),
                    // Add Button - Target Style (Inline GestureDetector + Container)
                    if (canAddMoreImages)
                      GestureDetector(
                        onTap: onPickImages, // Use the callback from props
                        child: Container(
                          width: 80, // Target size
                          height: 80, // Target size
                          margin: const EdgeInsets.only(
                            right: 10,
                          ), // Target margin for button
                          decoration: BoxDecoration(
                            // Target border style for add button
                            border: Border.all(color: Colors.black, width: 1),
                            borderRadius: BorderRadius.circular(
                              8,
                            ), // Target radius
                          ),
                          child: const Icon(
                            Icons.add,
                            color: Colors.black,
                          ), // Target icon
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16), // Target spacing
              // --- Description Field - Target Style ---
              TextField(
                controller: article.descriptionController,
                decoration: InputDecoration(
                  // Target decoration from second definition
                  hintText: 'Description courte', // Target hint
                  hintStyle: const TextStyle(
                    // Target hint style
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    // Target padding
                    horizontal: 10,
                    vertical: 8,
                  ),
                  filled: true, // Target fill
                  fillColor: Colors.white, // Target fill color (Matches target)
                  border: OutlineInputBorder(
                    // Target base border
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.black, width: 1),
                  ),
                  enabledBorder: OutlineInputBorder(
                    // Target enabled border
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.black, width: 1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    // Target focused border
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.blue, width: 2),
                  ),
                  counterText:
                      "", // Hide counter to match implicit target style
                ),
                maxLines: 2, // Target max lines
                maxLength: 100, // Target max length
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black,
                ), // Target text style
                textInputAction: TextInputAction.done,
              ),
            ],
          ),

          // Delete Button - Positioned inside Stack (Target Style)
          // Show based on whether the onDelete callback is provided
          if (onDelete != null)
            Positioned(
              // Target positioning from second definition (adjust if needed)
              top: -4,
              right: -4,
              child: IconButton(
                icon: const Icon(
                  Icons.delete,
                  color: Colors.red,
                  size: 20,
                ), // Target style
                onPressed: onDelete, // Use the callback from props
                padding: const EdgeInsets.all(4), // Target minimal padding
                constraints:
                    const BoxConstraints(), // Target minimal constraints
                tooltip: 'Supprimer Article', // Generic tooltip
              ),
            ),
        ],
      ),
    );
  }

  // Assuming ImagePreviewWidget looks something like this:
  // (Adapt styling inside this if needed, though the main card styling is applied above)
}
class ImagePreviewWidget extends StatelessWidget {
  final File? imageFile;
  final String? imageUrl;
  final VoidCallback onRemove;

  const ImagePreviewWidget({
    Key? key,
    this.imageFile,
    this.imageUrl,
    required this.onRemove,
  }) : assert(imageFile != null || imageUrl != null),
       super(key: key);

  @override
  Widget build(BuildContext context) {
    // Basic structure, styling might need adjustments based on original ImagePreview
    return Container(
       margin: const EdgeInsets.only(right: 10, bottom: 4, top: 4),
       child: Stack(
         clipBehavior: Clip.none,
         children: [
           Container(
             width: 80,
             height: 80,
             decoration: BoxDecoration(
               border: Border.all(color: Colors.grey.shade300, width: 1),
               borderRadius: BorderRadius.circular(8),
               color: Colors.grey.shade100,
             ),
             child: ClipRRect(
               borderRadius: BorderRadius.circular(7.5),
               child: imageFile != null
                   ? Image.file(imageFile!, fit: BoxFit.cover)
                   : Image.network(imageUrl!, fit: BoxFit.cover, /* Add loaders/error builders */),
             ),
           ),
           Positioned(
             top: -6,
             right: -6,
             child: Material(
               shape: const CircleBorder(),
               clipBehavior: Clip.antiAlias,
               color: Colors.black.withOpacity(0.6),
               child: InkWell(
                 onTap: onRemove,
                 child: const Padding(
                   padding: EdgeInsets.all(3.0),
                   child: Icon(Icons.close, color: Colors.white, size: 15),
                 ),
               ),
             ),
           ),
         ],
       ),
    );
  }
}
