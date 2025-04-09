import 'dart:developer';

import 'package:bladi_go_client/notification/notification.api.dart';
import 'package:bladi_go_client/pages/home.dart';
// sendPushNotification import is not needed if using NotificationApi directly
import 'package:bladi_go_client/provider/user.dart';
import 'package:bladi_go_client/service/baggage_service.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_animate/flutter_animate.dart';
// Import the actual HomePage widget from your project
// Assuming it's in 'pages/home_page.dart' - adjust the path if necessary

import 'package:bladi_go_client/pages/notification.dart';
import 'package:provider/provider.dart';

class ChauffeurProposalScreen extends StatefulWidget {
  final String trajetId;
  final String chauffeurId;
  final String date;
  final String collectionPoint;
  final String deliveryPoint;

  const ChauffeurProposalScreen({
    super.key,
    required this.trajetId,
    required this.chauffeurId,
    required this.date,
    required this.collectionPoint,
    required this.deliveryPoint,
  });

  @override
  State<ChauffeurProposalScreen> createState() =>
      _ChauffeurProposalScreenState();
}

class _ChauffeurProposalScreenState extends State<ChauffeurProposalScreen> {
  String chauffeurName = 'Chargement...';
  double price = 0.0;
  String currencySymbol = '';
  String? paymentDocId;
  bool isLoading = true;
  bool hasProposal = false;
  bool isProcessing = false;
  int counterProposalCount = 0;
  final BaggageService _baggageService = BaggageService(); // Instance for reuse

  // --- Style Constants (similar to BaggageItemCard) ---
  static final _kGreyShade700 = Colors.grey.shade700;
  static final _kGreyShade600 = Colors.grey.shade600;
  static final _kGreyShade400 = Colors.grey.shade400;
  static final _kGreyShade300 = Colors.grey.shade300;
  static final _kGreyShade200 = Colors.grey.shade200;
  static final _kGreyShade100 = Colors.grey.shade100;
  static final _kGreyShade50 = Colors.grey.shade50;
  static final _kBlackOpacity87 = Colors.black.withOpacity(0.87);
  static final _kBlackOpacity05 = Colors.black.withOpacity(0.05);


  @override
  void initState() {
    super.initState();
    _fetchProposalDetails();
  }

