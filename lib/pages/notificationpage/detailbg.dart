import 'package:bladi_go_client/provider/user.dart';
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bladi_go_client/pages/notificationpage/detail_screen.dart';
import 'package:bladi_go_client/widget/title.dart';
import 'package:bladi_go_client/pages/notificationpage/proposa.dart'; 
// Import the modification screen (adjust the path as needed)
import 'package:bladi_go_client/pages/baggage_screen.dart' as ModifyScreen;
import 'package:provider/provider.dart'; 

class ModernBaggageScreen extends StatefulWidget {
  final String? userId;
  final String selectedDate;
  final String collectionPoint;
  final String deliveryPoint;

  const ModernBaggageScreen({
    super.key,
    required this.userId,
    required this.selectedDate,
    required this.collectionPoint,
    required this.deliveryPoint,
  });

  @override
  State<ModernBaggageScreen> createState() => _ModernBaggageScreenState();
}

class _ModernBaggageScreenState extends State<ModernBaggageScreen> {
  List<Map<String, dynamic>> baggageItems = [];

  @override
  void initState() {
    super.initState();
    _fetchBaggageItems();
  }

  Future<String> _fetchChauffeurName(String chauffeurId) async {
    try {
      final chauffeurDoc = await FirebaseFirestore.instance
          .collection('chauffeurs')
          .doc(chauffeurId)
          .get();
      if (chauffeurDoc.exists) {
        final data = chauffeurDoc.data()!;
        final name = data['name'] ?? 'Inconnu';
        final lastName = data['lastName'] ?? '';
        return '$name $lastName'.trim();
      }
      return 'Chauffeur non attribué';
    } catch (e) {
      debugPrint('Erreur lors de la récupération du chauffeur: $e');
      return 'Chauffeur non attribué';
    }
  }

  Future<Map<String, dynamic>> _fetchTrajetDetails(String trajetId) async {
    try {
      final trajetDoc = await FirebaseFirestore.instance
          .collection('trajets')
          .doc(trajetId)
          .get();
      if (trajetDoc.exists) {
        final data = trajetDoc.data()!;
        final value = data['value']?.split(' → ') ?? ['N/A', 'N/A'];
        return {
          'collectionPoint': value[0],
          'deliveryPoint': value[1],
          'date': data['date'] ?? 'N/A',
          'transportType': data['style'] ?? 'N/A', // Assuming style field exists
        };
      }
      return {
        'collectionPoint': 'N/A',
        'deliveryPoint': 'N/A',
        'date': 'N/A',
        'transportType': 'N/A',
      };
    } catch (e) {
      debugPrint('Erreur lors de la récupération du trajet: $e');
      return {
        'collectionPoint': 'N/A',
        'deliveryPoint': 'N/A',
        'date': 'N/A',
        'transportType': 'N/A',
      };
    }
  }

  Future<void> _fetchBaggageItems() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('baggage')
        .where('userId', isEqualTo: widget.userId)
        .get();

    final List<Map<String, dynamic>> newBaggageItems = [];

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final items = data['items'] as List<dynamic>;
      final status = data['status'] ?? 'Statut inconnu';
      final trajetId = data['trajetId'] as String?;
      final chauffeurId = data['chauffeurId'] as String?;
      final docId = doc.id; // Store document ID for modification

      if (trajetId == null || chauffeurId == null) {
        debugPrint('Document sans trajetId ou chauffeurId: ${doc.id}');
        continue;
      }

      final results = await Future.wait([
        _fetchTrajetDetails(trajetId),
        _fetchChauffeurName(chauffeurId),
      ]);

      final trajetDetails = results[0] as Map<String, dynamic>;
      final chauffeurName = results[1] as String;

