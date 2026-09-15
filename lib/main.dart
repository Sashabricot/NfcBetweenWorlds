import 'package:flame/game.dart';
import 'package:flutter/widgets.dart';
import 'package:klondike/src/test_game.dart';

void main() {
  runApp(GameWidget(game: TestGame(),));
}
