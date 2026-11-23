import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gamepads/flutter_gamepads.dart';
import 'package:nfc_between_worlds/firebase_options.dart';
import 'package:nfc_between_worlds/src/constants/test_leaderboard_records.dart';

import 'package:nfc_between_worlds/src/leaderboard/hive_service.dart';
import 'package:nfc_between_worlds/src/menu/auth/auth_screen.dart';
import 'package:nfc_between_worlds/src/menu/splash_screen_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized;
  await HiveService().initializeHive();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  for (var record in testLeaderboardRecords) {
    HiveService().getLeaderboardRecordBox().put(record.id, record);
  }
  final auth = FirebaseAuth.instance;
  auth.signOut();
  runApp(
    GamepadControl(
      child: MaterialApp(
        home: StreamBuilder(
          stream: auth.authStateChanges(),
          builder: (context, userSnapShot) {
            if (userSnapShot.hasData) {
              return SplashScreenPage();
            }
            return AuthScreen();
          },
        ),
        debugShowCheckedModeBanner: false,
      ),
    ),
  );
}
