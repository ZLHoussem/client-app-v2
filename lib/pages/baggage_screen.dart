// lib/pages/modern_baggage_screen.dart

import 'dart:io';       // For File
import 'dart:developer'; // For log

import 'package:bladi_go_client/models/article_data.dart';            // Model
import 'package:bladi_go_client/notification/notification.api.dart';
import 'package:bladi_go_client/pages/home.dart';                     // Navigation Target
import 'package:bladi_go_client/provider/user.dart';                  // User Info
import 'package:bladi_go_client/service/baggage_service.dart';        // Backend Service

// Corrected Widget Imports
import 'package:bladi_go_client/widget/uiBaggageScreen/add_article_button.dart';
import 'package:bladi_go_client/widget/uiBaggageScreen/article_card.dart';       // Assume file matches class ArticleCardWidget
import 'package:bladi_go_client/widget/uiBaggageScreen/info_card.dart';          // Assume file matches class InfoCardWidget
import 'package:bladi_go_client/widget/uiBaggageScreen/submit_button.dart';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';


class ModernBaggageScreen extends StatefulWidget {
  // ... (Keep existing properties)
  final String locations;
  final String travelDate;
  final String transportType;
  final String chauffeurId;
  final String trajetId;
  final String? baggageId;

   const ModernBaggageScreen({
    super.key,
    required this.locations,
    required this.travelDate,
    required this.transportType,
    required this.chauffeurId,
    required this.trajetId,
    this.baggageId,
  });

  @override
  State<ModernBaggageScreen> createState() => _ModernBaggageScreenState();
}

class _ModernBaggageScreenState extends State<ModernBaggageScreen> {
  // State Variables
  // Initialize with one default article (constructor now handles default ID)
  List<ArticleData> articles = [ArticleData()];
  bool _isLoading = false;
  bool _isSubmitting = false;

  // Services (final makes them non-reassignable)
  final BaggageService _baggageService = BaggageService();
  final ImagePicker _picker = ImagePicker();

  // Constants (consider moving to a separate constants file)
  static const int _maxImagesPerArticle = 3;
  static const int _maxArticles = 5;

  // Location parsing result
  String _startLocation = 'N/A';
  String _endLocation = 'N/A';

  @override
  void initState() {
    super.initState();
    _parseLocations();
    // Load existing baggage only if ID is provided
    if (widget.baggageId != null) {
      _loadExistingBaggage();
    }
  }

  // Use a more robust separator if possible, e.g., " - "
  // Ensure the string format passed to the widget is consistent.
  void _parseLocations() {
     // Using '→' as per the original code. Ensure this is reliable.
     final locationParts = widget.locations.split('→');
     _startLocation = locationParts.isNotEmpty ? locationParts[0].trim() : 'N/A';
     // Check length before accessing index 1
     _endLocation = locationParts.length > 1 ? locationParts[1].trim() : 'N/A';
     log("Parsed locations: $_startLocation -> $_endLocation");
  }

  Future<void> _loadExistingBaggage() async {
    if (widget.baggageId == null) return; // Should not happen due to initState check, but safe guard.
    setState(() => _isLoading = true);
    try {
      final loadedArticles = await _baggageService.loadExistingBaggage(widget.baggageId!);
       // Check mounted *after* await
       if (!mounted) return;
      setState(() {
        // If loading resulted in an empty list, still initialize with one default article
        articles = loadedArticles.isNotEmpty ? loadedArticles : [ArticleData()];
      });
    } catch (e) {
      log('Error loading baggage in screen: $e');
      if (!mounted) return;
      _showSnackBar('Erreur lors du chargement des données existantes.', Colors.red);
      // Reset to a default article on error
       articles = [ArticleData()];
    } finally {
       if (mounted) {
          setState(() => _isLoading = false);
       }
    }
  }

