import 'package:flutter/material.dart';

class StyledButton {
  final overlayButtonStyle = ButtonStyle(
    side: WidgetStateProperty.resolveWith<BorderSide?>((states) {
      if (states.contains(WidgetState.focused)) {
        return const BorderSide(color: Colors.red);
      } else {
        return const BorderSide(color: Colors.black);
      }
    }),
  );

  final menuButtonStyle = ButtonStyle(
    textStyle: WidgetStateTextStyle.resolveWith((states) {
      if (states.contains(WidgetState.focused)) {
        return const TextStyle(color: Colors.amber);
      } else {
        return const TextStyle(color: Colors.black);
      }
    }),
  );
}
