
import 'package:bladi_go_client/widget/inputdecor.dart';
import 'package:flutter/material.dart';

class NameInputWidget extends StatelessWidget {
  final TextEditingController nameController;
  final FocusNode? focusNode; // Added
  final FocusNode? nextFocusNode; // Added

  const NameInputWidget({
    super.key,
    required this.nameController,
    this.focusNode, // Added
    this.nextFocusNode, // Added
  });

  @override
  Widget build(BuildContext context) {
    return TextFieldInput(
      icon: Icons.person,
      textEditingController: nameController,
      labelText: "Nom et Prenom",
      hintText: 'Entrez votre nom',
      textInputType: TextInputType.name,
      focusNode: focusNode, // Passed
      // Assuming TextFieldInput handles focus shifting via onFieldSubmitted
      onFieldSubmitted: (_) {
         if (nextFocusNode != null) {
           FocusScope.of(context).requestFocus(nextFocusNode);
         } else {
           FocusScope.of(context).unfocus();
         }
      },
      textInputAction: nextFocusNode != null ? TextInputAction.next : TextInputAction.done,
      validator: (value) {
        if (value == null || value.trim().isEmpty) { // Trim value
          return 'Veuillez entrer votre nom';
        }
         if (value.trim().length < 2) { // Example: Add minimum length
           return 'Le nom doit comporter au moins 2 caractères';
         }
        return null;
      },
    );
  }
}