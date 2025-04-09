// home.dart (or home_screen.dart)
import 'package:bladi_go_client/pages/notification.dart';
import 'package:bladi_go_client/pages/trajetScreen.dart';
import 'package:bladi_go_client/provider/search_state.dart';
import 'package:bladi_go_client/provider/user.dart';
import 'package:bladi_go_client/service/home_service.dart';
import 'package:bladi_go_client/widget/home_ui/home_header.dart';
import 'package:bladi_go_client/widget/home_ui/search_form.dart';
import 'package:bladi_go_client/widget/title.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class Home extends StatefulWidget {
  const Home({super.key});
  static const route = '/home';

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  // Use the service
  final HomeService _homeService = HomeService();

  // State variables managed by this screen
  bool _isLoading = true;
  String? _clientName;
  String? _errorMessage; // To store potential errors
  Stream<int>? _pendingRequestsStream; // Hold the stream

  // Notification initialization flag
  bool _hasInitializedNotifications = false;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
   
    if (!_hasInitializedNotifications && mounted) {
       _hasInitializedNotifications = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        
         if(mounted) {
            _initializeNotifications();
         }
      });
    }
  }

  Future<void> _initializeNotifications() async {
   
     await _homeService.initializeNotifications(context);
  }


  Future<void> _initializeData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null; // Reset error on reload
    });

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final String? userId = userProvider.userId;

    if (userId == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = "Utilisateur non connecté.";
      });
      return;
    }

    try {
      // Fetch client name using the service
      final name = await _homeService.fetchClientName(userId);

      // Get the stream using the service
      final stream = _homeService.getPendingRequestsStream(userId);

      if (mounted) {
        setState(() {
          _clientName = name;
          _pendingRequestsStream = stream; // Assign the stream
          _isLoading = false;
        });
      }
    } catch (e) {
       debugPrint("Error initializing data: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = "Erreur de chargement des données. (${e.toString()})"; // Show specific error
        });
      }
    }
  }

  void _navigateToNotifications() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => NotificationScreen()),
    );
  }

  // Callback function passed to SearchForm
 void _handleSearch(Map<String, String> searchParams) {
    print("Search triggered with params: $searchParams"); // For debugging

    // --- Get values, handle potential nulls ---
    final String fromValue = searchParams['from'] ?? ''; // Default to empty string if null
    final String toValue = searchParams['to'] ?? '';   // Default to empty string if null
    final String? dateValue = searchParams['date']; // Keep nullable for check
    final String? transportTypeValue = searchParams['transportType']; // Keep nullable for check

    // --- Update the Provider ---
    // Use listen: false as we are only calling a method, not reacting to changes here.
    try {
      Provider.of<SearchState>(context, listen: false)
          .updateSearchDetails(fromValue, toValue);
    } catch (e) {
      print("Error updating SearchState provider: $e");
      // Optionally show a specific error message for provider update failure
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur interne lors de la sauvegarde de la recherche: $e'), backgroundColor: Colors.orange),
        );
      }
      return; // Stop if provider update fails
    }

    // --- Check required parameters for Navigation ---
    if (dateValue == null || dateValue.isEmpty || transportTypeValue == null || transportTypeValue.isEmpty) {
      print("Error: Missing date or transportType for navigation.");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Veuillez renseigner la date et le type de transport.'), backgroundColor: Colors.red),
        );
      }
      return; // Stop execution if required parameters are missing
    }
 // For debugging
     try {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TrajetScreen(
              from: searchParams['from']!,
              to: searchParams['to']!,
              date: searchParams['date']!,
              transportType: searchParams['transportType']!,
            ),
          ),
        );
     } catch (e) {
        if(mounted) {
             ScaffoldMessenger.of(context).showSnackBar(
               SnackBar(content: Text('Erreur lors de la navigation: $e'), backgroundColor: Colors.red,)
             );
        }
     }
  }




  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Prevent keyboard overlap
      resizeToAvoidBottomInset: true, // Set to true when keyboard might appear
      appBar: TitleApp(
        // Use default text if name is loading or errored
        text: 'Bienvenue, ${_clientName ?? "Utilisateur"}',
        retour: false,
      ),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
             mainAxisAlignment: MainAxisAlignment.center,
             children: [
               Text(_errorMessage!, style: TextStyle(color: Colors.red, fontSize: 16), textAlign: TextAlign.center,),
               const SizedBox(height: 20),
               ElevatedButton(onPressed: _initializeData, child: Text("Réessayer"))
             ],
          ),
        ),
      );
    }

    // Use StreamBuilder to listen for pending requests count
    return StreamBuilder<int>(
      stream: _pendingRequestsStream,
      initialData: 0, // Start with 0 pending requests
      builder: (context, snapshot) {
         int pendingRequests = 0;
         if(snapshot.hasError){
            debugPrint("Error in pending requests stream: ${snapshot.error}");
            // Optionally show an indicator in the badge or log
         } else if (snapshot.hasData) {
            pendingRequests = snapshot.data!;
         }

        // Build the main layout using Column
        return Column(
          children: [
            // Use the extracted Header widget
            HomeHeader(
              pendingRequests: pendingRequests,
              onNotificationTap: _navigateToNotifications,
            ),
            // Use the extracted Form widget, wrapped in Expanded
            Expanded(
              child: SearchForm(
                 onSearch: _handleSearch, // Pass the search handler
              ),
            ),
          ],
        );
      },
    );
  }
}