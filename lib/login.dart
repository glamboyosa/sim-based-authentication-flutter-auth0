import 'package:flutter/material.dart';
import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:tru_sdk_flutter/tru_sdk_flutter.dart';
import 'dart:convert';
import 'package:flutterauth0subscribercheck/models.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

const String baseURL = '<YOUR-NGROK-URL>';

final FlutterAppAuth appAuth = FlutterAppAuth();

class Login extends StatefulWidget {
  const Login({Key? key}) : super(key: key);

  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {
  String phoneNumber = '';
  bool loading = false;

  Future<SubscriberCheckResult> exchangeCode(
      String checkID, String code, String? referenceID) async {
    var body = jsonEncode(<String, String>{
      'code': code,
      'check_id': checkID,
      'reference_id': (referenceID != null) ? referenceID : ""
    });

    final response = await http.post(
      Uri.parse('$baseURL/v0.2/subscriber-check/exchange-code'),
      body: body,
      headers: <String, String>{
        'content-type': 'application/json; charset=UTF-8',
      },
    );
    print("response request ${response.request}");
    if (response.statusCode == 200) {
      SubscriberCheckResult exchangeCheckRes =
          SubscriberCheckResult.fromJson(jsonDecode(response.body));
      print("Exchange Check Result $exchangeCheckRes");
      if (exchangeCheckRes.match) {
        print("✅ successful SubscriberCheck match");
      } else {
        print("❌ failed SubscriberCheck match");
      }
      return exchangeCheckRes;
    } else {
      throw Exception('Failed to exchange Code');
    }
  }

  Future<void> errorHandler(
      BuildContext context, String title, String content) {
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
            title: const Text('Registration Successful.'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: TextButton(
              onPressed: () async {
                setState(() {
                  loading = true;
                });
                TruSdkFlutter sdk = TruSdkFlutter();
                bool isSubscriberCheckSupported = false;
                Map<Object?, Object?> reach = await sdk.openWithDataCellular(
                    "https://eu.api.tru.id/public/coverage/v0.1/device_ip",
                    false);
                print("isReachable = $reach");

                if (reach.containsKey("http_status") &&
                    reach["http_status"] != 200) {
                  if (reach["http_status"] == 400 ||
                      reach["http_status"] == 412) {
                    return errorHandler(context, "Something Went Wrong.",
                        "Mobile Operator not supported, or not a Mobile IP.");
                  }
                } else if (reach.containsKey("http_status") ||
                    reach["http_status"] == 200) {
                  Map body = reach["response_body"] as Map<dynamic, dynamic>;
                  Coverage coverage = Coverage.fromJson(body);

                  for (var product in coverage.products!) {
                    if (product.name == "Subscriber Check") {
                      isSubscriberCheckSupported = true;
                    }
                  }
                } else {
                  isSubscriberCheckSupported = true;
                }

                if (isSubscriberCheckSupported) {
                  final response = await http.post(
                      Uri.parse('$baseURL/v0.2/subscriber-check'),
                      body: {"phone_number": phoneNumber});

                  if (response.statusCode != 200) {
                    setState(() {
                      loading = false;
                    });

                    return errorHandler(context, 'Something went wrong.',
                        'Unable to create phone check');
                  }

                  SubscriberCheck checkDetails =
                      SubscriberCheck.fromJson(jsonDecode(response.body));

                  Map result =
                      await sdk.openWithDataCellular(checkDetails.url, false);
                  print("openWithDataCellular Results -> $result");

                  if (result.containsKey("error")) {
                    setState(() {
                      loading = false;
                    });

                    errorHandler(context, "Something went wrong.",
                        "Failed to open Check URL.");
                  }

                  if (result.containsKey("http_status") &&
                      result["http_status"] == 200) {
                    Map body = result["response_body"] as Map<dynamic, dynamic>;
                    if (body["code"] != null) {
                      CheckSuccessBody successBody =
                          CheckSuccessBody.fromJson(body);

                      try {
                        SubscriberCheckResult exchangeResult =
                            await exchangeCode(successBody.checkId,
                                successBody.code, successBody.referenceId);

                        if (exchangeResult.match &&
                            exchangeResult.noSimChange) {
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
                        } else {
                          setState(() {
                            loading = false;
                          });

                          return errorHandler(context, "Something went wrong.",
                              "Unable to login. Please try again later");
                        }
                      } catch (error) {
                        setState(() {
                          loading = false;
                        });

                        return errorHandler(context, "Something went wrong.",
                            "Unable to login. Please try again later");
                      }
                    }
                  }
                } else {
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
                  : const Text('Login'),
            ),
          )
        ],
      ),
    );
  }
}
