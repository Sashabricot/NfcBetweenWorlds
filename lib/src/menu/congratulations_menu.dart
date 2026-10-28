import 'package:flutter/material.dart';
import 'package:nfc_between_worlds/src/menu/main_menu.dart';
import 'package:nfc_between_worlds/src/provider/nfc_data_notifier.dart';

class CongratulationsMenu extends StatelessWidget {
  const CongratulationsMenu({
    super.key,
    required this.nfcDataNotifier,
    required this.playerName,
    required this.time,
  });
  final String playerName;
  final NfcDataNotifier nfcDataNotifier;
  final int time;
  @override
  Widget build(BuildContext context) {
    nfcDataNotifier.blockSystemNfc();
    final double minutes = time / 60;
    final double tenthSeconds =
        ((minutes - minutes.truncate()) * 60).round() / 10;
    final int seconds = ((tenthSeconds - tenthSeconds.truncate()) * 10)
        .truncate();

    return Scaffold(
      body: SizedBox.expand(
        child: Column(
          mainAxisAlignment: .center,
          mainAxisSize: .max,
          crossAxisAlignment: .center,

          children: [
            Text('Félicitations $playerName'),
            Text(
              'Tu as terminé le jeu en ${minutes.truncate()} minutes et ${tenthSeconds.truncate()}$seconds secondes',
            ),
            TextButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PopScope(
                      canPop: false,
                      child: MainMenu(nfcDataNotifier: nfcDataNotifier),
                    ),
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
                    'Classement',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
