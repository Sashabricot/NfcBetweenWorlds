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
        child: Stack(
          children: [
            ColorFiltered(
              colorFilter: ColorFilter.matrix([
                1,
                0,
                0,
                0,
                -35,
                0,
                1,
                0,
                0,
                -35,
                0,
                0,
                1,
                0,
                -35,
                0,
                0,
                0,
                1,
                0,
              ]),
              child: Image(
                fit: .cover,
                filterQuality: .none,

                image: AssetImage('assets/images/background.png'),
                height: MediaQuery.of(context).size.height,
                width: MediaQuery.of(context).size.width,
              ),
            ),
            Center(
              child: Column(
                mainAxisAlignment: .center,
                mainAxisSize: .max,
                crossAxisAlignment: .center,

                children: [
                  Text(
                    textAlign: .center,
                    'Félicitations $playerName',
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
                  SizedBox(height: 24),
                  Text(
                    textAlign: .center,
                    'Tu as terminé le jeu en ${minutes.truncate()} minutes et ${tenthSeconds.truncate()}$seconds secondes',
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
                  SizedBox(height: 24),
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
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
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
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
