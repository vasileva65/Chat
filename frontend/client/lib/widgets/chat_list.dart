import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:client/models/chats.dart';
import 'package:client/models/auth.dart';

import '../models/userProfile.dart';

typedef ChatUpdated = void Function(int chatId);

class ChatList extends StatefulWidget {
  Auth auth;
  UserProfile userData;
  Chats chat;
  ChatUpdated onChatUpdated;
  ChatList(this.auth, this.userData, this.chat,
      {required this.onChatUpdated, super.key});

  @override
  State<ChatList> createState() => _ChatListState();
}

class _ChatListState extends State<ChatList> {
  List<Chats> items = [];
  bool isSelected = true;
  final dio = Dio();
  late Chats chat;
  ScrollController scrollController = ScrollController();
  Future getChats() async {
    Response returnedResult = await dio.get('http://localhost:8000/chatmembers',
        options: Options(headers: {
          'Authorization': "Bearer ${widget.auth.token}",
        }));
    print("fetching chats");
    print(returnedResult.data);

    List<Chats> result = [];

    for (int i = 0; i < (returnedResult.data as List<dynamic>).length; i++) {
      print(widget.auth.userId);
      if (returnedResult.data[i]['user_id'].toString() == widget.auth.userId) {
        Chats chat = Chats(
            returnedResult.data[i]['chat_id'],
            returnedResult.data[i]['chat_name'],
            returnedResult.data[i]['avatar']);
        print("CHATS");
        print(chat);
        result.add(chat);
      }
      print(result);
    }

    setState(() {
      items = result;
    });
  }

  @override
  void initState() {
    super.initState();
    getChats();
    print("init state called");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        //backgroundColor: Color.fromARGB(255, 114, 154, 207),
        appBar: AppBar(
          title: const Text(''),
          backgroundColor: Color.fromARGB(255, 37, 87, 153),
        ),
        //backgroundColor: Color.fromARGB(255, 247, 247, 247),
        body: Center(
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.all(8.0),
                child: const Padding(
                  padding: EdgeInsets.only(left: 10.0, top: 8.0),
                  child: Text(
                    'Все чаты',
                    style: TextStyle(fontSize: 21),
                  ),
                ),
              ),
              SizedBox(
                height: MediaQuery.of(context).size.height - 130,
                child: ListView.builder(
                    padding:
                        const EdgeInsets.symmetric(vertical: 15, horizontal: 3),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        title: Text(
                          items[index].name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Color.fromARGB(255, 39, 77, 126),
                          ),
                        ),
                        leading: const CircleAvatar(
                          backgroundImage: NetworkImage(''),
                        ),
                        selectedTileColor: Color.fromARGB(17, 39, 77, 126),
                        selected: isSelected,
                        onTap: () {
                          widget.onChatUpdated(items[index].chatId);
                        },
                      );
                    },
                    controller: scrollController),
              )
            ],
          ),
        ));
  }
}
