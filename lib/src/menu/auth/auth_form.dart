import 'package:flutter/material.dart';
import 'package:nfc_between_worlds/src/menu/splash_screen_page.dart';

class AuthForm extends StatefulWidget {
  const AuthForm(this.submitFunction, this.isLoading, {super.key});

  final bool isLoading;

  final void Function(String email, String username, BuildContext context)
  submitFunction;

  @override
  State<AuthForm> createState() => _AuthFormState();
}

class _AuthFormState extends State<AuthForm> {
  final _formKey = GlobalKey<FormState>();

  var _userEmail = '';
  var _userPassword = '';

  void _trySubmit() {
    final isValid = _formKey.currentState?.validate() ?? false;
    FocusScope.of(context).unfocus();

    if (isValid) {
      _formKey.currentState!.save();
      widget.submitFunction(_userEmail.trim(), _userPassword.trim(), context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Card(
        margin: EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Padding(
            padding: .all(16),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: .min,
                children: [
                  TextFormField(
                    keyboardType: .emailAddress,
                    decoration: InputDecoration(labelText: 'Email address'),
                    validator: (value) {
                      if (value!.isEmpty || !value.contains('@')) {
                        return 'Please enter a valid email address';
                      }
                      return null;
                    },
                    onSaved: (newValue) {
                      _userEmail = newValue ?? '';
                    },
                    key: ValueKey('email'),
                  ),
                  TextFormField(
                    decoration: InputDecoration(labelText: 'Password'),
                    obscureText: true,
                    validator: (value) {
                      if (value!.isEmpty || value.length < 7) {
                        return "Password must be at least 7 characters long";
                      }
                      return null;
                    },
                    onSaved: (newValue) {
                      _userPassword = newValue ?? '';
                    },
                    key: ValueKey('password'),
                  ),
                  SizedBox(height: 12),
                  widget.isLoading
                      ? CircularProgressIndicator()
                      : ElevatedButton(
                          onPressed: () {
                            _trySubmit();
                          },
                          child: Text('Login'),
                        ),
                  if (!widget.isLoading)
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (context) => SplashScreenPage(),
                          ),
                        );
                      },
                      child: Text('Play as Guest'),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
