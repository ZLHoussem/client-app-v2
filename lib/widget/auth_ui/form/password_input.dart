
import 'package:bladi_go_client/widget/inputdecor.dart';
import 'package:flutter/material.dart';

class PasswordInputWidgetInternal extends StatelessWidget {
  final TextEditingController passwordController;
  final bool isPasswordVisible;
  final VoidCallback onToggleVisibility;
  final String? labelText;
  final FocusNode? focusNode; // Added
  final FocusNode? nextFocusNode; // Added
  final String? Function(String?)? validator; // Added validator parameter

  const PasswordInputWidgetInternal({
    super.key,
    required this.passwordController,
    required this.isPasswordVisible,
    required this.onToggleVisibility,
    this.labelText = 'Mot de passe',
    this.focusNode, // Added
    this.nextFocusNode, // Added
    this.validator, // Added
  });

  @override
  Widget build(BuildContext context) {
    return TextFieldInput(
      icon: Icons.lock,
      textEditingController: passwordController,
      labelText: labelText ?? 'Mot de passe',
      hintText: 'Entrez votre mot de passe',
      suffixIcon: isPasswordVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined, // Use outlined icons
      onSuffixIconPressed: onToggleVisibility,
      textInputType: TextInputType.visiblePassword, // More appropriate type
      focusNode: focusNode, // Passed
      // Assuming TextFieldInput handles focus shifting via onFieldSubmitted
      onFieldSubmitted: (_) {
         if (nextFocusNode != null) {
           FocusScope.of(context).requestFocus(nextFocusNode);
         } else {
            // If it's the confirmation field and validation passes, maybe trigger form submission?
            // Or just unfocus as default.
           FocusScope.of(context).unfocus();
         }
      },
      textInputAction: nextFocusNode != null ? TextInputAction.next : TextInputAction.done,
      validator: validator ?? _defaultValidator, // Use passed validator or default
      obscureText: !isPasswordVisible,
    );
  }

  // Default validator if none is provided
  static String? _defaultValidator(String? value) {
     if (value == null || value.isEmpty) {
       return 'Veuillez entrer un mot de passe';
     }
     if (value.length < 6) { // Use 6 to match AuthService example (or keep 8 if intended)
       return 'Le mot de passe doit contenir au moins 6 caractères';
     }
     return null;
   }
}