import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutterauth0subscribercheck/models.dart';
import 'package:http/http.dart' as http;
import 'package:tru_sdk_flutter/tru_sdk_flutter.dart';
import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

const String baseURL = '<YOUR-NGROK-URL>';

final FlutterAppAuth appAuth = FlutterAppAuth();

class Login extends StatefulWidget {
  const Login({Key? key}) : super(key: key);

  @override
  _LoginState createState() => _LoginState();
}

Future<SubscriberCheck?> createSubscriberCheck(String phoneNumber) async {
  final response = await http.post(Uri.parse('$baseURL/subscriber-check'),
      body: {"phone_number": phoneNumber});

  if (response.statusCode != 200) {
    return null;
  }
  final String data = response.body;
  return subscriberCheckFromJSON(data);
}

Future<SubscriberCheckResult?> getSubscriberCheck(String checkId) async {
  final response =
      await http.get(Uri.parse('$baseURL/subscriber-check/$checkId'));

  if (response.statusCode != 200) {
    return null;
  }

  final String data = response.body;
  return subscriberCheckResultFromJSON(data);
}

Future<void> errorHandler(BuildContext context, String title, String content) {
  return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context, 'Cancel'),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, 'OK'),
              child: const Text('OK'),
            ),
          ],
        );
      });
}

Future<void> successHandler(BuildContext context) {
  return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Login Successful.'),
          content: const Text('✅'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context, 'Cancel'),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, 'OK'),
              child: const Text('OK'),
            ),
          ],
        );
      });
}

class _LoginState extends State<Login> {
  String phoneNumber = '';
  bool loading = false;

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
            Container(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
                child: TextField(
                  keyboardType: TextInputType.phone,
                  onChanged: (text) {
                    setState(() {
                      phoneNumber = text;
                    });
                  },
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Enter your phone number.',
                  ),
                ),
              ),
            ),
            Container(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                child: TextButton(
                    onPressed: () async {
                      setState(() {
                        loading = true;
                      });

                      TruSdkFlutter sdk = TruSdkFlutter();

                      String? reachabilityInfo = await sdk.isReachable();

                      print("-------------REACHABILITTY RESULT --------------");
                      print(reachabilityInfo);
                      ReachabilityDetails? reachabilityDetails;
                      if (reachabilityInfo != null) {
                        reachabilityDetails = json.decode(reachabilityInfo);
                      }

                      if (reachabilityDetails?.error?.status == 400) {
                        setState(() {
                          loading = false;
                        });
                        return errorHandler(context, "Something Went Wrong.",
                            "Mobile Operator not supported.");
                      }
                      bool isSubscriberCheckSupported = true;

                      if (reachabilityDetails?.error?.status != 412) {
                        isSubscriberCheckSupported = false;

                        for (var products in reachabilityDetails!.products!) {
                          if (products.productName == "Subscriber Check") {
                            isSubscriberCheckSupported = true;
                          }
                        }
                      } else {
                        isSubscriberCheckSupported = true;
                      }

                      if (isSubscriberCheckSupported) {
                        final SubscriberCheck? subscriberCheckResponse =
                            await createSubscriberCheck(phoneNumber);
                        if (subscriberCheckResponse == null) {
                          setState(() {
                            loading = false;
                          });
                          return errorHandler(context, 'Something went wrong.',
                              'Phone number not supported');
                        }
                        // open check URL

                        String? result =
                            await sdk.check(subscriberCheckResponse.checkUrl);

                        if (result == null) {
                          setState(() {
                            loading = false;
                          });
                          return errorHandler(context, "Something went wrong.",
                              "Failed to open Check URL.");
                        }

                        final SubscriberCheckResult? subscriberCheckResult =
                            await getSubscriberCheck(
                                subscriberCheckResponse.checkId);

                        if (subscriberCheckResult == null) {
                          // return dialog
                          setState(() {
                            loading = false;
                          });
                          return errorHandler(context, 'Something Went Wrong.',
                              'Please contact support.');
                        }

                        if (subscriberCheckResult.match &&
                            subscriberCheckResult.simChanged == false) {
                          // proceed with Auth0 Auth

                          final AuthorizationTokenResponse?
                              result = await appAuth.authorizeAndExchangeCode(
                                  AuthorizationTokenRequest(
                                      dotenv.env["AUTH0_CLIENT_ID"]!,
                                      dotenv.env["AUTH0_REDIRECT_URI"]!,
                                      issuer: dotenv.env["AUTH0_ISSUER"]!,
                                      scopes: [
                                'openid',
                                'profile',
                                'offline_access'
                              ],
                                      promptValues: [
                                'login'
                              ]));

                          if (result?.idToken != null) {
                            setState(() {
                              loading = false;
                            });

                            return successHandler(context);
                          } else {
                            setState(() {
                              loading = false;
                            });

                            return errorHandler(
                                context,
                                "Something went wrong.",
                                "Unable to login. Please try again later");
                          }
                        }
                      } else {
                        // proceed with Auth0 Auth

                        final AuthorizationTokenResponse? result = await appAuth
                            .authorizeAndExchangeCode(AuthorizationTokenRequest(
                                dotenv.env["AUTH0_CLIENT_ID"]!,
                                dotenv.env["AUTH0_REDIRECT_URI"]!,
                                issuer: dotenv.env["AUTH0_ISSUER"]!,
                                scopes: ['openid', 'profile', 'offline_access'],
                                promptValues: ['login']));

                        if (result?.idToken != null) {
                          setState(() {
                            loading = false;
                          });

                          return successHandler(context);
                        } else {
                          setState(() {
                            loading = false;
                          });

                          return errorHandler(context, "Something went wrong.",
                              "Unable to login. Please try again later");
                        }
                      }
                    },
                    child: loading
                        ? const CircularProgressIndicator()
                        : const Text('Login')),
              ),
            )
          ],
        ),
      ),
    );
  }
}
