// lib/uiBaggageScreen/add_article_button.dart
import 'package:flutter/material.dart';

/// A button styled specifically to add a new baggage article section,
/// matching the original design request.
class AddArticleButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool enabled; // Added enabled flag for consistency

  const AddArticleButton({
    super.key,
    required this.onPressed,
    this.enabled = true, // Default to enabled
  });

  @override
  Widget build(BuildContext context) {
    // Use the exact styling provided by the user
    return Container( // Wrap in container for width control
      width: double.infinity, // Takes full available width
      margin: const EdgeInsets.only(top: 10), // Consistent spacing
      child: ElevatedButton.icon(
        onPressed: enabled ? onPressed : null, // Respect the enabled flag
        icon: Icon(
          Icons.add_circle_outline,
          color: enabled ? Colors.white : Colors.grey.shade400, // Adjust icon color when disabled
        ),
        label: Text(
          'Ajouter un autre article',
          style: TextStyle(
            // Adjust text color when disabled
            color: enabled ? Colors.white : Colors.grey.shade400,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          // Adjust background color when disabled
          backgroundColor: enabled ? Colors.blue.shade600 : Colors.grey.shade300,
          padding: const EdgeInsets.symmetric(vertical: 15), // Vertical padding
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12), // Rounded corners
          ),
          elevation: enabled ? 2 : 0, // Add elevation only when enabled
          textStyle: const TextStyle(fontSize: 15) // Ensure consistent text size
        ),
      ),
    );
  }
}