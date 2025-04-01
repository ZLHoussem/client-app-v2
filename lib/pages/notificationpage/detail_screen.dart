import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:bladi_go_client/widget/title.dart';

class ChauffeurDetailScreen extends StatefulWidget {
  final Map<String, dynamic> baggageItem;

  const ChauffeurDetailScreen({super.key, required this.baggageItem});

  @override
  State<ChauffeurDetailScreen> createState() => _ChauffeurDetailScreenState();
}

class _ChauffeurDetailScreenState extends State<ChauffeurDetailScreen> {

  String? _selectedCollectionPoint;
  String? _selectedDeliveryPoint;
  Map<String, dynamic>? _chauffeurData;
  bool _isLoading = true;
  String trajetDate = 'N/A';
  String trajetStyle = 'N/A';
  late final List<String> _collectionPoints;
  late final List<String> _deliveryPoints;

  @override
  void initState() {
    super.initState();
    _initializeData();
    _fetchChauffeurData();
    _loadTrajetDate();
  }

  void _initializeData() {
  


    // Now that _availableDates is initialized, we can set _selectedDate
  
    // Initialize collection and delivery points
    _collectionPoints = [
      widget.baggageItem['collectionPoint'] as String? ?? 'N/A',
    ];
    _deliveryPoints = [
      widget.baggageItem['deliveryPoint'] as String? ?? 'N/A',
    ];

    // Set selected points
    _selectedCollectionPoint = _collectionPoints.first;
    _selectedDeliveryPoint = _deliveryPoints.first;
  }

