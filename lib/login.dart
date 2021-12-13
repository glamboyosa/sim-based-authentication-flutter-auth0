import 'package:flutter/material.dart';
import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

const String baseURL = '<YOUR-NGROK-URL>';

final FlutterAppAuth appAuth = FlutterAppAuth();

class Login extends StatefulWidget {
  const Login({Key? key}) : super(key: key);

  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        child: ListView(
          children: [
            Container(
                padding: const EdgeInsets.only(bottom: 45.0),
                margin: const EdgeInsets.only(top: 40),
                child: Image.asset(
                  'assets/images/tru-id-logo.png',
                  height: 100,
                )),
            Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 20),
                child: const Text(
                  'Login.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 30,
                  ),
                )),
          ],
        ),
      ),
    );
  }
}
