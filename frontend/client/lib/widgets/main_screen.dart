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
  void usernameDialog(BuildContext context, UserProfile userData) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Добро пожаловать в корпоративный чат!',
          textAlign: TextAlign.center,
        ),
        content: SingleChildScrollView(
          child: Column(
            children: [
              const Text(
                'Ваше имя пользователя:',
                textAlign: TextAlign.center,
              ),
              Text(
                userData.username,
                textAlign: TextAlign.center,
              ),
              const Text(
                'Пожалуйста, запомните его для дальнейшего \nвхода в приложение',
                textAlign: TextAlign.center,
              )
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            style: TextButton.styleFrom(
              padding: const EdgeInsets.all(16.0),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            onPressed: () => Navigator.pop(context, 'Понятно'),
            child: const Text('Понятно'),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      usernameDialog(context, widget.userData);
    });
  }

  @override
  Widget build(BuildContext context) {
    print('build called');
    print(widget.userData);
    print(widget.userData.name);
    print(widget.userData.lastname);
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
                    onChatUpdated: (chatId, name, avatar, membersCount) {
                      setState(() {
                        widget.chat = Chats(chatId, name, avatar, membersCount);
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
                      : ZeroPage(widget.auth, widget.userData))),
        ],
      )),
    );
  }
}