  Future<void> _pickImages(int articleIndex) async {
    // Validate index
    if (articleIndex < 0 || articleIndex >= articles.length) return;

    final article = articles[articleIndex];
    final currentImageCount = article.images.length + article.existingImageUrls.length;
    final remainingSlots = _maxImagesPerArticle - currentImageCount;

    if (remainingSlots <= 0) {
      _showSnackBar('Limite de $_maxImagesPerArticle images atteinte pour cet article.', Colors.orange);
      return;
    }

    try {
      // Use pickMultipleMedia for better future-proofing, though pickMultiImage is fine
      final pickedFiles = await _picker.pickMultiImage(
        imageQuality: 85, // Slightly higher quality might be okay
        requestFullMetadata: false, // Usually not needed
      );

      // Check mounted *after* await
      if (pickedFiles.isEmpty || !mounted) return;

      setState(() {
          final validNewImages = pickedFiles
            .where((file) => _baggageService.isValidImageExtension(file.path))
            .take(remainingSlots)
            .map((file) => File(file.path)) // Create File object
            .toList();

         if (validNewImages.length < pickedFiles.length) {
            _showSnackBar(
              'Certaines images ont été ignorées (format invalide). Seules JPEG, PNG, GIF sont acceptées.',
              Colors.orange,
            );
         }
         // Add validated images to the list for the specific article
         articles[articleIndex].images.addAll(validNewImages);
      });

    } catch (e) {
       log("Error picking images: $e");
       if (!mounted) return;
       _showSnackBar("Erreur lors de la sélection d'images: $e", Colors.red);
    }
  }

  void _removeImage(int articleIndex, int imageIndex, {required bool isExisting}) {
     // Validate indexes
     if (articleIndex < 0 || articleIndex >= articles.length) return;

    setState(() {
      if (isExisting) {
         if (imageIndex >= 0 && imageIndex < articles[articleIndex].existingImageUrls.length) {
             articles[articleIndex].existingImageUrls.removeAt(imageIndex);
              log("Removed existing image at index $imageIndex for article $articleIndex");
         }
      } else {
          if (imageIndex >= 0 && imageIndex < articles[articleIndex].images.length) {
             // Optional: Delete the actual File if it's temporary? Depends on picker behavior.
             articles[articleIndex].images.removeAt(imageIndex);
              log("Removed new image at index $imageIndex for article $articleIndex");
          }
      }
    });
  }

  void _addArticle() {
    if (articles.length < _maxArticles) {
      // Add a new ArticleData (constructor handles default ID)
      setState(() => articles.add(ArticleData()));
       log("Added new article. Total articles: ${articles.length}");
    } else {
      _showSnackBar('Vous ne pouvez pas ajouter plus de $_maxArticles articles.', Colors.orange);
    }
  }

  void _deleteArticle(int index) {
    // Validate index and condition
    if (articles.length > 1 && index >= 0 && index < articles.length) {
       // Get the article *before* removing it to dispose its controller
       final articleToRemove = articles[index];
      setState(() {
          articles.removeAt(index);
          log("Removed article at index $index. Total articles: ${articles.length}");
      });
      // Dispose the controller *after* setState has removed it from the list being built
      WidgetsBinding.instance.addPostFrameCallback((_) {
         articleToRemove.dispose();
         log("Disposed controller for removed article at index $index.");
      });
    } else if (articles.length == 1) {
        _showSnackBar("Vous devez conserver au moins un article.", Colors.orange);
    }
  }

  bool _validateInput() {
    for (int i = 0; i < articles.length; i++) {
       final article = articles[i];
       final articleNum = i + 1;
        if (article.images.isEmpty && article.existingImageUrls.isEmpty) {
          _showSnackBar('Article $articleNum: Veuillez ajouter au moins une image.', Colors.orange);
          return false;
        }
        final description = article.descriptionController.text.trim();
        if (description.isEmpty) {
           _showSnackBar('Article $articleNum: Veuillez ajouter une description.', Colors.orange);
          return false;
        }
         if (description.length > 100) { // Use constant if defined elsewhere
           _showSnackBar('Article $articleNum: La description doit faire 100 caractères maximum.', Colors.orange);
          return false;
        }
    }
    // All articles are valid
    return true;
  }

