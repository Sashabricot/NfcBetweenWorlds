import 'dart:async';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:nfc_between_worlds/src/leaderboard/leaderboard.dart';
import 'package:nfc_between_worlds/src/menu/player_form.dart';

import 'package:nfc_between_worlds/src/overlays/pause_button.dart';
import 'package:nfc_between_worlds/src/overlays/save_button.dart';
import 'package:nfc_between_worlds/src/provider/nfc_data_notifier.dart';
import 'package:nfc_between_worlds/src/test_game.dart';

class MainMenu extends StatelessWidget {
  const MainMenu({super.key, required this.nfcDataNotifier});
  final NfcDataNotifier nfcDataNotifier;

  @override
  Widget build(BuildContext context) {
    Completer stopNfcSaveReading = Completer();

    void initGame(Map<String, dynamic> characterSaveData) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => PopScope(
            canPop: false,
            child: GameWidget<TestGame>.controlled(
              gameFactory: () {
                return TestGame(
                  characterName: characterSaveData['characterName'] ??= 'test',
                  nfcDataNotifier: nfcDataNotifier,
                  characterPosition: characterSaveData['characterPosition'],
                  slimeType: characterSaveData['nfcType'],
                  level: characterSaveData['level'],
                  characterItems: characterSaveData['items'],
                  savedBoxesPosition: characterSaveData['boxesPosition'],
                  playerTimer: characterSaveData['playerTimer'],
                );
              },
              overlayBuilderMap: {
                'SaveButton': (_, game) =>
                    SaveButton(game: game, nfcDataNotifier: nfcDataNotifier),
                'PauseButton': (_, game) =>
                    PauseButton(game: game, nfcDataNotifier: nfcDataNotifier),
              },
              loadingBuilder: (context) =>
                  Center(child: CircularProgressIndicator()),

              // initialActiveOverlays: const ['SaveButton', 'PauseButton'],
              initialActiveOverlays: const ['SaveButton'],
            ),
          ),
        ),
      );
    }

    Future<void> loadGame(Map<String, dynamic>? characterSaveData) async {
      if (nfcDataNotifier.error == null && characterSaveData != null) {
        if (characterSaveData['characterName'] == null) {
          showDialog(
            barrierDismissible: false,
            context: context,
            builder: (context) => PopScope(
              canPop: false,
              child: AlertDialog(
                title: Text('Choisissez un nom de joueur'),
                content: SizedBox(
                  height: 64,
                  child: PlayerForm(
                    initGame: initGame,
                    characterSaveData: characterSaveData,
                  ),
                ),
                actions: <Widget>[
                  TextButton(
                    onPressed: () async {
                      Navigator.pop(context, 'Annuler');
                      stopNfcSaveReading = Completer();
                      nfcDataNotifier
                          .loadNfcSave(
                            startNewGame: false,
                            stopNfcSaveReading: stopNfcSaveReading,
                            nfcDataNotifier: nfcDataNotifier,
                          )
                          .then(
                            (characterSaveData) => loadGame(characterSaveData),
                          );
                    },
                    child: Text('Annuler'),
                  ),
                ],
              ),
            ),
          );
        } else {
          initGame(characterSaveData);
        }
      } else {
        stopNfcSaveReading = Completer();
        nfcDataNotifier
            .loadNfcSave(
              startNewGame: false,
              stopNfcSaveReading: stopNfcSaveReading,
              nfcDataNotifier: nfcDataNotifier,
            )
            .then((characterSaveData) => loadGame(characterSaveData));
      }
    }

    nfcDataNotifier
        .loadNfcSave(
          startNewGame: false,
          stopNfcSaveReading: stopNfcSaveReading,
          nfcDataNotifier: nfcDataNotifier,
        )
        .then((characterSaveData) => loadGame(characterSaveData));

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.white,

        body: Stack(
          alignment: AlignmentGeometry.center,
          children: [
            SingleChildScrollView(
              child: Image(
                fit: .cover,
                image: AssetImage('assets/images/background.png'),
                height: MediaQuery.of(context).size.height,
                width: MediaQuery.of(context).size.width,
              ),
            ),
            Positioned(
              top: MediaQuery.of(context).size.height * 0.15,
              child: Text(
                'NFC Between Worlds',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontFamily: 'Pixel',
                  shadows: <Shadow>[
                    Shadow(
                      offset: Offset(3.0, 3.0),
                      blurRadius: 3.0,
                      color: Color.fromARGB(255, 0, 0, 0),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height * 0.6,
              top:
                  MediaQuery.of(context).size.height / 2 -
                  MediaQuery.of(context).size.height * 0.3,
              child: Leaderboard(),
            ),
            Positioned(
              top: MediaQuery.of(context).size.height * 0.65,
              child: Center(
                child: Column(crossAxisAlignment: .center, children: [
              
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
