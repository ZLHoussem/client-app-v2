import 'package:flutter/material.dart';
import 'package:bladi_go_client/style/p_style.dart';



class ButtonApp extends StatelessWidget {
  const ButtonApp({
    super.key,
    required this.text,
    required this.onPressed,
  });

  final String text;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: Stack(
          children: <Widget>[
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: <Color>[
                      Color(0xFF0D47A1),
                      Color(0xFF1976D2),
                      Color(0xFF42A5F5),
                    ],
                  ),
                ),
              ),
            ),
            TextButton(
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 12),
                textStyle: const TextStyle(fontSize: 20),
              ),
              onPressed: onPressed, 
              child: Text(
                text, 
                style: ButtonTextStyle.bottontext,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
