import 'package:client/models/userProfile.dart';
import 'package:flutter/material.dart';
import 'package:client/widgets/chat.dart';
import 'package:client/widgets/chat_list.dart';
import 'package:client/models/auth.dart';

import '../models/chats.dart';
import 'zero_page.dart';

class MainScreen extends StatefulWidget {
  Auth auth;
  UserProfile userData;
  MainScreen(this.auth, this.userData, {super.key, required this.chat});
  Chats chat;
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  @override
  Widget build(BuildContext context) {
    print('build called');
    print(widget.chat.chatId);
    return Scaffold(
      body: Container(
          child: Row(
        children: [
          SafeArea(
              child: Container(
                  width: 300,
                  child: ChatList(
                    widget.auth,
                    widget.userData,
                    widget.chat,
                    onChatUpdated: (chatId) {
                      setState(() {
                        widget.chat = Chats(chatId, 'new name', '');
                      });
                    },
                  ))),
          Expanded(
              child: Container(
                  decoration: const BoxDecoration(
                      border: Border(
                          left: BorderSide(
                              width: 0.2,
                              color: Color.fromARGB(255, 0, 0, 0)))),
                  width: 600,
                  child: widget.chat.chatId != 0
                      ? ChatPage(
                          key: ValueKey(widget.chat.chatId),
                          widget.auth,
                          widget.userData,
                          widget.chat)
                      : ZeroPage(widget.auth))),
        ],
      )),
    );
  }
}