  Future<void> _fetchChauffeurData() async {
    try {
      final chauffeurId = widget.baggageItem['chauffeurId'] as String?;
      if (chauffeurId == null) {
        throw const FormatException('No chauffeur ID provided');
      }

      final doc = await FirebaseFirestore.instance
          .collection('chauffeurs')
          .doc(chauffeurId)
          .get();

      setState(() {
        _chauffeurData = doc.exists
            ? doc.data()
            : throw const FormatException('Chauffeur not found');
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching chauffeur data: $e');
      setState(() {
        _chauffeurData = {};
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du chargement: $e')),
        );
      }
    }
  }
Future<void> _loadTrajetDate() async {
  try {
    final trajetId = widget.baggageItem['trajetId'] ?? 'N/A';
    final trajetData = await _fetchTrajetData(trajetId);
    setState(() {
      trajetDate = trajetData['date'] ?? 'N/A';
      // Add a new variable for style
      trajetStyle = trajetData['style'] ?? 'N/A';
    });
  } catch (e) {
    print('Error loading trajet data: $e');
    setState(() {
      trajetDate = 'N/A';
      trajetStyle = 'N/A';
    });
  }
} 
Future<Map<String, String?>> _fetchTrajetData(String trajetId) async {
  if (trajetId == 'N/A' || trajetId.isEmpty) {
    return {'date': 'N/A', 'style': 'N/A'};
  }

  try {
    final doc = await FirebaseFirestore.instance
        .collection('trajets')
        .doc(trajetId)
        .get();

    if (doc.exists) {
      final data = doc.data();
      if (data != null) {
        // Fetch date
        String? dateString = data['date'] as String?;
        if (dateString != null) {
          final dateParts = dateString.split('/');
          if (dateParts.length == 3) {
            final year = dateParts[0];
            final month = dateParts[1];
            final day = dateParts[2];
            dateString = '$day/$month/$year';
          }
        } else {
          dateString = 'N/A';
        }

        // Fetch style (assuming it's stored as 'style' or 'type' in Firestore)
        String? style = data['style'] as String? ?? data['type'] as String? ?? 'N/A';

        return {'date': dateString, 'style': style};
      }
    }
    return {'date': 'N/A', 'style': 'N/A'};
  } catch (e) {
    print('Error in _fetchTrajetData: $e');
    return {'date': 'N/A', 'style': 'N/A'};
  }
}
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final chauffeurData = _chauffeurData ?? widget.baggageItem;

    return Scaffold(
      appBar: const TitleApp(text: "Détails du Chauffeur", retour: true),
      backgroundColor: Colors.white,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SizedBox(
              height: screenHeight,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Nom de chauffeur:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '${chauffeurData['name'] ?? 'Nom de chauffeur'} ${chauffeurData['lastname'] ?? ''}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildVehicleImage(screenWidth, chauffeurData),
                    const SizedBox(height: 20),
                    _buildLocationBox(screenWidth),
                    const SizedBox(height: 20),
                    _buildCalendarBox(screenWidth),
                    const SizedBox(height: 10),
                    Center(
                      child: _buildRetourButton(screenWidth),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
Widget _buildVehicleImage(double screenWidth, Map<String, dynamic> data) =>
    ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        width: screenWidth * 0.9,
        height: 160,
        child: Image.network(
          data['vehicleImageUrl']?.isNotEmpty == true
              ? data['vehicleImageUrl']
              : '',
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (_, __, ___) => Image.asset(
            'assets/vehicle_image.jpg',
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
Widget _buildCalendarBox(double screenWidth) {
  final data = _chauffeurData ?? widget.baggageItem;

  return Container(
    width: screenWidth * 0.90,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      border: Border.all(color: Colors.green, width: 2),
      borderRadius: BorderRadius.circular(15),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Display the trajetDate
        Row(
          children: [
            const Text(
              'Date de transport: ',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.green,
              ),
            ),
            const SizedBox(width: 2),
            Text(
              trajetDate,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Display the trajetStyle with conditional icon
        Row(
          children: [
            const Text(
              'Type de transport: ',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.green,
              ),
            ),
            const SizedBox(width: 2),
            // Add icon based on trajetStyle
            if (trajetStyle.toLowerCase() == 'bateau')
              const Icon(
                Icons.directions_boat,
                color: Colors.green,
                size: 24,
              )
            else if (trajetStyle.toLowerCase() == 'avion')
              const Icon(
                Icons.airplanemode_active,
                color: Colors.green,
                size: 24,
              )
            else
              const SizedBox(width: 24), // Placeholder for no icon
            const SizedBox(width: 8),
            Text(
              trajetStyle,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Chauffeur Details
        const Text(
          'Détails du Chauffeur',
          style: TextStyle(
            color: Colors.green,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 8),
        _buildDetailRow('Nom', '${data['name'] ?? 'N/A'} ${data['lastname'] ?? ''}'),
        _buildDetailRow('Email', data['email'] ?? 'N/A'),
        _buildDetailRow('Téléphone', data['phone'] ?? 'N/A'),
        _buildDetailRow('Véhicule', data['vehicle'] ?? 'N/A'),
        _buildDetailRow('Couleur', data['vehicleColor'] ?? 'N/A'),
      ],
    ),
  );
}

Widget _buildDetailRow(String label, String value) => Padding(
  padding: const EdgeInsets.symmetric(vertical: 4),
  child: Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        '$label: ',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      Expanded(
        child: Text(
          value,
          style: const TextStyle(fontSize: 14),
        ),
      ),
    ],
  ),
);

  Widget _buildLocationBox(double screenWidth) => Container(
        width: screenWidth * 0.9,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.green, width: 2),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildLocationColumn(
              'point de ramassage',
              _selectedCollectionPoint ?? 'N/A',
            ),
            _buildLocationColumn(
              'point de livraison',
              _selectedDeliveryPoint ??  'N/A',
            ),
          ],
        ),
      );

  Widget _buildLocationColumn(String title, String location) => Expanded(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 8),
            Text(location, style: const TextStyle(fontSize: 14)),
          ],
        ),
      );


  Widget _buildRetourButton(double screenWidth) => ElevatedButton(
        onPressed: () => Navigator.pop(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          minimumSize: Size(screenWidth * 0.5, 50),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        ),
        child: const Text(
          'Retour',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
        ),
      );
}