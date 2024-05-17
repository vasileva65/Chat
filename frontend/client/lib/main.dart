import 'package:client/widgets/password_reset.dart';
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
import 'package:window_size/window_size.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    setWindowTitle('Chat');
    setWindowMinSize(const Size(750, 500));
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
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
    );
  }
}
