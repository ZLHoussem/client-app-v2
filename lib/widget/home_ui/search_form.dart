// widgets/search_form.dart

import 'package:bladi_go_client/widget/button.dart';

import 'package:bladi_go_client/style/p_style.dart' show AppTextStyle;
import 'package:bladi_go_client/widget/home_ui/date_input.dart';
import 'package:bladi_go_client/widget/home_ui/location_input.dart';
import 'package:bladi_go_client/widget/home_ui/transport_button.dart';

import 'package:flutter/material.dart';

// Define a callback type for search submission
typedef SearchCallback = void Function(Map<String, String> searchParams);

class SearchForm extends StatefulWidget {
  final SearchCallback onSearch;

  const SearchForm({super.key, required this.onSearch});

  @override
  State<SearchForm> createState() => _SearchFormState();
}

class _SearchFormState extends State<SearchForm> {
  final _formKey = GlobalKey<FormState>();
  final _dateController = TextEditingController();
  final _fromController = TextEditingController();
  final _toController = TextEditingController();

  bool _isBoatSelected = false;
  bool _isPlaneSelected = false;

  @override
  void dispose() {
    _dateController.dispose();
    _fromController.dispose();
    _toController.dispose();
    super.dispose();
  }

  void _handleTransportSelection(String type) {
    setState(() {
      if (type == 'Bateau') {
        _isBoatSelected = !_isBoatSelected;
        if (_isBoatSelected) _isPlaneSelected = false;
      } else if (type == 'Avion') {
        _isPlaneSelected = !_isPlaneSelected;
        if (_isPlaneSelected) _isBoatSelected = false;
      }
    });
  }

  void _submitSearch() {
    // 1. Validate Form
    if (!(_formKey.currentState?.validate() ?? false)) {
      return; // Validation failed
    }

    // 2. Check Transport Selection
    if (!_isBoatSelected && !_isPlaneSelected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Veuillez sélectionner un type de transport.'),
            backgroundColor: Colors.orange), // Use warning color
      );
      return;
    }

    // 3. Prepare Search Parameters
    final searchParams = {
      'from': _fromController.text.trim(),
      'to': _toController.text.trim(),
      'date': _dateController.text.trim(),
      'transportType': _isBoatSelected ? 'Bateau' : 'Avion',
    };

    // 4. Call the callback provided by the parent widget
    widget.onSearch(searchParams);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[200], // Consider using Theme.of(context).canvasColor
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView( // Important for smaller screens
          child: Column(
            mainAxisSize: MainAxisSize.min, // Take only necessary space
            children: [
              Text('Formulaire de recherche', style: AppTextStyle.title),
              const SizedBox(height: 20), // Increased spacing slightly
              LocationInputWidget(
                locationController: _fromController,
                labelText: 'Départ',
                prefixIcon: Icons.location_searching_outlined,
                validator: (value) =>
                    value?.trim().isEmpty ?? true ? 'Champ requis' : null,
              ),
              const SizedBox(height: 16),
              LocationInputWidget(
                locationController: _toController,
                labelText: 'Arrivée',
                prefixIcon: Icons.location_on,
                validator: (value) =>
                    value?.trim().isEmpty ?? true ? 'Champ requis' : null,
              ),
              const SizedBox(height: 16),
              DateInputWidget(
                dateController: _dateController,
                prefixIcon: Icons.calendar_today_outlined,
                validator: (value) {
                  if (value?.trim().isEmpty ?? true) return 'Champ requis';
                  // Basic regex, consider more robust date validation if needed
                  if (!RegExp(r'^\d{4}/\d{2}/\d{2}$').hasMatch(value!)) {
                    return 'Format invalide (YYYY/MM/DD)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24), // Increased spacing
              _buildTransportSelector(),
              const SizedBox(height: 24), // Increased spacing
              ButtonApp(text: "Recherche", onPressed: _submitSearch),
              const SizedBox(height: 20), // Add padding at the bottom for keyboard
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTransportSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        TransportButton(
          label: 'Bateau',
          icon: Icons.directions_boat,
          isSelected: _isBoatSelected,
          onTap: () => _handleTransportSelection('Bateau'),
        ),
        const SizedBox(width: 20),
        TransportButton(
          label: 'Avion',
          icon: Icons.flight,
          isSelected: _isPlaneSelected,
          onTap: () => _handleTransportSelection('Avion'),
        ),
      ],
    );
  }
}