import 'package:bladi_go_client/pages/signup.dart';
import 'package:bladi_go_client/style/p_style.dart' show AppTextStyle;
import 'package:flutter/material.dart';

class SignupLink extends StatelessWidget {
  final bool isLoading; // To disable tap when loading

  const SignupLink({
    super.key,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          "Vous n'avez pas de compte ? ",
          style: AppTextStyle.loginsignintext,
        ),
        InkWell(
          onTap: isLoading
              ? null // Disable tap if loading
              : () => Navigator.push( // Use replacement if logical
                    context,
                    MaterialPageRoute(builder: (_) => const Signup()),
                  ),
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
            child: Text(
              "S'inscrire",
              style: AppTextStyle.linktext,
            ),
          ),
        ),
      ],
    );
  }
}