import 'package:flame_splash_screen/flame_splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:nfc_between_worlds/src/menu/main_menu.dart';
import 'package:nfc_between_worlds/src/provider/nfc_data_notifier.dart';

class SplashScreenPage extends StatefulWidget {
  const SplashScreenPage({super.key});

  @override
  State<SplashScreenPage> createState() => _SplashScreenPageState();
}

class _SplashScreenPageState extends State<SplashScreenPage> {
  final NfcDataNotifier nfcDataNotifier = NfcDataNotifier();
  @override
  Widget build(BuildContext context) {
    nfcDataNotifier.blockSystemNfc();
    return Scaffold(
      body: FlameSplashScreen(
        onFinish: (BuildContext context) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => MainMenu(nfcDataNotifier: nfcDataNotifier),
            ),
          );
        },
        theme: FlameSplashTheme.dark,
      ),
    );
  }
}
