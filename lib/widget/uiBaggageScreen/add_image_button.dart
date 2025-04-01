import 'package:flutter/material.dart';
// You might need a package for dashed borders like `dotted_border`
// Or implement a CustomPainter if you prefer no extra packages.
// For simplicity, using a solid border here.
// import 'package:dotted_border/dotted_border.dart';


/// A button used to trigger the image selection process.
class AddImageButton extends StatelessWidget {
  final VoidCallback onTap; // Callback when the button is tapped

  const AddImageButton({Key? key, required this.onTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Ajouter une image',
      child: InkWell( // Provides visual feedback on tap
        onTap: onTap,
        borderRadius: BorderRadius.circular(8), // Match the container's border radius
        child: Container(
          width: 80,
          height: 80,
          margin: const EdgeInsets.only(right: 10, bottom: 4, top: 4), // Match ImagePreviewWidget margins
          decoration: BoxDecoration(
            // Example using a solid border instead of dashed
            border: Border.all(color: Colors.grey.shade400, width: 1.5),
            borderRadius: BorderRadius.circular(8),
            color: Colors.grey.shade100, // Subtle background
          ),
          // Example using DottedBorder package:
          // child: DottedBorder(
          //   borderType: BorderType.RRect,
          //   radius: const Radius.circular(8),
          //   color: Colors.grey.shade500,
          //   strokeWidth: 1.5,
          //   dashPattern: const [4, 4],
          //   child: Center(...),
          // ),
          child: Center( // Center the icon
            child: Icon(
              Icons.add_photo_alternate_outlined,
              color: Colors.grey.shade600,
              size: 30
            ),
          ),
        ),
      ),
    );
  }
}