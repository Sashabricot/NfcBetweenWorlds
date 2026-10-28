import 'package:hive_flutter/hive_flutter.dart';
import 'package:nfc_between_worlds/src/models/leaderboard_record.dart';

class HiveService {
  Future<void> initializeHive() async {
    await Hive.initFlutter();
    Hive.registerAdapter(LeaderboardRecordAdapter());
    await Hive.openBox<LeaderboardRecord>('leaderboardRecord');
  }

  Box<LeaderboardRecord> getLeaderboardRecordBox() {
    return Hive.box<LeaderboardRecord>('leaderboardRecord');
  }
}

class LeaderboardRecordAdapter extends TypeAdapter<LeaderboardRecord> {
  @override
  int get typeId => 0;

  @override
  LeaderboardRecord read(BinaryReader reader) {
    return LeaderboardRecord(
      id: reader.read(),
      name: reader.read(),
      time: reader.read(),
    );
  }

  @override
  void write(BinaryWriter writer, LeaderboardRecord obj) {
    writer.write(obj.id);
    writer.write(obj.name);
    writer.write(obj.time);
  }
}
