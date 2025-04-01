
import 'package:bladi_go_client/widget/inputdecor.dart';
import 'package:flutter/material.dart';

class EmailInputWidget extends StatelessWidget {
  final TextEditingController emailController;
  final FocusNode? focusNode; // Added
  final FocusNode? nextFocusNode; // Added

  const EmailInputWidget({
    super.key,
    required this.emailController,
    this.focusNode, // Added
    this.nextFocusNode, // Added
  });

  static final RegExp _emailRegExp = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');

  @override
  Widget build(BuildContext context) {
    return TextFieldInput(
      icon: Icons.mail,
      textEditingController: emailController,
      labelText: "Email",
      hintText: 'Entrez votre email',
      textInputType: TextInputType.emailAddress,
      focusNode: focusNode, // Passed
      // Assuming TextFieldInput handles focus shifting via onFieldSubmitted
      onFieldSubmitted: (_) {
         if (nextFocusNode != null) {
           FocusScope.of(context).requestFocus(nextFocusNode);
         } else {
           FocusScope.of(context).unfocus(); // Unfocus if last field
         }
      },
      textInputAction: nextFocusNode != null ? TextInputAction.next : TextInputAction.done, // Set appropriate action
      validator: _validateEmail,
    );
  }

  static String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) { // Trim value before check
      return 'Veuillez entrer votre adresse email';
    }
    if (!_emailRegExp.hasMatch(value.trim())) { // Trim value before regex
      return 'Veuillez entrer une adresse email valide';
    }
    return null;
  }
}