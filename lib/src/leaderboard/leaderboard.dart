import 'package:flutter/material.dart';
// import 'package:nfc_between_worlds/src/constants/test_leaderboard_records.dart';
import 'package:nfc_between_worlds/src/leaderboard/hive_service.dart';
import 'package:nfc_between_worlds/src/leaderboard/leaderboard_card.dart';

class Leaderboard extends StatelessWidget {
  const Leaderboard({super.key});

  @override
  Widget build(BuildContext context) {
    final leaderboardList = HiveService()
        .getLeaderboardRecordBox()
        .values
        .toList();
    leaderboardList.sort(
      (record, record2) => record.time.compareTo(record2.time),
    );
    return Container(
      padding: .only(top: 180, left: 60, right: 60, bottom: 120),
      decoration: BoxDecoration(
        image: DecorationImage(
          filterQuality: .none,
          fit: .fitWidth,
          image: AssetImage('assets/images/leaderboard.png'),
        ),
      ),
      child: ListView.builder(
        padding: .zero,
        itemCount: leaderboardList.length,
        itemBuilder: ((context, index) =>
            LeaderboardCard(record: leaderboardList[index], index: index + 1)),
      ),
    );
  }
}
