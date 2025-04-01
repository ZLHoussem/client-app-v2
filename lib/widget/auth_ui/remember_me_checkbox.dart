import 'package:flutter/material.dart';

class RememberMeCheckbox extends StatelessWidget {
  final bool value;
  final ValueChanged<bool?> onChanged;

  const RememberMeCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Checkbox(
          value: value,
          onChanged: onChanged,
          activeColor: const Color(0xFF416FDF),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        // Use Flexible to prevent overflow if text is long
        const Flexible(
          child: Text(
            'Se souvenir de moi',
            style: TextStyle(color: Colors.black54), // Adjusted color slightly
          ),
        ),
        const Spacer(), // Pushes Forgot Password link (if added later) to the right
      ],
    );
  }
}