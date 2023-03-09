import 'package:flutter/material.dart';

class ChatList extends StatefulWidget {
  const ChatList({
    super.key,
  });

  @override
  State<ChatList> createState() => _ChatListState();
}

class _ChatListState extends State<ChatList> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Chats'),
        ),
        body: const Center(
          child: Text(
            'The list of chats',
            style: TextStyle(fontSize: 24),
          ),
        ));
  }
}
