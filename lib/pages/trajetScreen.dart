import 'package:bladi_go_client/models/trajet_models.dart';
import 'package:bladi_go_client/pages/baggage_screen.dart';
import 'package:bladi_go_client/service/trajet_service.dart';
import 'package:bladi_go_client/widget/title.dart';
import 'package:bladi_go_client/widget/trajet_card.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For date formatting

class TrajetScreen extends StatefulWidget {
  final String from;
  final String to;
  final String date; // Expecting "YYYY/MM/DD"
  final String transportType;

  const TrajetScreen({
    super.key,
    required this.from,
    required this.to,
    required this.date,
    required this.transportType,
  });

  @override
  State<TrajetScreen> createState() => _TrajetScreenState();
}

class _TrajetScreenState extends State<TrajetScreen> {
  // Instantiate the service
  final TrajetService _trajetService = TrajetService();
  late Future<List<TrajetDisplayData>> _trajetsFuture;

  // Store the target date for comparison
  DateTime? _targetDate;

  @override
  void initState() {
    super.initState();
    _parseTargetDate();
    _loadTrajets();
  }

  void _parseTargetDate() {
     try {
       _targetDate = DateFormat('yyyy/MM/dd').parse(widget.date);
     } catch (e) {
       debugPrint("Error parsing initial date ${widget.date}: $e");
       _targetDate = null; // Handle cases where initial date might be invalid
     }
  }

  void _loadTrajets() {
    // Call the service method
    _trajetsFuture = _trajetService.getTrajets(
      from: widget.from,
      to: widget.to,
      dateString: widget.date,
      transportType: widget.transportType,
    );
  }

  void _retryLoadTrajets() {
    setState(() {
      _loadTrajets(); // Re-assign the future to trigger FutureBuilder reload
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const TitleApp(text: "Trajets Disponibles", retour: true),
      backgroundColor: Colors.grey[100], // Slightly off-white background
      body: FutureBuilder<List<TrajetDisplayData>>(
        future: _trajetsFuture,
        builder: (context, snapshot) => _buildBody(context, snapshot),
      ),
    );
  }

  // Centralized body building logic
  Widget _buildBody(
    BuildContext context,
    AsyncSnapshot<List<TrajetDisplayData>> snapshot,
  ) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(child: CircularProgressIndicator());
    }

    if (snapshot.hasError) {
      debugPrint('TrajetScreen Error: ${snapshot.error}');
      return _buildErrorWidget(snapshot.error);
    }

    if (!snapshot.hasData || snapshot.data!.isEmpty) {
      return _buildNoDataWidget();
    }

    // Data is available
    return _buildTrajetListView(snapshot.data!);
  }

  // Widget for displaying errors
  Widget _buildErrorWidget(Object? error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 50),
            const SizedBox(height: 16),
            Text(
              'Une erreur s\'est produite',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.red.shade700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              // Provide a more generic message for users
              error is Exception ? error.toString() : 'Impossible de charger les trajets.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
              onPressed: _retryLoadTrajets,
            ),
          ],
        ),
      ),
    );
  }

  // Widget for displaying when no data is found
  Widget _buildNoDataWidget() {
     return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
             Icon(Icons.search_off, color: Colors.grey[600], size: 50),
             const SizedBox(height: 16),
            Text(
              'Aucun trajet trouvé',
               style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Nous n\'avons pas trouvé de trajet correspondant à vos critères dans la période de recherche (+/- 5 jours).',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
             const SizedBox(height: 8),
             Text(
              'Recherche: ${widget.from} → ${widget.to} (${widget.transportType}) autour du ${widget.date}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[700]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
               icon: const Icon(Icons.refresh),
               label: const Text('Rafraîchir'),
              onPressed: _retryLoadTrajets,
            ),
          ],
        ),
      ),
    );
  }

  // Widget for displaying the list of trajets
  Widget _buildTrajetListView(List<TrajetDisplayData> trajets) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0), // Adjusted padding
      itemCount: trajets.length,
      itemBuilder: (context, index) {
        // Use the extracted TrajetCard widget
        return TrajetCard(
          trajetData: trajets[index],
          targetDate: _targetDate, // Pass the target date for comparison
          onTap: () => _navigateToBaggageScreen(trajets[index]),
        );
      },
    );
  }

  // Navigation logic
  void _navigateToBaggageScreen(TrajetDisplayData data) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ModernBaggageScreen(
          locations: data.trajet.value, // Use combined value
          travelDate: data.trajet.date, // Use date string from trajet
          transportType: data.trajet.style == 'Bateau' ? 'boat' : 'plane',
          chauffeurId: data.chauffeur.id,
          trajetId: data.trajet.id,
        ),
      ),
    );
  }
}
