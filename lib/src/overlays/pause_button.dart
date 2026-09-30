import 'package:flutter/material.dart';

import 'package:nfc_between_worlds/src/constants/styled_button.dart';
import 'package:nfc_between_worlds/src/menu/main_menu.dart';
import 'package:nfc_between_worlds/src/provider/nfc_data_notifier.dart';
import 'package:nfc_between_worlds/src/test_game.dart';

class PauseButton extends StatelessWidget {
  const PauseButton({
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
          left: MediaQuery.of(context).size.width * 0.05,
          child: GestureDetector(
            onTap: () {
              game.pauseEngine();
              showDialog(
                barrierDismissible: false,
                context: context,
                builder: (BuildContext context) => ListenableBuilder(
                  listenable: nfcDataNotifier,
                  builder: (context, _) {
                    return PopScope(
                      canPop: false,
                      child: AlertDialog(
                        actionsAlignment: .spaceAround,
                        content: SizedBox(
                          height: 64,
                          child: Center(child: Text('Jeu en pause')),
                        ),
                        actions: <Widget>[
                          OutlinedButton(
                            style: StyledButton().overlayButtonStyle,
                            onPressed: () {
                              Navigator.pop(context, 'Quitter');
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => MainMenu(
                                    nfcDataNotifier: nfcDataNotifier,
                                  ),
                                ),
                              );
                            },
                            child: Text(
                              'Quitter',
                              style: TextStyle(color: Colors.black),
                            ),
                          ),
                          OutlinedButton(
                            style: StyledButton().overlayButtonStyle,
                            onPressed: () {
                              game.resumeEngine();
                              Navigator.pop(context, 'Reprendre');
                            },
                            child: Text(
                              'Reprendre',
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
            child: Center(
              child: Icon(
                Icons.pause,
                color: Colors.black,
                size: 40,
                shadows: [
                  Shadow(
                    color: Colors.white,
                    blurRadius: 0,
                    offset: .fromDirection(90, 2),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
