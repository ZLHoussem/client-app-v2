import 'package:bladi_go_client/widget/button.dart'; // Assuming general ButtonApp is here
import 'package:flutter/material.dart';

class LoginButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback? onPressed;

  const LoginButton({
    super.key,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    // No ValueListenableBuilder needed here, the parent manages it
    return isLoading
        ? const Center(child: CircularProgressIndicator())
        : ButtonApp(
            text: "Se Connecter",
            onPressed: isLoading ? null : onPressed, // Disable button when loading
          );
  }
}