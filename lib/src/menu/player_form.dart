import 'package:flutter/material.dart';

class PlayerForm extends StatefulWidget {
  PlayerForm({
    super.key,
    required this.initGame,
    required this.characterSaveData,
  });

  final Function initGame;
  final Map<String, dynamic> characterSaveData;

  final _form = GlobalKey<FormState>();
  final _textController = TextEditingController();

  void saveForm() {
    final isValid = _form.currentState?.validate();
    if (!isValid!) {
      return;
    }
    characterSaveData['characterName'] = _textController.text.replaceAll(
      ' ',
      '',
    );
    initGame(characterSaveData);
  }

  @override
  State<PlayerForm> createState() => _PlayerFormState();
}

class _PlayerFormState extends State<PlayerForm> {
  @override
  void dispose() {
    widget._textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: widget._form,
      child: TextFormField(
        // autofocus: true,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Veuillez entrer votre nom de joueur';
          }
          if (value.length > 14) {
            return 'Nom de joueur trop long';
          }
          return null;
        },
        onFieldSubmitted: (value) => widget.saveForm(),
      ),
    );
  }
}
