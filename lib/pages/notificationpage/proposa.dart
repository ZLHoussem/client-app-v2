import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:bladi_go_client/pages/notification.dart';


class ChauffeurProposalScreen extends StatefulWidget {
  final String trajetId;
  final String chauffeurId;
  final String? userId;
  final String date;
  final String collectionPoint;
  final String deliveryPoint;

  const ChauffeurProposalScreen({
    super.key,
    required this.trajetId,
    required this.chauffeurId,
    required this.userId,
    required this.date,
    required this.collectionPoint,
    required this.deliveryPoint,
  });

  @override
  State<ChauffeurProposalScreen> createState() => _ChauffeurProposalScreenState();
}

class _ChauffeurProposalScreenState extends State<ChauffeurProposalScreen> {
  String chauffeurName = 'Chargement...';
  double price = 0.0;
  bool isLoading = true;
  bool hasProposal = false;

  @override
  void initState() {
    super.initState();
    _fetchProposalDetails();
  }

  Future<void> _fetchProposalDetails() async {
    try {
      // Fetch chauffeur name
      final chauffeurDoc = await FirebaseFirestore.instance
          .collection('chauffeurs')
          .doc(widget.chauffeurId)
          .get();
      if (chauffeurDoc.exists) {
        final data = chauffeurDoc.data()!;
        final name = data['name'] ?? 'Inconnu';
        final lastName = data['lastName'] ?? '';
        chauffeurName = '$name $lastName'.trim();
      } else {
        chauffeurName = 'Chauffeur non attribué';
      }

      // Fetch the latest payment proposal for this trajet
      final paymentSnapshot = await FirebaseFirestore.instance
          .collection('payments')
          .where('chauffeurName', isEqualTo: chauffeurName)
         
        
      .limit(1)
          .get();

      if (paymentSnapshot.docs.isNotEmpty) {
        final paymentData = paymentSnapshot.docs.first.data();
        price = (paymentData['price'] as num?)?.toDouble() ?? 0.0;
        hasProposal = true;
      } else {
        hasProposal = false;
      }

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Erreur lors de la récupération des détails: $e');
      setState(() {
        isLoading = false;
        hasProposal = false;
      });
    }
  }

  Future<void> _acceptProposal() async {
    try {
      // Update the baggage status to "Payé"
      await FirebaseFirestore.instance
          .collection('baggage')
          .where('trajetId', isEqualTo: widget.trajetId)
          .get()
          .then((snapshot) {
        for (var doc in snapshot.docs) {
          doc.reference.update({'status': 'En accepter'});
        }
      });

      // Update the payment status to "Payé"
      await FirebaseFirestore.instance
          .collection('payments')
          .where('chauffeurName', isEqualTo: chauffeurName)

          .get()
          .then((snapshot) {
        if (snapshot.docs.isNotEmpty) {
          snapshot.docs.first.reference.update({'status': 'En cour'});
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Proposition acceptée avec succès')),
      );

        Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => NotificationScreen(),
        ),
      );// Return to NotificationScreen
    } catch (e) {
      debugPrint('Erreur lors de l\'acceptation: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }

  Future<void> _rejectProposal() async {
    try {
      // Update the baggage status to "En attente" or another status as needed
      await FirebaseFirestore.instance
          .collection('baggage')
          .where('trajetId', isEqualTo: widget.trajetId)
          .get()
          .then((snapshot) {
        for (var doc in snapshot.docs) {
          doc.reference.update({'status': 'En refuser'});
        }
      });

      // Optionally, delete the payment proposal or mark it as rejected
     await FirebaseFirestore.instance
          .collection('payments')
          .where('chauffeurName', isEqualTo: chauffeurName)

          .get()
          .then((snapshot) {
        if (snapshot.docs.isNotEmpty) {
          snapshot.docs.first.reference.delete();
        }
      });


      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Proposition refusée')),
      );
                        Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => NotificationScreen(),
                  ),
                );// Return to NotificationScreen
    } catch (e) {
      debugPrint('Erreur lors du refus: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Proposition de Chauffeur',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.black87,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : !hasProposal
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 80,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Aucune proposition disponible',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Trajet Details Card
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                            gradient: LinearGradient(
                              colors: [Colors.white, Colors.grey.shade50],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Détails du Trajet',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today_outlined,
                                    size: 18,
                                    color: Colors.blueGrey.shade700,
                                  ),
                                  const SizedBox(width: 8),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Date', style: _labelStyle()),
                                      const SizedBox(height: 4),
                                      Text(
                                        widget.date,
                                        style: _valueStyle(),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Icon(
                                    Icons.location_on_outlined,
                                    size: 18,
                                    color: Colors.blueGrey.shade700,
                                  ),
                                  const SizedBox(width: 8),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Point de collecte', style: _labelStyle()),
                                      const SizedBox(height: 4),
                                      Text(
                                        widget.collectionPoint,
                                        style: _valueStyle(),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Icon(
                                    Icons.location_on,
                                    size: 18,
                                    color: Colors.blueGrey.shade700,
                                  ),
                                  const SizedBox(width: 8),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Point de livraison', style: _labelStyle()),
                                      const SizedBox(height: 4),
                                      Text(
                                        widget.deliveryPoint,
                                        style: _valueStyle(),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1),

                      const SizedBox(height: 16),

                      // Proposal Details Card
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                            gradient: LinearGradient(
                              colors: [Colors.white, Colors.grey.shade50],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Détails de la Proposition',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Icon(
                                    Icons.person_outline,
                                    size: 18,
                                    color: Colors.blueGrey.shade700,
                                  ),
                                  const SizedBox(width: 8),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Chauffeur', style: _labelStyle()),
                                      const SizedBox(height: 4),
                                      Text(
                                        chauffeurName,
                                        style: _valueStyle(),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Icon(
                                    Icons.attach_money,
                                    size: 18,
                                    color: Colors.blueGrey.shade700,
                                  ),
                                  const SizedBox(width: 8),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Prix proposé', style: _labelStyle()),
                                      const SizedBox(height: 4),
                                      Text(
                                        '$price TND',
                                        style: _valueStyle(),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1),

                      const SizedBox(height: 24),

                      // Accept and Reject Buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _acceptProposal,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: const Text(
                                'Accepter',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _rejectProposal,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: const Text(
                                'Refuser',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1),
                    ],
                  ),
                ),
    );
  }

  TextStyle _labelStyle() => TextStyle(
        fontSize: 12,
        color: Colors.grey.shade600,
        fontWeight: FontWeight.w500,
      );

  TextStyle _valueStyle() => const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      );
}