      if (trajetDetails['date'] == widget.selectedDate &&
          trajetDetails['collectionPoint'] == widget.collectionPoint &&
          trajetDetails['deliveryPoint'] == widget.deliveryPoint) {
        Color statusColor;
        switch (status) {
          case 'En attente':
            statusColor = Colors.orange;
            break;
          case 'En proposition':
            statusColor = Colors.blue;
            break;
          case 'En accepter':
            statusColor = Colors.green;
            break;
          case 'Confirmé':
            statusColor = Colors.green;
            break;
          case 'Payé':
            statusColor = Colors.blue;
            break;
          default:
            statusColor = const Color.fromARGB(255, 165, 165, 165);
        }

        for (var item in items) {
          final itemData = item as Map<String, dynamic>;
          newBaggageItems.add({
            'title': itemData['baggageNumber'] ?? 'Bagage #${doc.id}',
            'images': List<String>.from(itemData['imageUrls'] ?? []),
            'description': itemData['description'] ?? 'Sans description',
            'chauffeurName': chauffeurName,
            'status': status,
            'statusColor': '#${statusColor.value.toRadixString(16).padLeft(8, '0').substring(2)}',
            'chauffeurId': chauffeurId,
            'trajetId': trajetId,
            'date': trajetDetails['date'],
            'collectionPoint': trajetDetails['collectionPoint'],
            'deliveryPoint': trajetDetails['deliveryPoint'],
            'transportType': trajetDetails['transportType'],
            'baggageId': docId, // Add baggageId for modification
          });
        }
      }
    }

    setState(() {
      baggageItems = newBaggageItems;
    });
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: const TitleApp(text: "Vos bagages", retour: true),
      body: Column(
        children: [
          // Status banner for "En proposition"
          if (baggageItems.any((item) => item['status'] == 'En proposition'))
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              color: Colors.blue.withOpacity(0.1),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'En proposition',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue,
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      final proposalItem = baggageItems.firstWhere((item) => item['status'] == 'En proposition');
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChauffeurProposalScreen(
                            chauffeurId: proposalItem['chauffeurId'],
                            userId: userProvider.userId,
                            trajetId: proposalItem['trajetId'],
                            collectionPoint: proposalItem['collectionPoint'],
                            deliveryPoint: proposalItem['deliveryPoint'],
                            date: proposalItem['date'],
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Voir la proposition',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          // Status banner for "En attente" with Modifier button
          if (baggageItems.any((item) => item['status'] == 'En attente'))
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              color: Colors.orange.withOpacity(0.1),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'En attente',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.orange,
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      final waitingItem = baggageItems.firstWhere((item) => item['status'] == 'En attente');
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ModifyScreen.ModernBaggageScreen(
                            locations: '${waitingItem['collectionPoint']} → ${waitingItem['deliveryPoint']}',
                            travelDate: waitingItem['date'],
                            transportType: waitingItem['transportType'],
                            chauffeurId: waitingItem['chauffeurId'],
                            trajetId: waitingItem['trajetId'],
                            baggageId: waitingItem['baggageId'], // Pass baggageId for editing
                          ),
                        ),
                      );
                      _fetchBaggageItems(); // Refresh data after modification
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Modifier',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          // Status banner for "En accepter"
          if (baggageItems.any((item) => item['status'] == 'En accepter'))
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              color: Colors.green.withOpacity(0.1),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'En accepter',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.green,
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      final acceptedItem = baggageItems.firstWhere((item) => item['status'] == 'En accepter');
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChauffeurDetailScreen(
                            baggageItem: acceptedItem,
                          ),
                        ),
                      );
                      _fetchBaggageItems(); // Refresh data on return
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Voir les détails',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          // Main content
          Expanded(
            child: FutureBuilder<bool>(
              future: Future.delayed(const Duration(seconds: 30), () => true),
              builder: (context, snapshot) {
                if (baggageItems.isEmpty) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  return const Center(child: Text('Aucun bagage trouvé pour ces critères'));
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  itemCount: baggageItems.length,
                  itemBuilder: (context, index) {
                    final baggage = baggageItems[index];
                    final images = baggage['images'] as List<String>;
                    return BaggageCard(baggage: baggage, images: images);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// BaggageCard class remains unchanged
class BaggageCard extends StatefulWidget {
  final Map<String, dynamic> baggage;
  final List<String> images;

  const BaggageCard({super.key, required this.baggage, required this.images});

  @override
  State<BaggageCard> createState() => _BaggageCardState();
}

class _BaggageCardState extends State<BaggageCard> {
  final CarouselController carouselController = CarouselController();
  int currentImageIndex = 0;

  @override
  Widget build(BuildContext context) {
    final Color blackWithOpacity = Colors.black.withAlpha((0.8 * 255).toInt());


    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.05 * 255).toInt()),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, 2),
          ),
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.baggage['title'],
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                      color: blackWithOpacity,
                    ),
                  ),
                ],
              ),
            ),
            Stack(
              alignment: Alignment.center,
              children: [
                CarouselSlider(
                  options: CarouselOptions(
                    height: 220,
                    enlargeCenterPage: true,
                    enableInfiniteScroll: widget.images.length > 1,
                    viewportFraction: 1.0,
                    onPageChanged: (index, reason) {
                      setState(() {
                        currentImageIndex = index;
                      });
                    },
                  ),
                  items: widget.images.isNotEmpty
                      ? widget.images.map((imageUrl) {
                          return Builder(
                            builder: (BuildContext context) {
                              return Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                ),
                                child: Image.network(
                                  imageUrl,
                                  fit: BoxFit.cover,
                                  loadingBuilder: (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return const Center(child: CircularProgressIndicator());
                                  },
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      color: Colors.grey.shade200,
                                      child: Center(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.image_not_supported_outlined,
                                              color: Colors.grey.shade400,
                                              size: 40,
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              'Image non disponible',
                                              style: TextStyle(
                                                color: Colors.grey.shade700,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              );
                            },
                          );
                        }).toList()
                      : [
                          Container(
                            width: double.infinity,
                            height: 220,
                            color: Colors.grey.shade200,
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.image_not_supported_outlined,
                                    color: Colors.grey.shade400,
                                    size: 40,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Aucune image disponible',
                                    style: TextStyle(
                                      color: Colors.grey.shade700,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                ),
                if (widget.images.length > 1) ...[
                  Positioned(
                    bottom: 10,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: widget.images.asMap().entries.map((entry) {
                        return Container(
                          width: 8.0,
                          height: 8.0,
                          margin: const EdgeInsets.symmetric(horizontal: 3.0),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: currentImageIndex == entry.key
                                ? Colors.white
                                : Colors.white.withOpacity(0.5),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Description',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Text(
                      widget.baggage['description'],
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.black.withAlpha((0.7 * 255).toInt()),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}