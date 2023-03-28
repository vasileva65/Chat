import 'package:flutter/material.dart';
import 'package:client/widgets/chat.dart';
import 'package:client/widgets/chat_list.dart';
import 'package:client/models/auth.dart';

class MainScreen extends StatefulWidget {
  Auth auth;

  MainScreen(this.auth);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
          child: Row(
        children: [
          SafeArea(child: Container(width: 300, child: ChatList())),
          const VerticalDivider(
            color: Color.fromARGB(255, 194, 194, 194),
            thickness: 1,
            width: 0.5,
          ),
          Expanded(child: Container(width: 600, child: ChatPage(widget.auth))),
        ],
      )),
    );
  }
}
