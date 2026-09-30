import 'dart:async';

import 'package:flutter/material.dart';
import 'package:nfc_between_worlds/src/constants/styled_button.dart';
import 'package:nfc_between_worlds/src/provider/nfc_data_notifier.dart';
import 'package:nfc_between_worlds/src/test_game.dart';

class SaveButton extends StatelessWidget {
  const SaveButton({
    super.key,
    required this.game,
    required this.nfcDataNotifier,
  });

  final NfcDataNotifier nfcDataNotifier;
  final TestGame game;
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: MediaQuery.of(context).padding.top,
          right: MediaQuery.of(context).size.width * 0.05,
          child: GestureDetector(
            onTap: () {
              Completer stopNfcWriting = Completer();
              game.pauseEngine();
              game.savePlayerDataOnNfc(stopNfcWriting: stopNfcWriting);
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
                            child: nfcDataNotifier.isProcessing
                                ? CircularProgressIndicator()
                                : Text(nfcDataNotifier.nfcSaveMessage),
                          ),
                        ),
                        actions: <Widget>[
                          nfcDataNotifier.isProcessing
                              ? OutlinedButton(
                                  style: StyledButton().overlayButtonStyle,
                                  onPressed: () async {
                                    Navigator.pop(context, 'Annuler');
                                    stopNfcWriting.complete();
                                    game.resumeEngine();
                                  },
                                  child: Text('Annuler'),
                                )
                              : OutlinedButton(
                                  style: StyledButton().overlayButtonStyle,
                                  onPressed: () {
                                    Navigator.pop(context, 'Terminer');
                                    game.resumeEngine();
                                  },
                                  child: Text(
                                    'Terminer',
                                    style: TextStyle(color: Colors.black),
                                  ),
                                ),
                        ],
                      ),
                    );
                  },
                ),
              );
            },
            child: Container(
              height: 48,
              width: 48,
              decoration: BoxDecoration(
                color: Color.fromARGB(255, 202, 100, 4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange, width: 2),
              ),
              child: Center(child: Icon(Icons.save, color: Colors.black)),
            ),
          ),
        ),
      ],
    );
  }
}
