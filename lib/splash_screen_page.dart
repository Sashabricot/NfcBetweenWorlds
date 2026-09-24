import 'package:flame/game.dart';
import 'package:flame_splash_screen/flame_splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:nfc_between_worlds/src/test_game.dart';

class SplashScreenPage extends StatefulWidget {
  const SplashScreenPage({super.key});

  @override
  State<SplashScreenPage> createState() => _SplashScreenPageState();
}

class _SplashScreenPageState extends State<SplashScreenPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FlameSplashScreen(
          onFinish: (BuildContext context) {
            Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (context) => GameWidget(game: TestGame())));
          },
          theme: FlameSplashTheme.dark),
    );
  }
}
