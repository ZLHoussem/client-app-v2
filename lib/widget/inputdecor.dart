import 'package:bladi_go_client/style/label_style.dart';

import 'package:flutter/material.dart';

class TextFieldInput extends StatelessWidget {
  final TextEditingController textEditingController;
  final bool obscureText;
  final String labelText;
  final String hintText;
  final IconData icon;
  final IconData? suffixIcon;
  final VoidCallback? onSuffixIconPressed;
  final TextInputType textInputType;
  final String? Function(String?)? validator;
  final FocusNode? focusNode; // Added
  final FocusNode? nextFocusNode; // Added to determine textInputAction
  final TextInputAction? textInputAction; // Added override
  final ValueChanged<String>? onFieldSubmitted; // Added callback

  const TextFieldInput({
    super.key,
    required this.textEditingController,
    this.obscureText = false,
    required this.labelText,
    required this.hintText,
    required this.icon,
    this.suffixIcon,
    this.onSuffixIconPressed,
    required this.textInputType,
    this.validator,
    this.focusNode, // Added
    this.nextFocusNode, // Added
    this.textInputAction, // Added
    this.onFieldSubmitted, // Added
  });

  @override
  Widget build(BuildContext context) {
    // Determine the appropriate TextInputAction if not explicitly provided
    final effectiveTextInputAction = textInputAction ??
        (nextFocusNode != null ? TextInputAction.next : TextInputAction.done);

    return Padding(
      // Consider making padding configurable if needed
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 0), // Adjusted padding
      child: TextFormField(
        controller: textEditingController,
        focusNode: focusNode, // Use the provided focusNode
        obscureText: obscureText,
        keyboardType: textInputType,
        textInputAction: effectiveTextInputAction, // Use determined action
        validator: validator,
        onFieldSubmitted: onFieldSubmitted, // Use the provided callback
        style: const TextStyle(fontSize: 18), // Example style adjustment
        decoration: InputDecorationBuilder.buildInputDecoration(
          labelText: labelText,
          icon: icon,
          hintText: hintText,
          suffixIcon: suffixIcon,
          onSuffixIconPressed: onSuffixIconPressed,
          // --- Assuming InputDecorationBuilder defines these ---
          // If not, keep them, but it's better design for the builder to handle them.
          // fillColor: const Color(0xFFedf0f8),
          // borderRadius: const BorderRadius.all(Radius.circular(30)),
          // errorBorderRadius: const BorderRadius.all(Radius.circular(30)), // Standardized radius
          // focusedBorderSide: const BorderSide(color: Colors.blue, width: 2),
          // ------------------------------------------------------
        ),
        // keyboardAppearance: Brightness.light, // Usually default, keep if needed
      ),
    );
  }
}

// --- Example Structure for InputDecorationBuilder (in inputdecor.dart) ---
// You should adapt this based on your actual InputDecorationBuilder implementation

class InputDecorationBuilder {
  static InputDecoration buildInputDecoration({
    required String labelText,
    required IconData icon,
    required String hintText,
    IconData? suffixIcon,
    VoidCallback? onSuffixIconPressed,
    // Define default styles here
    Color fillColor = const Color(0xFFedf0f8),
    BorderRadius borderRadius = const BorderRadius.all(Radius.circular(30)),
    BorderSide focusedBorderSide = const BorderSide(color: Colors.blue, width: 2), // Adjusted width
    BorderSide enabledBorderSide = const BorderSide(color: Colors.blue, width: 0.5), // Added enabled state
    BorderSide errorBorderSide = const BorderSide(color: Colors.red, width: 2), // Added error state
    Color suffixIconColor = Colors.blue,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      prefixIcon: Padding( // Add padding to the prefix icon
         padding: const EdgeInsets.only(left: 15.0, right: 10.0),
         child: Icon(icon, size: 22),
      ),
      suffixIcon: suffixIcon != null
          ? IconButton(
              icon: Icon(suffixIcon, size: 22),
              onPressed: onSuffixIconPressed,
              splashRadius: 20, 
              color: suffixIconColor,// Smaller splash for icon buttons
            )
          : null,
      border: OutlineInputBorder( // Base border
        borderRadius: borderRadius,
        borderSide: enabledBorderSide,
      ),
      enabledBorder: OutlineInputBorder( // Border when enabled but not focused
        borderRadius: borderRadius,
        borderSide: enabledBorderSide,
      ),
      focusedBorder: OutlineInputBorder( // Border when focused
        borderRadius: borderRadius,
        borderSide: focusedBorderSide,
      ),
      errorBorder: OutlineInputBorder( // Border when error
        borderRadius: borderRadius, // Use consistent radius
        borderSide: errorBorderSide,
      ),
       focusedErrorBorder: OutlineInputBorder( // Border when error and focused
        borderRadius: borderRadius,
        borderSide: errorBorderSide.copyWith(width: 2.0), // Slightly thicker focused error
      ),
      filled: true,
      fillColor: fillColor,
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20), // Adjusted padding
      hintStyle: const TextStyle(color: Colors.black45, fontSize: 16), // Adjusted style
      labelStyle: AppLabelStyle.linktext, // Adjusted style
      errorStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500), // Style for validation error text
    );
  }
}