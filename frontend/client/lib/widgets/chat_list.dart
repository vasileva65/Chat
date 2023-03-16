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
        //backgroundColor: Color.fromARGB(255, 114, 154, 207),
        appBar: AppBar(
          title: const Text('All chats'),
          backgroundColor: Color.fromARGB(255, 0, 102, 204),
        ),
        body: const Center(
          child: Text(
            'The list of chats',
            style: TextStyle(fontSize: 24),
          ),
        ));
  }
}
