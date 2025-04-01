import 'package:bladi_go_client/pages/rechercheapi.dart';
import 'package:bladi_go_client/widget/inputdecor.dart';
import 'package:flutter/material.dart';


class LocationInputWidget extends StatefulWidget {
  final TextEditingController locationController;
  final String labelText;
  final String? Function(String?)? validator;
  final IconData prefixIcon;

  const LocationInputWidget({
    super.key,
    required this.locationController,
    this.labelText = 'Location',
    this.validator,
    this.prefixIcon = Icons.location_on,
  });

  @override
  State<LocationInputWidget> createState() => _LocationInputWidgetState();
}

class _LocationInputWidgetState extends State<LocationInputWidget> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        TextFormField(
          controller: widget.locationController,
          readOnly: true,
          decoration: InputDecorationBuilder.buildInputDecoration(
            labelText: widget.labelText,
            icon: widget.prefixIcon,
            hintText: 'Choisissez un emplacement',
          ),
          onTap: () async {
            final selectedLocation = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => LocationSearchScreen(
                  labelText: widget.labelText,
                  onLocationSelected: (location) {
                    widget.locationController.text = location;
                  },
                ),
              ),
            );
            if (selectedLocation != null && mounted) {
              setState(() {
                widget.locationController.text = selectedLocation;
              });
            }
          },
          validator: widget.validator ??
              (value) => value == null || value.isEmpty
                  ? 'Veuillez sélectionner une adresse'
                  : null,
        ),
      ],
    );
  }
}