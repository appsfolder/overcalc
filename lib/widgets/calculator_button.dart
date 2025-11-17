import 'package:flutter/material.dart';

class CalculatorButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final Color? backgroundColor;
  final Color? textColor;

  const CalculatorButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.backgroundColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    Widget child;
    if (text == '⌫') {
      child = Center(
        child: Icon(Icons.backspace_outlined, color: textColor, size: 28),
      );
    } else {
      child = Text(
        text,
        style: const TextStyle(
          fontFamily: 'IBMPlexSans',
          fontSize: 28,
          fontWeight: FontWeight.bold,
        ),
      );
    }

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(6.0),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: backgroundColor ?? Colors.grey.shade800,
            foregroundColor: textColor ?? Colors.white,
            shape: const CircleBorder(),
          ),
          child: child,
        ),
      ),
    );
  }
}
