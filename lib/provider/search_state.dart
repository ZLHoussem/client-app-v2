import 'package:flutter/foundation.dart'; // Required for ChangeNotifier

class SearchState with ChangeNotifier {
  String _from = ''; // Private variable for 'from' location
  String _to = '';   // Private variable for 'to' location

  // Public getters to access the values
  String get from => _from;
  String get to => _to;

  // Method to update the search details and notify listeners
  void updateSearchDetails(String newFrom, String newTo) {
    _from = newFrom;
    _to = newTo;
    print('Provider updated: from=$_from, to=$_to'); // For debugging
    notifyListeners(); // This tells widgets listening to this provider to rebuild
  }
}