import 'dart:async';

import 'package:client/widgets/login_page.dart';
import 'package:client/widgets/password_reset.dart';

import 'package:client/widgets/set_new_password.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';
import 'dart:io';
import 'package:client/widgets/chat.dart';
import 'package:client/widgets/main_screen.dart';
import 'package:uni_links/uni_links.dart';
import 'package:window_size/window_size.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    setWindowTitle('Chat');
    setWindowMinSize(const Size(750, 500));
  }

  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  StreamSubscription? _sub;

  @override
  void initState() {
    super.initState();
    initUniLinks();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> initUniLinks() async {
    try {
      _sub = getUriLinksStream().listen((Uri? uri) {
        if (uri != null) {
          _handleDeepLink(uri);
        }
      }, onError: (err) {
        // Handle error
      });

      Uri? initialUri = await getInitialUri();
      if (initialUri != null) {
        _handleDeepLink(initialUri);
      }
    } catch (e) {
      // Handle exception
    }
  }

  void _handleDeepLink(Uri uri) {
    // Handle your deep link here
    if (uri.pathSegments.contains('reset-password-confirm')) {
      String uidb64 = uri.pathSegments[1];
      String token = uri.pathSegments[2];
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              SetNewPasswordPage(uidb64: uidb64, token: token),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chat',
      theme: ThemeData(
        fontFamily: 'Rubik',
        primarySwatch: Colors.blue,
        colorScheme:
            ColorScheme.fromSeed(seedColor: Color.fromARGB(255, 37, 87, 153)),
      ),
      home: LoginPage(),
      routes: {
        '/request-password-reset': (context) => PasswordResetRequestPage(),
        '/set-new-password': (context) => SetNewPasswordPage(
            uidb64: '',
            token:
                ''), // Для простоты, но uidb64 и token должны быть переданы из URL
      },
    );
  }
}