  // --- Data Fetching and Logic (As provided in the prompt) ---
Future<void> _fetchProposalDetails() async {
    if (!mounted) return;
    setState(() {
      isLoading = true;
      hasProposal = false;
      paymentDocId = null;
      counterProposalCount = 0;
    });

    try {
      DocumentSnapshot chauffeurDoc;
      try {
        chauffeurDoc = await FirebaseFirestore.instance
            .collection('chauffeurs')
            .doc(widget.chauffeurId)
            .get();
        if (chauffeurDoc.exists) {
          final data = chauffeurDoc.data()! as Map<String, dynamic>;
          final name = data['name'] ?? 'Inconnu';
          final lastName = data['lastName'] ?? '';
          chauffeurName = '$name $lastName'.trim();
        } else {
          chauffeurName = 'Chauffeur non trouvé';
        }
      } catch (e) {
        debugPrint('Erreur fetch chauffeur: $e');
        chauffeurName = 'Erreur chargement';
         // Add this to prevent proceeding with wrong name if fetch fails
         if (mounted) setState(() => isLoading = false);
         return;
      }

      final userId = Provider.of<UserProvider>(context, listen: false).userId;
      if (userId == null || userId.isEmpty) {
        throw Exception("User ID from Provider is missing.");
      }

      // This query fetches *all* payments for the user. It might be better to filter
      // further by trajetId or chauffeurId if possible, depending on your data structure.
      // The original code assumes the first found payment is the relevant one.
      final paymentSnapshot = await FirebaseFirestore.instance
          .collection('payments')
          .where('userId', isEqualTo: userId)
          // Optional: Add more .where clauses if needed for accuracy
          .where('chauffeurId', isEqualTo: widget.chauffeurId) // Match specific chauffeur
          //.where('trajetId', isEqualTo: widget.trajetId) // Match specific trajet if ID stored in payments
           .where('status', whereIn: ['En proposition', 'Contre-proposition Client 1', 'Contre-proposition Client 2', 'Contre-proposition Client 3']) // Look for active proposals from this chauffeur
          .limit(1)
          .get();

      if (paymentSnapshot.docs.isNotEmpty) {
        final paymentData = paymentSnapshot.docs.first.data();
        paymentDocId = paymentSnapshot.docs.first.id;
        price = (paymentData['price'] as num?)?.toDouble() ?? 0.0;
        currencySymbol = paymentData['currency'] ?? 'TND'; // Default to TND if null
        counterProposalCount = paymentData['counterProposalCount'] ?? 0;
        hasProposal = true;
      } else {
        hasProposal = false;
      }

      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Erreur lors de la récupération des détails: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
          hasProposal = false; // Ensure hasProposal is false on error
          chauffeurName = 'Erreur chargement';
        });
         // Show error message to user
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(
             content: Text('Erreur chargement des détails: ${e.toString()}'),
             backgroundColor: Colors.red.shade700,
             behavior: SnackBarBehavior.floating,
           ),
         );
      }
    }
  }

  Future<void> _updateStatuses(String paymentStatus, String baggageStatus) async {
    if (!mounted) return;
    setState(() => isProcessing = true);
    try {
      if (paymentDocId == null) {
        throw Exception("ID de paiement manquant.");
      }

      final userId = Provider.of<UserProvider>(context, listen: false).userId;
      if (userId == null || userId.isEmpty) {
        throw Exception("User ID from Provider is missing.");
      }

      await FirebaseFirestore.instance
          .collection('payments')
          .doc(paymentDocId!)
          .update({'status': paymentStatus});

      final batch = FirebaseFirestore.instance.batch();
      // Ensure this query correctly identifies the baggage related to THIS proposal/payment
      final baggageQuery = await FirebaseFirestore.instance
          .collection('baggage')
          .where('userId', isEqualTo: userId)
          // It's crucial that baggage documents are linked correctly, either via userId AND trajetId,
          // or potentially directly via the paymentDocId if you store that in baggage.
          .where('trajetId', isEqualTo: widget.trajetId)
          .get();

      if (baggageQuery.docs.isEmpty) {
         log("Avertissement: Aucun document 'baggage' trouvé pour mise à jour (userId: $userId, trajetId: ${widget.trajetId})");
         // Decide how to handle this - maybe the payment update is enough?
      }

      for (var doc in baggageQuery.docs) {
        batch.update(doc.reference, {'status': baggageStatus});
      }
      await batch.commit();

      if (mounted) {
         // Determine navigation target based on status
        Widget destinationScreen;
        if (paymentStatus == 'Acceptée' || paymentStatus == 'Refusée') {
           // Go to Notifications if accepted or refused directly
           destinationScreen = const NotificationScreen();
        } else {
           // For other updates (like counter-proposal), maybe stay or go home?
           // Let's assume Home for now as per the latest request for counter-proposal.
           // If you want Notifications for Accept/Refuse, adjust this logic.
           destinationScreen = const Home(); // Changed for counter-proposal scenario
        }

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => destinationScreen),
        );
        WidgetsBinding.instance.addPostFrameCallback((_) {
           if (mounted) { // Check again in callback
             ScaffoldMessenger.of(context).showSnackBar(
               SnackBar(
                 content: Text('Statut mis à jour: $paymentStatus'),
                 backgroundColor: paymentStatus == 'Acceptée'
                   ? Colors.green.shade700
                   : (paymentStatus == 'Refusée' ? Colors.red.shade700 : Colors.blue), // Adjust color based on status
                 behavior: SnackBarBehavior.floating,
                ),
             );
           }
        });
      }
    } catch (e) {
      debugPrint('Erreur lors de la mise à jour des statuts: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la mise à jour: ${e.toString()}'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isProcessing = false);
      }
    }
  }

  Future<void> _acceptProposal() async {
    await _updateStatuses('Acceptée', 'Accepté'); // Statuses defined in the method
    await _sendNotificationToChauffeurAcc(); // Send notification
  }

  Future<void> _rejectProposal() async {
    await _updateStatuses('Refusée', 'Refusé'); // Statuses defined in the method
    await _sendNotificationToChauffeurRE(); // Send notification
  }


  Future<void> _showCounterProposalPopup(BuildContext context) async {
    if (paymentDocId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Erreur: Impossible d\'identifier la proposition.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red.shade700,
        ),
      );
      return;
    }

    if (counterProposalCount >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Limite de 3 contre-propositions atteinte.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.orange.shade700,
        ),
      );
      return;
    }

    final TextEditingController priceController = TextEditingController();
    final String currentCurrency = currencySymbol; // Should be fetched correctly

    await showDialog(
      context: context,
      barrierDismissible: !isProcessing, // Prevent dismissal while processing
      builder: (BuildContext dialogContext) {
        // Use local state for the dialog's processing indicator
        bool isDialogProcessing = false;
        return StatefulBuilder( // Needed for the dialog's own state
          builder: (context, setDialogState) {
            return AlertDialog(
              // --- Apply target style to AlertDialog ---
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16), // Consistent radius
              ),
              backgroundColor: Colors.white,
              titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              actionsPadding: const EdgeInsets.all(16),
              title: Row(
                children: [
                   Container( // Icon container like in target style
                     padding: const EdgeInsets.all(8),
                     decoration: BoxDecoration(
                       color: Theme.of(context).primaryColor.withOpacity(0.1),
                       borderRadius: BorderRadius.circular(12),
                     ),
                     child: Icon(
                       Icons.price_change_outlined,
                       color: Theme.of(context).primaryColor,
                       size: 24,
                     ),
                   ),
                   const SizedBox(width: 12),
                   Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       const Text(
                         'Contre-proposition',
                         style: TextStyle(
                           fontWeight: FontWeight.bold,
                           fontSize: 18,
                           color: Colors.black87
                         ),
                       ),
                       Text(
                         'Essai ${counterProposalCount + 1} / 3', // Show attempt count
                         style: TextStyle(
                           fontSize: 13,
                           color: _kGreyShade600,
                           fontWeight: FontWeight.w500,
                         ),
                       ),
                     ],
                   ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Section for current price (styled) ---
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _kGreyShade100, // Light grey background
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _kGreyShade200)
                    ),
                    child: Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                           Text(
                             'Prix actuel proposé par $chauffeurName',
                             style: TextStyle(
                               fontSize: 13,
                               color: _kGreyShade600,
                               fontWeight: FontWeight.w500,
                             ),
                           ),
                           const SizedBox(height: 8),
                           Text(
                              '$price $currentCurrency',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87
                              ),
                           ),
                       ]
                    ),
                  ),
                  const SizedBox(height: 20),
                  // --- Section for new price input (styled) ---
                   const Text(
                     'Votre nouvelle proposition',
                     style: TextStyle(
                       fontWeight: FontWeight.w600,
                       fontSize: 15,
                       color: Colors.black87
                     ),
                   ),
                   const SizedBox(height: 12),
                  TextField(
                    controller: priceController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    enabled: !isDialogProcessing, // Use dialog's state
                    decoration: InputDecoration(
                      // Styled Prefix Icon like target
                       prefixIcon: Container(
                         margin: const EdgeInsets.all(8),
                         padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                         decoration: BoxDecoration(
                           color: Colors.orange.shade50, // Match counter button color theme
                           borderRadius: BorderRadius.circular(8),
                         ),
                         child: Text(
                           currentCurrency,
                           style: TextStyle(
                             fontSize: 16,
                             fontWeight: FontWeight.bold,
                             color: Colors.orange.shade800,
                           ),
                         ),
                       ),
                      hintText: 'Entrez votre prix',
                      hintStyle: TextStyle(color: _kGreyShade400),
                      filled: true,
                      fillColor: _kGreyShade50, // Very light fill
                      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                      border: OutlineInputBorder( // Consistent border style
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: _kGreyShade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Theme.of(context).primaryColor, width: 2),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: _kGreyShade300),
                      ),
                       disabledBorder: OutlineInputBorder( // Style for disabled state
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: _kGreyShade200),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                // --- Styled Actions ---
                TextButton(
                  onPressed: isDialogProcessing ? null : () => Navigator.of(dialogContext).pop(),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(
                    'Annuler',
                    style: TextStyle(color: _kGreyShade700, fontWeight: FontWeight.w500),
                  ),
                ),
                ElevatedButton(
                   // Style matching target buttons (Orange theme for counter)
                   style: ElevatedButton.styleFrom(
                     backgroundColor: isDialogProcessing ? Colors.grey : Colors.orange.shade700,
                     foregroundColor: Colors.white,
                     padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                     elevation: 0, // Flatter style
                     shape: RoundedRectangleBorder(
                       borderRadius: BorderRadius.circular(10),
                     ),
                   ),
                   onPressed: isDialogProcessing
                       ? null
                       : () async {
                          final priceText = priceController.text.trim().replaceAll(',', '.'); // Handle comma input
                          if (priceText.isEmpty) {
                            ScaffoldMessenger.of(dialogContext).showSnackBar(
                              SnackBar(
                                content: const Text('Veuillez entrer un prix'),
                                behavior: SnackBarBehavior.floating,
                                backgroundColor: Colors.red.shade700,
                              ),
                            );
                            return;
                          }
                          final double? newPrice = double.tryParse(priceText);
                          if (newPrice == null || newPrice <= 0) {
                             ScaffoldMessenger.of(dialogContext).showSnackBar(
                               SnackBar(
                                 content: const Text('Prix invalide.'),
                                 behavior: SnackBarBehavior.floating,
                                 backgroundColor: Colors.red.shade700,
                               ),
                             );
                            return;
                          }
                          if (newPrice == price) { // Prevent proposing the same price
                             ScaffoldMessenger.of(dialogContext).showSnackBar(
                               SnackBar(
                                 content: const Text('Veuillez proposer un prix différent.'),
                                 behavior: SnackBarBehavior.floating,
                                 backgroundColor: Colors.orange.shade700,
                               ),
                             );
                            return;
                          }


                          // --- Start processing ---
                          setDialogState(() => isDialogProcessing = true);
                          if (mounted) setState(() => isProcessing = true); // Also update screen state

                          try {
                            final userId = Provider.of<UserProvider>(context, listen: false).userId;
                            if (userId == null || userId.isEmpty) {
                              throw Exception("User ID manquant.");
                            }

                            final newCount = counterProposalCount + 1;
                            final newStatus = 'Contre-proposition Client $newCount';

                            // Update Payment Document
                            await FirebaseFirestore.instance
                                .collection('payments')
                                .doc(paymentDocId!)
                                .update({
                                  'price': newPrice,
                                  'status': newStatus,
                                  'counterProposalCount': newCount,
                                  'counterProposalTimestamp': FieldValue.serverTimestamp(),
                                  'counterProposedByUserId': userId, // Track who made the counter
                                });

                            // Update Baggage Documents
                            final batch = FirebaseFirestore.instance.batch();
                            final baggageQuery = await FirebaseFirestore.instance
                                .collection('baggage')
                                .where('userId', isEqualTo: userId)
                                .where('trajetId', isEqualTo: widget.trajetId)
                                .get();

                            for (var doc in baggageQuery.docs) {
                               batch.update(doc.reference, {'status': newStatus});
                            }
                            await batch.commit();

                           Navigator.pushAndRemoveUntil( // Use pushAndRemoveUntil to clear stack
                                context,
                                MaterialPageRoute(builder: (context) => const Home()), // Go to HomePage
                                (Route<dynamic> route) => false, // Remove all previous routes
                              ); // Close dialog

                            // --- Post-update actions ---
                            if (mounted) {
                              await _sendNotificationToChauffeur(); // Notify chauffeur - Call restored function

                              // ***** CHANGE NAVIGATION TARGET HERE *****
                              
                              // ******************************************

                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                 if(mounted) {
                                   ScaffoldMessenger.of(context).showSnackBar(
                                     SnackBar(
                                       content: Text('Contre-proposition $newCount envoyée!'),
                                       backgroundColor: Colors.orange.shade700,
                                       behavior: SnackBarBehavior.floating,
                                     ),
                                   );
                                 }
                              });
                            }

                          } catch (e) {
                            debugPrint('Erreur lors de la contre-proposition: $e');
                            if (mounted) { // Check mount before showing snackbar
                               ScaffoldMessenger.of(context).showSnackBar(
                                 SnackBar(
                                   content: Text('Erreur: ${e.toString()}'),
                                   backgroundColor: Colors.red.shade700,
                                   behavior: SnackBarBehavior.floating,
                                 ),
                               );
                            }
                          } finally {
                            // --- End processing ---
                             // Check mount before setting state
                            if (mounted) setState(() => isProcessing = false);
                            // No need to setDialogState here as the dialog is popped
                          }
                       },
                   child: isDialogProcessing // Show loader inside button
                       ? const SizedBox(
                         height: 20, width: 20,
                         child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                       )
                       : const Text(
                         'Envoyer Proposition',
                         style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                       ),
                 ),
              ],
            );
          },
        );
      },
    );
    // Reset processing state if dialog is dismissed externally while processing (less likely with barrierDismissible=false)
    if (mounted && isProcessing) {
      // setState(() => isProcessing = false); // Might be redundant due to finally block in async operation
    }
  }

  // --- Restored Notification Sending Logic ---

  Future<void> _sendNotificationToChauffeur() async {
    // final BaggageService _baggageService = BaggageService(); // Already defined as class member
    try {
      // Use BaggageService to fetch the token
      final chauffeurFcmToken = await _baggageService.fetchFcmToken(
        widget.chauffeurId,
      );

      if (chauffeurFcmToken != null) {
        log(
          'Sending notification via NotificationApi to token: $chauffeurFcmToken for baggage ',
        );

        // *** CALL NotificationApi.sendNotification ***
        final notificationResult = await NotificationApi.sendNotification(
          // Use the static method
          targetToken: chauffeurFcmToken,
          title: 'Nouvelle négociation de bagages', // Original title
          body:
              'Reçu une négociation:${widget.collectionPoint} → ${widget.deliveryPoint}. ', // Original body
        );

        // Log result from NotificationApi's response map
        if (notificationResult['success'] == true) {
          log(
            'NotificationApi: Sent successfully to chauffeur ${widget.chauffeurId}.',
          );
        } else {
          final errorMessage = notificationResult['message'] ?? 'Unknown error';
          log(
            'NotificationApi: Failed to send notification to chauffeur ${widget.chauffeurId}: $errorMessage',
          );
          // _showSnackBar('Avertissement: Echec envoi notification chauffeur.', Colors.orange); // Optional feedback
        }
      } else {
        log(
          'Could not send notification: Chauffeur FCM token not found via service for ${widget.chauffeurId}.',
        );
        // _showSnackBar('Avertissement: Token chauffeur introuvable.', Colors.orange); // Optional feedback
      }
    } catch (e) {
      log("Error during _sendNotificationToChauffeur phase: $e");
      // _showSnackBar('Erreur envoi notification.', Colors.orange); // Optional feedback
    }
  }

  Future<void> _sendNotificationToChauffeurAcc() async {
    // final BaggageService _baggageService = BaggageService(); // Already defined as class member
    try {
      // Use BaggageService to fetch the token
      final chauffeurFcmToken = await _baggageService.fetchFcmToken(
        widget.chauffeurId,
      );

      if (chauffeurFcmToken != null) {
        log(
          'Sending notification via NotificationApi to token: $chauffeurFcmToken for baggage ',
        );

        // *** CALL NotificationApi.sendNotification ***
        final notificationResult = await NotificationApi.sendNotification(
          // Use the static method
          targetToken: chauffeurFcmToken,
          title: 'Accepter de bagages', // Original title
          body:
              'Reçu une voyage:${widget.collectionPoint} → ${widget.deliveryPoint}. ', // Original body
        );

        // Log result from NotificationApi's response map
        if (notificationResult['success'] == true) {
          log(
            'NotificationApi: Sent successfully to chauffeur ${widget.chauffeurId}.',
          );
        } else {
          final errorMessage = notificationResult['message'] ?? 'Unknown error';
          log(
            'NotificationApi: Failed to send notification to chauffeur ${widget.chauffeurId}: $errorMessage',
          );
          // _showSnackBar('Avertissement: Echec envoi notification chauffeur.', Colors.orange); // Optional feedback
        }
      } else {
        log(
          'Could not send notification: Chauffeur FCM token not found via service for ${widget.chauffeurId}.',
        );
        // _showSnackBar('Avertissement: Token chauffeur introuvable.', Colors.orange); // Optional feedback
      }
    } catch (e) {
      log("Error during _sendNotificationToChauffeur phase: $e");
      // _showSnackBar('Erreur envoi notification.', Colors.orange); // Optional feedback
    }
  }

  Future<void> _sendNotificationToChauffeurRE() async {
    // final BaggageService _baggageService = BaggageService(); // Already defined as class member
    try {
      // Use BaggageService to fetch the token
      final chauffeurFcmToken = await _baggageService.fetchFcmToken(
        widget.chauffeurId,
      );

      if (chauffeurFcmToken != null) {
        log(
          'Sending notification via NotificationApi to token: $chauffeurFcmToken for baggage ',
        );

        // *** CALL NotificationApi.sendNotification ***
        final notificationResult = await NotificationApi.sendNotification(
          // Use the static method
          targetToken: chauffeurFcmToken,
          title: 'Refusée de bagages', // Original title
          body:
              'Reçu une voyage:${widget.collectionPoint} → ${widget.deliveryPoint}. ', // Original body
        );

        // Log result from NotificationApi's response map
        if (notificationResult['success'] == true) {
          log(
            'NotificationApi: Sent successfully to chauffeur ${widget.chauffeurId}.',
          );
        } else {
          final errorMessage = notificationResult['message'] ?? 'Unknown error';
          log(
            'NotificationApi: Failed to send notification to chauffeur ${widget.chauffeurId}: $errorMessage',
          );
          // _showSnackBar('Avertissement: Echec envoi notification chauffeur.', Colors.orange); // Optional feedback
        }
      } else {
        log(
          'Could not send notification: Chauffeur FCM token not found via service for ${widget.chauffeurId}.',
        );
        // _showSnackBar('Avertissement: Token chauffeur introuvable.', Colors.orange); // Optional feedback
      }
    } catch (e) {
      log("Error during _sendNotificationToChauffeur phase: $e");
      // _showSnackBar('Erreur envoi notification.', Colors.orange); // Optional feedback
    }
  }

  // --- Build Method (Applying new style - unchanged from previous styled version) ---
  @override
  Widget build(BuildContext context) {
    final userId = Provider.of<UserProvider>(context, listen: false).userId ?? 'ID Utilisateur Inconnu';

    return Scaffold(
      // --- Apply target Scaffold style ---
      backgroundColor: _kGreyShade50,
      appBar: AppBar(
         // --- Apply target AppBar style ---
         title: const Text(
           'Proposition de Transport', // More descriptive title
           style: TextStyle(
             fontWeight: FontWeight.w600,
             color: Colors.black87,
             fontSize: 20,
           ),
         ),
         backgroundColor: Colors.white, // White background
         elevation: 0.5, // Subtle elevation like TitleApp might have
         centerTitle: true,
         leading: IconButton(
           icon: const Icon(Icons.arrow_back, color: Colors.black),
           onPressed: isProcessing ? null : () => Navigator.pop(context),
         ),
      ),
      body: isLoading
          ? Center( // Consistent loading indicator
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text('Chargement des détails...', style: TextStyle(color: _kGreyShade700)),
                ],
              ),
            )
          : !hasProposal
              ? Center( // Consistent empty state
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                         Container( // Styled icon container
                           padding: const EdgeInsets.all(24),
                           decoration: BoxDecoration(
                             color: Colors.blue.shade50,
                             shape: BoxShape.circle
                           ),
                           child: Icon(
                             Icons.info_outline,
                             size: 48, // Slightly smaller icon
                             color: Colors.blue.shade400,
                           ),
                         ),
                         const SizedBox(height: 24),
                         Text(
                           'Aucune Proposition Active',
                           textAlign: TextAlign.center,
                           style: TextStyle(
                             fontSize: 20,
                             fontWeight: FontWeight.w600,
                             color: _kGreyShade700,
                           ),
                         ),
                         const SizedBox(height: 12),
                         Text(
                           'Aucune proposition de transport n\'est actuellement en attente pour ce trajet de la part de ce chauffeur.',
                           textAlign: TextAlign.center,
                           style: TextStyle(fontSize: 15, color: _kGreyShade600),
                         ),
                          const SizedBox(height: 20),
                           Container( // Optional: Display User ID subtly
                             padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                             decoration: BoxDecoration(
                               color: _kGreyShade200,
                               borderRadius: BorderRadius.circular(12),
                             ),
                             child: Text(
                               'ID Utilisateur: $userId',
                               style: TextStyle(fontSize: 11, color: _kGreyShade700),
                             ),
                           ),
                      ],
                    ),
                  ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1),
                )
              : SingleChildScrollView(
                  // Add padding similar to ModernBaggageScreen's ListView
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch, // Stretch buttons
                    children: [
                      // No need for _buildHeaderSection, AppBar serves that purpose
                      _buildTrajetCard(), // Apply new style
                      const SizedBox(height: 20), // Consistent spacing
                      _buildProposalCard(), // Apply new style
                      const SizedBox(height: 28),
                      _buildActionButtons(), // Apply new style
                      const SizedBox(height: 20), // Footer padding
                    ],
                  ),
                ),
    );
  }


  // --- Helper Widgets (Refactored with new style - unchanged from previous styled version) ---

  // Helper to build styled info rows consistently
  Widget _buildInfoRow(IconData icon, String label, String value, Color iconColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container( // Styled icon container
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: iconColor),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 13, color: _kGreyShade600, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 5),
              Text(
                value,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Card for Trajet Details (Styled like BaggageItemCard)
  Widget _buildTrajetCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 0), // Use SizedBox spacing instead
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _kBlackOpacity05, blurRadius: 10, offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card Header (Optional, can be simpler)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                 children: [
                   Icon(Icons.map_outlined, color: Colors.indigo.shade700, size: 22),
                   const SizedBox(width: 10),
                    const Text(
                      'Détails du Trajet',
                      style: TextStyle(
                        fontSize: 17, fontWeight: FontWeight.bold, color: Colors.black87,
                      ),
                    ),
                 ]
              ),
            ),
            const Divider(height: 1, thickness: 1, indent: 16, endIndent: 16),
            // Card Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildInfoRow(Icons.calendar_today_outlined, 'Date', widget.date, Colors.blue.shade700),
                  const SizedBox(height: 16), // Spacing between rows
                  _buildInfoRow(Icons.location_on_outlined, 'Point de collecte', widget.collectionPoint, Colors.green.shade700),
                   const SizedBox(height: 16),
                  _buildInfoRow(Icons.flag_outlined, 'Point de livraison', widget.deliveryPoint, Colors.red.shade700), // Changed icon
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05); // Keep animation
  }

  // Card for Proposal Details (Styled like BaggageItemCard)
  Widget _buildProposalCard() {
    return Container(
       margin: const EdgeInsets.only(bottom: 0),
       decoration: BoxDecoration(
         color: Colors.white,
         borderRadius: BorderRadius.circular(16),
         boxShadow: [
           BoxShadow(color: _kBlackOpacity05, blurRadius: 10, offset: const Offset(0, 2)),
         ],
       ),
       child: ClipRRect(
         borderRadius: BorderRadius.circular(16),
         child: Column(
           crossAxisAlignment: CrossAxisAlignment.start,
           children: [
             Padding(
               padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
               child: Row(
                 children: [
                    Icon(Icons.local_offer_outlined, color: Colors.orange.shade800, size: 22), // Changed Icon
                   const SizedBox(width: 10),
                    const Text(
                     'Proposition du Chauffeur',
                     style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.black87),
                   ),
                 ]
               ),
             ),
              const Divider(height: 1, thickness: 1, indent: 16, endIndent: 16),
             Padding(
               padding: const EdgeInsets.all(16),
               child: Column(
                 children: [
                   _buildInfoRow(Icons.person_outline, 'Chauffeur', chauffeurName, Colors.purple.shade700),
                   const SizedBox(height: 16),
                   _buildInfoRow(Icons.attach_money, 'Prix proposé', '$price $currencySymbol', Colors.amber.shade700), // Combine price/currency

                   // Display Counter Proposal Info (if any) - Styled
                   if (counterProposalCount > 0) ...[
                     const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: _kGreyShade100,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: _kGreyShade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, size: 18, color: Colors.blue.shade700),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Vous avez fait $counterProposalCount contre-proposition${counterProposalCount > 1 ? 's' : ''}.',
                                style: TextStyle(fontSize: 13, color: _kGreyShade700),
                              ),
                            ),
                          ],
                        ),
                      ),
                   ],
                 ],
               ),
             ),
           ],
         ),
       ),
    ).animate().fadeIn(duration: 500.ms, delay: 50.ms).slideY(begin: 0.05); // Keep animation
  }


  // Action Buttons (Styled like target - unchanged from previous styled version)
  Widget _buildActionButtons() {
     final bool canCounterPropose = counterProposalCount < 3;
     return Column(
       crossAxisAlignment: CrossAxisAlignment.stretch, // Make buttons full width
       children: [
         Row(
           children: [
             Expanded(
               child: ElevatedButton.icon(
                 icon: const Icon(Icons.check_circle_outline, size: 20),
                 label: const Text('Accepter'),
                 onPressed: isProcessing ? null : _acceptProposal,
                 // --- Apply target style (Green theme) ---
                 style: ElevatedButton.styleFrom(
                   backgroundColor: isProcessing ? Colors.grey : Colors.green.shade600,
                   foregroundColor: Colors.white,
                   padding: const EdgeInsets.symmetric(vertical: 14),
                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                   textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                   elevation: 1, // Subtle elevation
                 ),
               ),
             ),
             const SizedBox(width: 12), // Spacing between buttons
             Expanded(
               child: ElevatedButton.icon(
                 icon: const Icon(Icons.cancel_outlined, size: 20),
                 label: const Text('Refuser'),
                 onPressed: isProcessing ? null : _rejectProposal,
                  // --- Apply target style (Red theme) ---
                 style: ElevatedButton.styleFrom(
                   backgroundColor: isProcessing ? Colors.grey : Colors.red.shade600,
                   foregroundColor: Colors.white,
                   padding: const EdgeInsets.symmetric(vertical: 14),
                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                   textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                   elevation: 1,
                 ),
               ),
             ),
           ],
         ),
         const SizedBox(height: 12), // Spacing below row
         ElevatedButton.icon(
            icon: const Icon(Icons.price_change_outlined, size: 20),
            label: Text(
              canCounterPropose
                 ? 'Contre-proposition (${counterProposalCount + 1}/3)'
                 : 'Limite Atteinte (3/3)',
            ),
            onPressed: isProcessing || !canCounterPropose
                ? null
                : () => _showCounterProposalPopup(context),
            // --- Apply target style (Orange theme / Grey disabled) ---
            style: ElevatedButton.styleFrom(
              backgroundColor: isProcessing || !canCounterPropose
                  ? Colors.grey.shade400 // Disabled color
                  : Colors.orange.shade700, // Active color
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              elevation: 1,
            ),
          ),
       ],
     ).animate().fadeIn(duration: 600.ms, delay: 100.ms).slideY(begin: 0.05); // Keep animation
  }
}