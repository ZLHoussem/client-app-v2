import 'package:bladi_go_client/style/label_style.dart';
import 'package:flutter/material.dart';
// Remove the direct import of AppLabelStyle if it's not used elsewhere or handle it appropriately
// import 'package:bladi_go_client/style/label_style.dart';

class CustomPhoneField extends StatefulWidget {
  final FocusNode? focusNode;
  final TextEditingController? controller;
  final Function(String) onChanged;
  final Function(String) onCountryChanged;

  const CustomPhoneField({
    super.key,
    this.focusNode,
    this.controller,
    required this.onChanged,
    required this.onCountryChanged,
  });

  @override
  State<CustomPhoneField> createState() => _CustomPhoneFieldState();
}

class _CustomPhoneFieldState extends State<CustomPhoneField> {
  String _selectedCountryCode = '+216'; // Default to Tunisia
  late TextEditingController _phoneController;

  static const Map<String, String> _countries = {
    '+216': '🇹🇳', // Tunisia
    '+33': '🇫🇷', // France
    '+212': '🇲🇦', // Maroc (Morocco)
    '+213': '🇩🇿', // Algeria
  };

  static const Map<String, String> _countryNames = {
    '+216': 'Tunisia',
    '+33': 'France',
    '+212': 'Maroc',
    '+213': 'Algeria',
  };

  // Define consistent border radius and styling elements
  static const BorderRadius _borderRadius = BorderRadius.all(
    Radius.circular(30),
  );
  static const Color _fillColor = Color(0xFFedf0f8);
  static const BorderSide _focusedBorderSide = BorderSide(
    color: Colors.blue,
    width: 1.5,
  );
  static const BorderSide _enabledBorderSide =
      BorderSide.none; // No visible border when enabled but not focused
  static const BorderSide _errorBorderSide = BorderSide(
    color: Colors.red,
    width: 1.5,
  );

  @override
  void initState() {
    super.initState();
    _phoneController = widget.controller ?? TextEditingController();
    // Add listener *after* controller is initialized
    _phoneController.addListener(_handlePhoneChange);
  }

  void _handlePhoneChange() {
    if (!mounted) return;
    String fullPhoneNumber = '$_selectedCountryCode${_phoneController.text}';
    widget.onChanged(fullPhoneNumber);
  }

  @override
  void dispose() {
    _phoneController.removeListener(_handlePhoneChange);
    // Dispose only if the controller was created internally
    if (widget.controller == null) {
      _phoneController.dispose();
    }
    super.dispose();
  }

  // Validator function remains the same
  String? _validatePhoneNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      // Trim before check
      return 'Veuillez entrer un numéro'; // More concise message
    }

    final cleanedValue = value.replaceAll(RegExp(r'[\s-]'), '');

    switch (_selectedCountryCode) {
      case '+216':
        if (!RegExp(r'^\d{8}$').hasMatch(cleanedValue))
          return 'Numéro tunisien : 8 chiffres requis';
        break;
      case '+33':
        if (!RegExp(r'^\d{9}$').hasMatch(cleanedValue))
          return 'Numéro français : 9 chiffres requis';
        break;
      case '+212':
        if (!RegExp(r'^\d{9}$').hasMatch(cleanedValue))
          return 'Numéro marocain : 9 chiffres requis';
        break;
      case '+213':
        if (!RegExp(r'^\d{9}$').hasMatch(cleanedValue))
          return 'Numéro algérien : 9 chiffres requis';
        break;
      default: // Basic length check for unknown codes
        if (cleanedValue.length < 6 || cleanedValue.length > 15)
          return 'Numéro invalide';
    }
    return null; // Valid
  }

  @override
  Widget build(BuildContext context) {
    // Build the dropdown prefix widget separately for clarity
    Widget dropdownPrefix = Padding(
      // Add padding around the dropdown within the prefix area
      padding: const EdgeInsets.only(left: 12.0, right: 8.0),
      child: DropdownButtonHideUnderline(
        // Use HideUnderline wrapper
        child: DropdownButton<String>(
          value: _selectedCountryCode,
          items:
              _countries.keys.map((code) {
                return DropdownMenuItem<String>(
                  value: code,
                  child: Row(
                    mainAxisSize: MainAxisSize.min, // Prevent excessive width
                    children: [
                      Text(
                        _countries[code]!,
                        style: const TextStyle(
                          fontSize: 18,
                        ), // Slightly larger flag
                      ),
                      const SizedBox(width: 8), // Adjust spacing
                      Text(
                        code,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black54,
                          fontWeight: FontWeight.w500,
                        ), // Adjusted style
                      ),
                    ],
                  ),
                );
              }).toList(),
          onChanged: (String? value) {
            if (value != null && _countries.containsKey(value)) {
              setState(() {
                _selectedCountryCode = value;
                widget.onCountryChanged(_countryNames[value] ?? 'Unknown');
                _handlePhoneChange(); // Update full number when country changes
              });
            }
          },
          // No underline needed here
          icon: const Icon(Icons.arrow_drop_down, color: Colors.black54),
          // Make dropdown background transparent to use TextField's fill color
          dropdownColor: Colors.white, // Or match your theme background
          style: const TextStyle(
            // Ensure dropdown text style is consistent
            fontSize: 16,
            color: Colors.black87,
          ),
        ),
      ),
    );

    return Padding(
      // Padding around the entire text field
      padding: const EdgeInsets.symmetric(
        vertical: 8,
        horizontal: 0,
      ), // Adjusted padding
      child: TextFormField(
        focusNode: widget.focusNode,
        controller: _phoneController,
        keyboardType: TextInputType.phone,
        style: const TextStyle(
          fontSize: 18,
          color: Colors.black87,
        ), // Input text style
        decoration: InputDecoration(
          // Use the dropdown widget as the prefix
          prefixIcon:
              dropdownPrefix, // Using prefixIcon adds consistent padding behavior

          // Alternatively use 'prefix: dropdownPrefix' if prefixIcon alignment isn't right
          labelText: 'Numéro de téléphone',
          // labelStyle: AppLabelStyle.linktext, // Apply your label style if needed
          labelStyle: AppLabelStyle.linktext, // Example label style
          hintText: 'Numéro', // Shorter hint
          hintStyle: const TextStyle(color: Colors.black45, fontSize: 16),

          // Border definitions
          border: OutlineInputBorder(
            // Base border
            borderRadius: _borderRadius,
            borderSide: _enabledBorderSide, // Use none for base/enabled
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: _borderRadius,
            borderSide: _enabledBorderSide, // No border when enabled
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: _borderRadius,
            borderSide: _focusedBorderSide, // Blue border when focused
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: _borderRadius,
            borderSide: _errorBorderSide, // Red border on error
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: _borderRadius,
            borderSide: _errorBorderSide.copyWith(
              width: 2.0,
            ), // Thicker red border on focused error
          ),

          filled: true,
          fillColor: _fillColor, // Consistent fill color
          // Adjust content padding if needed, especially left padding
          // The prefixIcon usually handles alignment well, but you can fine-tune
          contentPadding: const EdgeInsets.symmetric(
            vertical: 16,
            horizontal: 15,
          ),

          errorStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ), // Error text style
        ),
        validator: _validatePhoneNumber,
        // Optional: Define textInputAction based on whether it's the last field
        textInputAction: TextInputAction.next, // Or TextInputAction.done
      ),
    );
  }
}