 // *** SUBMIT METHOD using NotificationApi ***
 Future<void> _submitBaggage() async {
    // 1. Validation and State Check
    if (!_validateInput() || _isSubmitting) return;

    setState(() => _isSubmitting = true);
    
    final userId = Provider.of<UserProvider>(context, listen: false).userId;
    // 2. Get User ID
      await _baggageService.submitBaggageData(
        userId: userId ?? ' ',
        chauffeurId: widget.chauffeurId,
        trajetId: widget.trajetId,
        articles: articles,
        existingBaggageId: widget.baggageId,
      );
    // Use context.read for one-time reads inside callbacks/functions
   
    if (userId == null) {
        _showSnackBar('Erreur: Utilisateur non identifié. Veuillez vous reconnecter.', Colors.red);
        setState(() => _isSubmitting = false);
        return;
    }

    // 3. Call Backend Service
    try {
    

      // Check mounted state *after* the async call
      if (!mounted) return;

      // --- 4. Send Notification (Only on *New* Submission Success) ---
      final bool isNewSubmission = widget.baggageId == null;
      if (isNewSubmission ) {
         log('New baggage request created . Preparing notification using NotificationApi.');
         // Using a separate function for clarity
         await _sendNotificationToChauffeur(); // This now uses NotificationApi
      } else if (!isNewSubmission) {
           log('Baggage updated (ID: ${widget.baggageId}). No notification needed.');
      } else {
           log('Baggage submission finished, but resulting ID was null. Cannot send notification.');
      }

      // 5. Handle Success UI
      setState(() => _isSubmitting = false);
      _showSuccessDialog();

    } catch (e) {
      // 6. Handle Error UI
      log('Error during baggage submission process: $e');
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      _showSnackBar('Erreur lors de la soumission: ${e.toString()}', Colors.red);
    }
  }

  // *** Helper function that uses NotificationApi ***
  Future<void> _sendNotificationToChauffeur() async {
     try {
        // Use BaggageService to fetch the token
        final chauffeurFcmToken = await _baggageService.fetchFcmToken(widget.chauffeurId);

        if (chauffeurFcmToken != null) {
          log('Sending notification via NotificationApi to token: $chauffeurFcmToken for baggage ');

          // *** CORRECTED: CALL NotificationApi.sendNotification ***
          final notificationResult = await NotificationApi.sendNotification( // Use the static method
            targetToken: chauffeurFcmToken,
            title: 'Nouvelle demande de bagages',
            body: 'Reçu une demande: $_startLocation → $_endLocation.', // Use parsed state variables
            data: {
              // 'click_action' is handled internally by sendNotification now
              'type': 'baggage_request',
              
              'trajetId': widget.trajetId,
              'chauffeurId': widget.chauffeurId,
            },
          );

          // Log result from NotificationApi's response map
          if (notificationResult['success'] == true) {
             log('NotificationApi: Sent successfully to chauffeur ${widget.chauffeurId}.');
          } else {
             final errorMessage = notificationResult['message'] ?? 'Unknown error';
             log('NotificationApi: Failed to send notification to chauffeur ${widget.chauffeurId}: $errorMessage');
             // _showSnackBar('Avertissement: Echec envoi notification chauffeur.', Colors.orange); // Optional feedback
          }
        } else {
           log('Could not send notification: Chauffeur FCM token not found via service for ${widget.chauffeurId}.');
           // _showSnackBar('Avertissement: Token chauffeur introuvable.', Colors.orange); // Optional feedback
        }
     } catch (e) {
        log("Error during _sendNotificationToChauffeur phase: $e");
        // _showSnackBar('Erreur envoi notification.', Colors.orange); // Optional feedback
     }
  }


