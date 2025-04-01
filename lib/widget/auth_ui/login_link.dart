// lib/widget/auth/login_link.dart
import 'package:bladi_go_client/pages/signin.dart';
import 'package:bladi_go_client/style/p_style.dart' show AppTextStyle; // Make sure this import is correct
import 'package:flutter/material.dart';

class LoginLink extends StatelessWidget {


  const LoginLink({
    super.key,

  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          "Vous avez deja un compte ? ",
          style: AppTextStyle.loginsignintext, // Ensure this style exists
        ),
        // Use InkWell or TextButton for better semantics/tap effects
      GestureDetector(
          onTap: () => Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const Signin()),
            (route) => false, // Clear the stack
          ),
          child: const Padding(
            // Add padding for easier tapping
            padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
            child: Text(
              "Se connecter",
              style: AppTextStyle.linktext, // Ensure this style exists
            ),
          ),
        ),
      ],
    );
  }
}