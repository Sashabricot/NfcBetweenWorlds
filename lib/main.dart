import 'package:flutter/material.dart';
import 'package:flutter_gamepads/flutter_gamepads.dart';
import 'package:nfc_between_worlds/src/menu/splash_screen_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized;
  runApp(
    const GamepadControl(
      child: MaterialApp(
        home: SplashScreenPage(),
        debugShowCheckedModeBanner: false,
      ),
    ),
  );
}
