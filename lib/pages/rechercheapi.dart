import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LocationSearchScreen extends StatefulWidget {
  final String labelText;
  final Function(String) onLocationSelected;
  const LocationSearchScreen({
    super.key,
    required this.labelText,
    required this.onLocationSelected,
  });

  @override
  State<LocationSearchScreen> createState() => _LocationSearchScreenState();
}

class _LocationSearchScreenState extends State<LocationSearchScreen> {
  List<Map<String, dynamic>> _filteredLocations = [];
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _fetchLocations(_searchController.text);
  }

  Future<void> _fetchLocations(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _filteredLocations = [];
        _errorMessage = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      String url =
          "http://twsoss4s0wgwgo8gcsk404sk.82.112.242.233.sslip.io/api/cities/search?q=$query";
      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      );
      print('$url');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] && data['data'] != null) {
          List<Map<String, dynamic>> locations = [];
          
          // Handle the flat list of city strings
          if (data['data'] is List) {
            for (var cityString in data['data']) {
              if (cityString is String) {
                final cityParts = cityString.split(' - ');
                final cityName = cityParts[0];
                final code = cityParts.length > 1 ? cityParts[1] : '';
                
                locations.add({
                  'name': cityName,
                  'address': code.isNotEmpty ? '($code)' : '',
                });
              }
            }
          }
          
          setState(() {
            _filteredLocations = locations;
          });
        } else {
          setState(() {
            _filteredLocations = [];
          });
        }
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(
          errorData['error'] ?? 'HTTP error! Status: ${response.statusCode}',
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: ${e.toString()}';
        _filteredLocations = [];
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: widget.labelText,
            border: InputBorder.none,
          ),
        ),
      ),
      body: Column(
        children: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: CircularProgressIndicator()),
            ),
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red, fontSize: 14),
              ),
            ),
          Expanded(
            child:
                _filteredLocations.isEmpty && !_isLoading
                    ? const Center(child: Text('Aucun lieu trouvé'))
                    : ListView.builder(
                      itemCount: _filteredLocations.length,
                      itemBuilder: (context, index) {
                        final location = _filteredLocations[index];
                        return ListTile(
                          leading: const Icon(
                            Icons.location_pin,
                            color: Colors.grey,
                          ),
                          title: Text(location['name']),
                          subtitle: Text(location['address']),
                          onTap: () {
                            widget.onLocationSelected(location['name']);
                            Navigator.pop(context, location['name']);
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