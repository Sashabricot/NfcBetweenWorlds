import 'package:flutter/material.dart';
import 'package:flutter_gamepads/flutter_gamepads.dart';

import 'package:nfc_between_worlds/src/leaderboard/hive_service.dart';
import 'package:nfc_between_worlds/src/menu/splash_screen_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized;
  await HiveService().initializeHive();

  // for (var record in testLeaderboardRecords) {
  //   HiveService().getLeaderboardRecordBox().put(record.id, record);
  // }

  runApp(
    const GamepadControl(
      child: MaterialApp(
        home: SplashScreenPage(),
        debugShowCheckedModeBanner: false,
      ),
    ),
  );
}
