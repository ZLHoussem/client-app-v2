import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart'; // Ensure you have flutter_svg in pubspec.yaml

class TitleApp extends StatelessWidget implements PreferredSizeWidget {
  const TitleApp({
    super.key,
    required this.text,
    required this.retour, // Expecting a boolean value
  });

  final String text;
  final bool retour;

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(
        text,
        style: const TextStyle(
          color: Colors.black, // Consider using Theme.of(context).appBarTheme.titleTextStyle
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: Colors.white, // Consider using Theme.of(context).appBarTheme.backgroundColor
      elevation: 0.0,
      centerTitle: true,
      // Use automaticallyImplyLeading: false if you *never* want Flutter's default back button
      // automaticallyImplyLeading: false,

      // Conditionally set the leading widget
      leading: retour
          ? IconButton(
              icon: Container(
                // Keep the container if you specifically want that background/shape
                // Otherwise, put SvgPicture directly inside IconButton
                padding: const EdgeInsets.all(8), // Adjust padding as needed
                decoration: BoxDecoration(
                  color: const Color(0xffF7F8F8), // Your custom background
                  borderRadius: BorderRadius.circular(10),
                ),
                child: SvgPicture.asset(
                  'assets/icons/Flache.svg', // Ensure this path is correct in pubspec.yaml
                  height: 20,
                  width: 20,
                  colorFilter: const ColorFilter.mode(Colors.black, BlendMode.srcIn), // Optional: To color the SVG
                ),
              ),
              tooltip: MaterialLocalizations.of(context).backButtonTooltip, // Accessibility
              onPressed: () {
                // Check if navigation is possible before popping
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                }
              },
              splashRadius: 24, // Standard splash radius for IconButton
            )
          : null, // Provide null when retour is false to allow default behavior (like drawer icon)
                 // Or use 'leading: const SizedBox.shrink()' if you want to guarantee empty space
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight); // Standard AppBar height
}