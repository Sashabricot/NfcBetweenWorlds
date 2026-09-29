import 'package:flutter/material.dart';
import 'package:nfc_between_worlds/src/menu/splash_screen_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized;
  runApp(
    MaterialApp(home: SplashScreenPage(), debugShowCheckedModeBanner: false),
  );
}
