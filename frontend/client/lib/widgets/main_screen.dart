import 'package:flutter/material.dart';
import 'package:client/widgets/chat.dart';
import 'package:client/widgets/chat_list.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({
    super.key,
  });

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
          SafeArea(child: Container(width: 400, child: ChatList())),
          Expanded(
              child: Container(
                  width: MediaQuery.of(context).size.width - 400,
                  child: ChatPage())),
        ],
      )),
    );
  }
}
