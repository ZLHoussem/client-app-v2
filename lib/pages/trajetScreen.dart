// No changes needed in TrajetScreen.dart
import 'package:bladi_go_client/models/trajet_models.dart'; // Ensure path is correct
import 'package:bladi_go_client/pages/baggage_screen.dart'; // Ensure path is correct
import 'package:bladi_go_client/service/trajet_service.dart'; // Ensure path is correct
import 'package:bladi_go_client/widget/title.dart';        // Ensure path is correct
import 'package:bladi_go_client/widget/trajet_card.dart';   // Ensure path is correct
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For date formatting

class TrajetScreen extends StatefulWidget {
  final String from;
  final String to;
  final String date; // Expecting "YYYY/MM/DD" from previous screen
  final String transportType; // Expecting type from previous screen (e.g., 'Voiture', 'Avion', 'Bateau')

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
  final TrajetService _trajetService = TrajetService(); // Service instance
  late Future<List<TrajetDisplayData>> _trajetsFuture; // Future for FutureBuilder
  DateTime? _targetDate; // Parsed target date for potential highlighting

  @override
  void initState() {
    super.initState();
    _parseTargetDate(); // Parse the date string first
    _loadTrajets(); // Then load data using the original date string
  }

  // Parses the initial date string into a DateTime object
  void _parseTargetDate() {
     try {
       // Ensure the format matches the input string "YYYY/MM/DD"
       _targetDate = DateFormat('yyyy/MM/dd').parseStrict(widget.date);
     } catch (e) {
       debugPrint("Error parsing initial date '${widget.date}': $e");
       _targetDate = null; // Set to null if parsing fails
     }
  }

  // Initiates the data fetching process
  void _loadTrajets() {
    _trajetsFuture = _trajetService.getTrajets( // Calls the updated service method
      from: widget.from,
      to: widget.to,
      dateString: widget.date,
      transportType: widget.transportType,
    );
  }

  // Retries fetching data when an error occurs or user refreshes
  void _retryLoadTrajets() {
    setState(() {
      _loadTrajets(); // Re-assign the future to make FutureBuilder rebuild
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const TitleApp(text: "Trajets Disponibles", retour: true),
      backgroundColor: Colors.grey[100],
      body: FutureBuilder<List<TrajetDisplayData>>(
        future: _trajetsFuture,
        builder: _buildBody,
      ),
    );
  }

  // Builds the main body content based on the FutureBuilder snapshot
  Widget _buildBody(
    BuildContext context,
    AsyncSnapshot<List<TrajetDisplayData>> snapshot,
  ) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(child: CircularProgressIndicator());
    }
    if (snapshot.hasError) {
      debugPrint('TrajetScreen Error: ${snapshot.error}');
      debugPrint('Stacktrace: ${snapshot.stackTrace}');
      return _buildErrorWidget(snapshot.error);
    }
    if (!snapshot.hasData || snapshot.data!.isEmpty) {
      return _buildNoDataWidget();
    }
    return _buildTrajetListView(snapshot.data!);
  }

  // Widget to display when an error occurs
  Widget _buildErrorWidget(Object? error) {
    // (Implementation remains the same)
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 50),
            const SizedBox(height: 16),
            Text(
              'Une erreur s\'est produite',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.red.shade700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Impossible de charger les trajets pour le moment. Veuillez vérifier votre connexion et réessayer.',
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

  // Widget to display when no trajets are found
  Widget _buildNoDataWidget() {
    // (Implementation remains the same)
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
              'Nous n\'avons pas trouvé de trajet correspondant à vos critères. Essayez d\'ajuster votre recherche.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
             const SizedBox(height: 8),
             Text(
              'Recherche: ${widget.from} → ${widget.to} (${widget.transportType}) le ${widget.date}',
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

  // Widget to build the scrollable list of TrajetCards
  Widget _buildTrajetListView(List<TrajetDisplayData> trajets) {
    // (Implementation remains the same)
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 8.0),
      itemCount: trajets.length,
      itemBuilder: (context, index) {
        final trajetData = trajets[index];
        return TrajetCard(
          trajetData: trajetData,
          targetDate: _targetDate,
          onTap: () => _navigateToBaggageScreen(trajetData),
        );
      },
    );
  }

  // Handles navigation to the baggage selection screen
  void _navigateToBaggageScreen(TrajetDisplayData data) {
    // (Implementation remains the same)
     String mappedTransportType;
     switch (data.trajet.style?.toLowerCase()) {
       case 'bateau': mappedTransportType = 'boat'; break;
       case 'avion': mappedTransportType = 'plane'; break;
       case 'voiture': mappedTransportType = 'car'; break;
       default:
         debugPrint("Unknown transport style: ${data.trajet.style}");
         mappedTransportType = 'other';
     }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ModernBaggageScreen(
          locations: data.trajet.routePreview ?? data.trajet.value ?? 'Itinéraire inconnu',
          travelDate: data.trajet.date, // Pass the String date
          transportType: mappedTransportType,
          chauffeurId: data.chauffeur.id,
          trajetId: data.trajet.id,
        ),
      ),
    );
  }
}