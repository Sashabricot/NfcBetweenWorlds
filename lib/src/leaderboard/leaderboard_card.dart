import 'package:flutter/material.dart';
import 'package:nfc_between_worlds/src/models/leaderboard_record.dart';

class LeaderboardCard extends StatelessWidget {
  const LeaderboardCard({super.key, required this.record, required this.index});

  final LeaderboardRecord record;
  final int index;
  @override
  Widget build(BuildContext context) {
    final double minutes = record.time / 60;
    final double tenthSeconds =
        ((minutes - minutes.truncate()) * 60).round() / 10;
    final int seconds = ((tenthSeconds - tenthSeconds.truncate()) * 10)
        .truncate();

    late final Image image;

    switch (index) {
      case 1:
        image = Image(
          filterQuality: .none,
          image: AssetImage('assets/images/golden_cup.png'),
          width: 20,
        );
      case 2:
        image = Image(
          filterQuality: .none,
          image: AssetImage('assets/images/silver_cup.png'),
          width: 20,
        );
      case 3:
        image = Image(
          filterQuality: .none,
          image: AssetImage('assets/images/bronze_cup.png'),
          width: 20,
        );
    }

    return SizedBox(
      height: index <= 3 ? 52 : 36,
      child: Card(
        color: Colors.transparent,
        shadowColor: Colors.transparent,
        child: ListTile(
          leading: index <= 3
              ? image
              : Text(
                  index.toString(),
                  style: TextStyle(
                    color: Colors.black,
                    fontFamily: 'Pixel',
                    fontWeight: .w400,
                  ),
                ),
          title: Text(
            record.name,
            maxLines: 1,
            overflow: .ellipsis,
            style: TextStyle(
              color: Colors.black,
              fontFamily: 'Pixel',
              fontWeight: .w400,
              fontSize: 10,
            ),
          ),
          trailing: Row(
            mainAxisSize: .min,
            children: [
              Image(
                image: AssetImage('assets/images/timer.png'),
                filterQuality: .none,
                width: 20,
              ),
              SizedBox(width: 4),
              SizedBox(
                width: 40,
                child: FittedBox(
                  fit: .contain,
                  child: Text(
                    '${minutes.truncate()}:${tenthSeconds.truncate()}$seconds',

                    style: TextStyle(
                      color: Colors.black,
                      fontFamily: 'Pixel',
                      fontWeight: .w400,
                      fontSize: 8,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
