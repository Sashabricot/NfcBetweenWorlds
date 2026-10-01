import 'dart:async';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import 'package:nfc_between_worlds/src/overlays/pause_button.dart';
import 'package:nfc_between_worlds/src/overlays/save_button.dart';
import 'package:nfc_between_worlds/src/provider/nfc_data_notifier.dart';
import 'package:nfc_between_worlds/src/test_game.dart';

class MainMenu extends StatelessWidget {
  const MainMenu({super.key, required this.nfcDataNotifier});
  final NfcDataNotifier nfcDataNotifier;

  @override
  Widget build(BuildContext context) {
    nfcDataNotifier.blockSystemNfc();

    Future<void> loadGame(Map<String, dynamic>? characterSaveData) async {
      if (nfcDataNotifier.error == null && characterSaveData != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PopScope(
              canPop: false,
              child: GameWidget<TestGame>.controlled(
                gameFactory: () {
                  return TestGame(
                    nfcDataNotifier: nfcDataNotifier,
                    characterPosition: characterSaveData['characterPosition'],
                    slimeType: characterSaveData['nfcType'],
                    level: characterSaveData['level'],
                    characterItems: characterSaveData['items'],
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

                initialActiveOverlays: const ['SaveButton', 'PauseButton'],
              ),
            ),
          ),
        );
      }
    }

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          alignment: AlignmentGeometry.center,
          children: [
            Positioned(
              top: MediaQuery.of(context).size.height * 0.25,
              child: Text(
                'NFC Between Worlds',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 24,
                  fontWeight: .bold,
                ),
              ),
            ),

            Positioned(
              top: MediaQuery.of(context).size.height * 0.65,
              child: Center(
                child: Column(
                  crossAxisAlignment: .center,
                  children: [
                    TextButton(
                      onPressed: () async {
                        Completer stopNfcSaveReading = Completer();
                        nfcDataNotifier
                            .loadNfcSave(
                              startNewGame: false,
                              stopNfcSaveReading: stopNfcSaveReading,
                              nfcDataNotifier: nfcDataNotifier,
                            )
                            .then(
                              (characterSaveData) =>
                                  loadGame(characterSaveData),
                            );
                        showDialog(
                          barrierDismissible: false,
                          context: context,
                          builder: (BuildContext context) => ListenableBuilder(
                            listenable: nfcDataNotifier,
                            builder: (context, _) {
                              return PopScope(
                                canPop: false,
                                child: AlertDialog(
                                  content: SizedBox(
                                    height: 64,
                                    child: Center(
                                      child: nfcDataNotifier.error == null
                                          ? CircularProgressIndicator()
                                          : Text(
                                              nfcDataNotifier.error.toString(),
                                            ),
                                    ),
                                  ),
                                  actions: <Widget>[
                                    nfcDataNotifier.error == null
                                        ? TextButton(
                                            onPressed: () async {
                                              Navigator.pop(context, 'Annuler');
                                              stopNfcSaveReading.complete();
                                            },
                                            child: Text('Annuler'),
                                          )
                                        : TextButton(
                                            onPressed: () async {
                                              Navigator.pop(
                                                context,
                                                'Confirmer',
                                              );
                                            },
                                            child: Text('Confirmer'),
                                          ),
                                  ],
                                ),
                              );
                            },
                          ),
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(),
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.black,
                        ),
                        width: 256,
                        height: 44,
                        child: Center(
                          child: Text(
                            'Jouer',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                    // TextButton(
                    //   onPressed: () {
                    //     Completer stopNfcSaveReading = Completer();
                    //     nfcDataNotifier.loadNfcSave(
                    //       context: context,
                    //       startNewGame: true,
                    //       stopNfcSaveReading: stopNfcSaveReading,
                    //       nfcDataNotifier: nfcDataNotifier,
                    //     );
                    //   },
                    //   child: Container(
                    //     decoration: BoxDecoration(
                    //       border: Border.all(),
                    //       borderRadius: BorderRadius.circular(8),
                    //       color: Colors.black,
                    //     ),

                    //     width: 256,
                    //     height: 44,
                    //     child: Center(
                    //       child: Text(
                    //         'Nouvelle Partie',
                    //         style: TextStyle(color: Colors.white),
                    //       ),
                    //     ),
                    //   ),
                    // ),
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
