// lib/widget/auth/register_button.dart
import 'package:flutter/material.dart';
import 'package:bladi_go_client/widget/button.dart'; // Assuming your general ButtonApp is here

class RegisterButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback? onPressed; // Use VoidCallback? for nullable onPressed

  const RegisterButton({
    super.key,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return isLoading
        ? const Center(child: CircularProgressIndicator())
        // Ensure ButtonApp handles null onPressed or disable explicitly
        : ButtonApp(
            text: "S'inscrire",
            onPressed: isLoading ? null : onPressed, // Disable button when loading
          );
  }
}