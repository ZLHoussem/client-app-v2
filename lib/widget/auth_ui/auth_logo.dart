import 'package:flutter/material.dart';

class AuthLogo extends StatelessWidget {
  final double screenHeight;

  const AuthLogo({
    super.key,
    required this.screenHeight,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate height once
    final double logoHeight = screenHeight / 4.5; // Adjusted as per previous optimization
    final int cacheHeightValue = logoHeight.round();

    return Center(
      child: SizedBox(
        height: logoHeight,
        child: ClipRRect(
          // Use const where possible
          borderRadius: const BorderRadius.all(Radius.circular(80)), // Use const constructor
          child: Image.asset(
            'assets/images/logo.png', // Make sure this path is correct
            fit: BoxFit.contain, // Contain might be better
            // Let SizedBox define constraints
            // cacheHeight/width are useful, ensure they match render size
            cacheHeight: cacheHeightValue,
            // Optionally add cacheWidth if width is constrained/known
            // cacheWidth: cacheWidthValue,
          ),
        ),
      ),
    );
  }
}