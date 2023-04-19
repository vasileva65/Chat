import 'package:flutter/material.dart';
import 'package:client/models/chats.dart';

class ChatList extends StatefulWidget {
  const ChatList({
    super.key,
  });

  @override
  State<ChatList> createState() => _ChatListState();
}

class _ChatListState extends State<ChatList> {
  List<Chats> items = [];
  Chats chat = Chats('Отдел 1', 1, '');
  bool isSelected = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        //backgroundColor: Color.fromARGB(255, 114, 154, 207),
        appBar: AppBar(
          title: const Text('Все чаты'),
          backgroundColor: Color.fromARGB(255, 37, 87, 153),
        ),
        //backgroundColor: Color.fromARGB(255, 247, 247, 247),
        body: Container(
          padding: EdgeInsets.symmetric(vertical: 8.0),
          child: Column(
            children: [
              /*
              Container(
                padding: EdgeInsets.all(8.0),
                child: const Padding(
                  padding: EdgeInsets.only(left: 10.0, top: 8.0),
                  child: Text(
                    'Все чаты',
                    style: TextStyle(fontSize: 21),
                  ),
                ),
              ),*/
              Material(
                child: ListTile(
                  title: Text(
                    chat.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Color.fromARGB(255, 39, 77, 126),
                    ),
                  ),
                  selectedTileColor: Color.fromARGB(17, 39, 77, 126),
                  selected: isSelected,
                  onTap: () {
                    setState(() {});
                  },
                ),
              )
            ],
          ),
        ));
  }
}