  // --- UI Feedback Methods ---
  void _showSnackBar(String message, Color backgroundColor) {
     if (!mounted) return;
     // Ensure context is still valid before showing snackbar
     if (ScaffoldMessenger.maybeOf(context) != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(message),
              backgroundColor: backgroundColor,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 3),
              margin: const EdgeInsets.all(10), // Add margin
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), // Rounded shape
          ),
        );
     } else {
         log("Could not show snackbar: ScaffoldMessenger not available.");
     }
  }

 void _showSuccessDialog() {
     if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) => AlertDialog( // Use specific context
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)), // Rounded dialog
            title: const Row( // Icon in title
              children: [
                Icon(Icons.check_circle_outline, color: Colors.green),
                SizedBox(width: 10),
                Text('Succès'),
              ],
            ),
            content: Text(
              widget.baggageId == null
                  ? 'Votre demande de bagages a été soumise avec succès!'
                  : 'Vos informations de bagages ont été mises à jour avec succès!',
              style: const TextStyle(fontSize: 15),
            ),
            actions: [
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).primaryColor
                ),
                onPressed: () {
                  Navigator.pop(dialogContext); // Use dialogContext to pop
                  // Ensure Home is imported correctly
                  Navigator.pushAndRemoveUntil(
                    context, // Use original context for navigation
                    MaterialPageRoute(builder: (_) => const Home()),
                    (route) => false,
                  );
                },
                child: const Text('OK', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
    );
  }

  @override
  void dispose() {
    log("Disposing ModernBaggageScreen State");
    // Dispose all text controllers
    for (final article in articles) {
      // Assuming descriptionController is managed within ArticleData instance
      article.dispose();
    }
    super.dispose();
  }


  // --- Build Method ---
  @override
  Widget build(BuildContext context) {
    final bool canAddMoreArticles = articles.length < _maxArticles;
    final String submitButtonLabel = widget.baggageId == null
                            ? 'Soumettre la Demande'
                            : 'Mettre à Jour';

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          widget.baggageId == null ? 'Ajouter des Bagages' : 'Modifier les Bagages',
          style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87, size: 20), // iOS style back arrow
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(), // Dismiss keyboard on tap outside fields
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 40), // Add more bottom padding
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Info Card
                    InfoCardWidget(
                        travelDate: widget.travelDate,
                        startLocation: _startLocation, // Use state variables
                        endLocation: _endLocation,   // Use state variables
                    ),
                    const SizedBox(height: 24),

                    // Section Title
                     const Text(
                      'Articles et Photos',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    const SizedBox(height: 8),
                     Text(
                      'Ajoutez chaque article séparément avec jusqu\'à $_maxImagesPerArticle photos.',
                       style: const TextStyle(fontSize: 13, color: Colors.black54),
                    ),
                    const SizedBox(height: 16),

                    // Article Cards List using ListView.builder
                    ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(), // Essential within SingleChildScrollView
                        itemCount: articles.length,
                        itemBuilder: (context, index) {
                          final article = articles[index];
                          // Use ValueKey with the article's unique ID for efficient rebuilds
                          return ArticleCardWidget(
                              key: ValueKey(article),
                              index: index,
                              article: article,
                              maxImagesPerArticle: _maxImagesPerArticle,
                              onDelete: articles.length > 1 ? () => _deleteArticle(index) : null,
                              onPickImages: () => _pickImages(index),
                              onRemoveImage: (imageIndex, isExisting) =>
                                  _removeImage(index, imageIndex, isExisting: isExisting),
                           );
                        },
                     ),

                    // Add Article Button
                    AddArticleButton(
                        onPressed: _addArticle,
                        enabled: canAddMoreArticles,
                    ),
                    const SizedBox(height: 30),

                    // Submit Button
                    SubmitBaggageButton( // *** Uses the imported widget ***
                        isLoading: _isSubmitting,
                        onPressed: _submitBaggage,
                        label: submitButtonLabel,
                    ),
                     // Removed extra SizedBox at bottom, handled by SingleChildScrollView padding
                  ],
                ),
              ),
            ),
    );
  }
}