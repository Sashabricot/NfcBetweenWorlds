import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nfc_between_worlds/src/menu/auth/auth_form.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _auth = FirebaseAuth.instance;

  var _isLoading = false;

  void _submitAuthForm(
    String email,
    String password,
    BuildContext context,
  ) async {
    try {
      setState(() {
        _isLoading = true;
      });
      await _auth.signInWithEmailAndPassword(email: email, password: password);
    } on PlatformException catch (error) {
      var message = 'An error occured, please check your credentials!';
      if (error.message != null) {
        message = error.message!;
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
      setState(() {
        _isLoading = false;
      });
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text((error as FirebaseAuthException).message.toString()),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: AuthForm(_submitAuthForm, _isLoading),
    );
  }
}
