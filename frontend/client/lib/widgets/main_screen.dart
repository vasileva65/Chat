import 'package:client/models/userProfile.dart';
import 'package:flutter/material.dart';
import 'package:client/widgets/chat.dart';
import 'package:client/widgets/chat_list.dart';
import 'package:client/models/auth.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:windows_taskbar/windows_taskbar.dart';

import '../dialogs/mainscreen_dialogs.dart';
import '../models/chat.dart';
import 'zero_page.dart';

typedef UpdateChatData = void Function(Chat updateChatData);

class MainScreen extends StatefulWidget {
  Auth auth;
  UserProfile userData;

  Set<String> updatedChats = {};

  MainScreen(this.auth, this.userData,
      {super.key, required this.chat, this.showUsernameDialog = false});
  Chat chat;
  bool showUsernameDialog;

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final _channel =
      WebSocketChannel.connect(Uri.parse('ws://localhost:8080/ws'));
  bool chatListReloadNeeded = false;
  bool chatReloadNeeded = false;

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
    _channel.stream.listen((data) {
      print("Received websocket update ${widget.chat.chatId}");
      var message = data.toString();
      // if (data.toString() != widget.chat.chatId.toString()) {
      //   print("calling onOtherChatGotUpdate $data ${widget.chat.chatId}");

      //   setState(() {
      //     widget.updatedChats.add(data);
      //   });
      // }
      if (message.startsWith('User ') && message.contains(' added to chat ')) {
        var parts = message.split(' ');
        var chatId = int.parse(parts[4]);
        setState(() {
          if (chatId != widget.chat.chatId) {
            widget.updatedChats.add(chatId.toString());
          }
          chatListReloadNeeded = true;
        });
      } else if (data.toString() != widget.chat.chatId.toString()) {
        setState(() {
          widget.updatedChats.add(data);
          chatListReloadNeeded = true;
          // onNewMessageReceived(data.toString());
        });
      }

      onNewMessageReceived(data.toString());
      WindowsTaskbar.setFlashTaskbarAppIcon(
        mode: TaskbarFlashMode.all | TaskbarFlashMode.timernofg,
        timeout: const Duration(milliseconds: 500),
      );
    });
  }

  void onNewMessageReceived(String chatId) {
    setState(() {
      if (chatId == widget.chat.chatId.toString()) {
        // Trigger chat message reload
        chatReloadNeeded = true; // Call the fetchMessages method
      } else {
        widget.updatedChats.add(chatId);
      }
    });
  }

  void updateUserData(UserProfile updatedUserData) {
    setState(() {
      widget.userData = updatedUserData;
    });
  }

  void updateChatData(Chat updatedChatData) {
    setState(() {
      widget.chat = updatedChatData;
      chatListReloadNeeded = true;
    });
  }

  void onDeleteChat() {
    setState(() {
      widget.chat = Chat(0, '', '', 0, 0, ''); // Создаем пустой чат
    });
  }

  @override
  Widget build(BuildContext context) {
    print('build called');
    print(widget.userData);
    print(widget.userData.name);
    print(widget.userData.lastname);
    print(widget.chat.chatId);
    print(widget.updatedChats);
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
                    widget.updatedChats,
                    onChatListUpdated: () {
                      setState(() {
                        chatListReloadNeeded = false;
                      });
                    },
                    reloadNeeded: chatListReloadNeeded,
                    updateUserData: updateUserData,
                    onChatUpdated: (chatId, name, avatar, membersCount, adminId,
                        isGroupChat) {
                      setState(() {
                        print("MAIN PAGE CHAT LIST CALLED");
                        print(widget.updatedChats);
                        widget.updatedChats.remove(chatId.toString());
                        print(widget.updatedChats);
                        widget.chat = Chat(chatId, name, avatar, membersCount,
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
                          onDeleteChat: onDeleteChat,
                          updateChatData: updateChatData,
                          updateMembersCount: (updatedMembersCount) {},
                          reloadNeeded: chatReloadNeeded,
                        )
                      : ZeroPage(widget.auth, widget.userData))),
        ],
      )),
    );
  }
}
