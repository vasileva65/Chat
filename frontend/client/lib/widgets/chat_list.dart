import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:client/models/chats.dart';
import 'package:client/models/auth.dart';

import '../models/userProfile.dart';

typedef ChatUpdated = void Function(int chatId, String name);

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
  List<Chats> dublicateItems = [];
  bool isSelected = true;
  final dio = Dio();
  late Chats chat;
  ScrollController scrollController = ScrollController();
  TextEditingController searchController = TextEditingController();
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
      dublicateItems = result;
    });
  }

  @override
  void initState() {
    items = dublicateItems;
    super.initState();
    getChats();
    items = dublicateItems;
    print("init state called");
  }

  void filterSearchResults(String query) {
    setState(() {
      items = dublicateItems
          .where(
              (item) => item.name.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Color.fromARGB(255, 255, 255, 255),
        appBar: AppBar(
          title: const Text(''),
          backgroundColor: Color.fromARGB(255, 255, 255, 255),
          elevation: 0,
          shape: const Border(
              bottom:
                  BorderSide(width: 0.2, color: Color.fromARGB(255, 0, 0, 0))),
        ),
        //backgroundColor: Color.fromARGB(255, 247, 247, 247),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10.0),
              child: const Padding(
                padding: EdgeInsets.only(left: 8.0, top: 10.0),
                child: Text(
                  'Все чаты',
                  textAlign: TextAlign.left,
                  style: TextStyle(
                      //color: Color.fromARGB(255, 255, 255, 255),
                      fontSize: 18),
                ),
              ),
            ),
            SizedBox(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                child: TextField(
                  //cursorColor: Color.fromARGB(255, 255, 255, 255),
                  style: const TextStyle(
                      color: Color.fromARGB(255, 255, 255, 255)),
                  onChanged: (value) {
                    filterSearchResults(value);
                  },
                  controller: searchController,
                  decoration: const InputDecoration(
                      //suffixIconColor: Color.fromARGB(255, 255, 255, 255),
                      suffixIconConstraints:
                          BoxConstraints(minWidth: 32, minHeight: 32),
                      hintText: "Найти чат",
                      hintStyle: TextStyle(
                          //color: Color.fromARGB(255, 255, 255, 255),
                          fontSize: 14,
                          fontWeight: FontWeight.w100),
                      suffixIcon: Icon(Icons.search),
                      isDense: true,
                      contentPadding: EdgeInsets.only(
                          right: 10, top: 10, bottom: 10, left: 15),
                      focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                              width: 1,
                              color: Color.fromARGB(255, 37, 87, 153))),
                      border: OutlineInputBorder(
                          borderSide: BorderSide(
                              //color: Color.fromARGB(255, 255, 255, 255)),
                              // borderRadius:
                              //     BorderRadius.all(Radius.circular(15.0)
                              ))),
                ),
              ),
            ),
            SizedBox(
              height: MediaQuery.of(context).size.height - 170,
              child: ListView.builder(
                  padding:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 5),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: ListTile(
                        title: Text(
                          items[index].name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Color.fromARGB(255, 39, 77, 126),
                          ),
                        ),
                        leading: CircleAvatar(
                          backgroundColor: Color.fromARGB(1, 255, 255, 255),
                          backgroundImage: NetworkImage(items[index].avatar),
                        ),
                        selectedTileColor: Color.fromARGB(17, 255, 255, 255),
                        selected: isSelected,
                        onTap: () {
                          widget.onChatUpdated(
                              items[index].chatId, items[index].name);
                        },
                      ),
                    );
                  },
                  controller: scrollController),
            ),
          ],
        ));
  }
}
