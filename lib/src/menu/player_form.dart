import 'package:flutter/material.dart';

class PlayerForm extends StatefulWidget {
  const PlayerForm({
    super.key,
    required this.initGame,
    required this.characterSaveData,
  });

  final Function initGame;
  final Map<String, dynamic> characterSaveData;

  @override
  State<PlayerForm> createState() => _PlayerFormState();
}

class _PlayerFormState extends State<PlayerForm> {
  final _form = GlobalKey<FormState>();
  final _textController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _saveForm(String playerName) {
    final isValid = _form.currentState?.validate();
    if (!isValid!) {
      return;
    }
    widget.characterSaveData['characterName'] = playerName;
    widget.initGame(widget.characterSaveData);
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _form,
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
        onFieldSubmitted: (value) => _saveForm(value),
      ),
    );
  }
}
