import 'package:client/models/userProfile.dart';
import 'package:flutter/material.dart';
import 'package:client/widgets/chat.dart';
import 'package:client/widgets/chat_list.dart';
import 'package:client/models/auth.dart';

import '../dialogs/mainscreen_dialogs.dart';
import '../models/chats.dart';
import 'zero_page.dart';

typedef UpdateChatData = void Function(Chats updateChatData);

class MainScreen extends StatefulWidget {
  Auth auth;
  UserProfile userData;

  MainScreen(this.auth, this.userData,
      {super.key, required this.chat, this.showUsernameDialog = false});
  Chats chat;
  bool showUsernameDialog;

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.showUsernameDialog) {
        MainScreenDialogs.usernameDialog(context, widget.userData);
        // Устанавливаем флаг в false, чтобы не показывать диалог в будущем
        setState(() {
          widget.showUsernameDialog = false;
        });
      }
    });
  }

  void updateUserData(UserProfile updatedUserData) {
    setState(() {
      widget.userData = updatedUserData;
    });
  }

  void updateChatData(Chats updatedChatData) {
    setState(() {
      widget.chat = updatedChatData;
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
                    updateUserData: updateUserData,
                    onChatUpdated: (chatId, name, avatar, membersCount, adminId,
                        isGroupChat) {
                      setState(() {
                        print("MAIN PAGE CHAT LIST CALLED");
                        widget.chat = Chats(chatId, name, avatar, membersCount,
                            adminId, isGroupChat);
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
                          key: ValueKey<int>(widget.chat.membersCount),
                          widget.auth,
                          widget.userData,
                          widget.chat,
                          updateChatData: updateChatData,
                          onChatUpdated: (chatId, name, avatar, membersCount,
                              adminId, isGroupChat) {
                            setState(() {
                              widget.chat = Chats(chatId, name, avatar,
                                  membersCount, adminId, isGroupChat);
                            });
                          },
                          updateMembersCount: (updatedMembersCount) {},
                        )
                      : ZeroPage(widget.auth, widget.userData))),
        ],
      )),
    );
  }
}
