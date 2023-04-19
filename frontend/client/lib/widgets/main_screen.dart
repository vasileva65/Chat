import 'package:client/models/userProfile.dart';
import 'package:flutter/material.dart';
import 'package:client/widgets/chat.dart';
import 'package:client/widgets/chat_list.dart';
import 'package:client/models/auth.dart';

class MainScreen extends StatefulWidget {
  Auth auth;
  UserProfile userData;
  MainScreen(this.auth, this.userData);

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
          /*const VerticalDivider(
            color: Color.fromARGB(255, 163, 163, 163),
            thickness: 1,
            width: 0.5,
            //indent: 100,
          ),*/
          Expanded(
              child: Container(
                  decoration: const BoxDecoration(
                      border: Border(
                          left: BorderSide(
                              width: 0.2,
                              color: Color.fromARGB(255, 0, 0, 0)))),
                  width: 600,
                  child: ChatPage(widget.auth, widget.userData))),
        ],
      )),
    );
  }
}
