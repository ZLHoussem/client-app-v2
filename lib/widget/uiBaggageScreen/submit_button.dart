// lib/uiBaggageScreen/submit_baggage_button.dart
import 'package:bladi_go_client/widget/button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart'; // Keep for animation

// Import your custom ButtonApp and its dependencies

/// The main submission button, using the custom ButtonApp widget.
class SubmitBaggageButton extends StatelessWidget {
  final VoidCallback onPressed; // Callback when pressed
  final bool isLoading; // Whether to show the loading indicator
  final String label; // Text to display on the button (e.g., 'Soumettre' or 'Mettre à Jour')

  const SubmitBaggageButton({
    Key? key,
    required this.onPressed,
    required this.isLoading,
    required this.label,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Determine the theme's primary color for the loader for better consistency
    final primaryColor = Theme.of(context).primaryColor;

    // Use Center as the outermost widget, consistent with ButtonApp's structure
    return Center(
      child: isLoading
          // If loading, display a progress indicator.
          // Wrap it in a SizedBox to give it a defined area,
          // potentially matching the ButtonApp's approximate height for visual consistency.
          ? SizedBox(
              height: 48, // Estimate ButtonApp's height (adjust if needed)
              width: 48,  // Make it square or adjust as preferred
              child: Center(
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  // Use the theme's primary color for the loader
                  valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                ),
              ),
            )
          // If not loading, display the custom ButtonApp
          : ButtonApp(
              text: label,
              // Pass the onPressed callback directly.
              // It's implicitly disabled because this branch only runs when isLoading is false.
              onPressed: onPressed,
            )
              .animate() // Apply the original animation to the ButtonApp
              .fadeIn(duration: 500.ms)
              .slideY(begin: 0.1),
    );
  }
}