import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:client/models/chats.dart';
import 'package:client/models/auth.dart';

import '../models/userProfile.dart';

typedef ChatUpdated = void Function(
    int chatId, String name, String avatar, int membersCount);

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
  List<UserProfile> users = [];
  List<UserProfile> dublicateUsers = [];
  bool isSelected = false;
  final dio = Dio();
  late Chats chat;
  ScrollController scrollController = ScrollController();
  TextEditingController searchController = TextEditingController();

  final nameController = TextEditingController();
  final lastnameController = TextEditingController();
  final middlenameController = TextEditingController();

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
      print('user name:');
      print(widget.userData.userId);
      print(widget.userData.name);

      if (returnedResult.data[i]['user_id'].toString() == widget.auth.userId) {
        Chats chat = Chats(
            returnedResult.data[i]['chat_id'],
            returnedResult.data[i]['chat_name'],
            returnedResult.data[i]['avatar'],
            returnedResult.data[i]['people_count']);
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

  Future addNewChat() async {
    try {
      Response response = await dio.post('http://localhost:8000/chats/',
          data: {
            'user_id': widget.auth.userId,
            'chat_name': '',
          },
          options: Options(headers: {
            'Authorization': "Bearer ${widget.auth.token}",
          }));
      print(response);
      print(response.data);
    } on DioError catch (e) {
      if (e.response != null) {
        if (e.response!.statusCode == 401) {
          Navigator.pop(context);
        }
      }
      return;
    }

    print('max scroll extent: ${items.length}');
    await getChats();

    //print('max scroll extent: ${items.length}');

    scrollController.animateTo(0.0,
        duration: Duration(milliseconds: 300), curve: Curves.easeOut);
  }

  Future getUsers() async {
    Response returnedResult =
        await dio.get('http://localhost:8000/userprofiles',
            options: Options(headers: {
              'Authorization': "Bearer ${widget.auth.token}",
            }));
    print("fetching users");
    print(returnedResult.data);

    List<UserProfile> result = [];

    for (int i = 0; i < (returnedResult.data as List<dynamic>).length; i++) {
      print(widget.auth.userId);

      if (returnedResult.data[i]['user_id'].toString() != widget.auth.userId) {
        UserProfile user = UserProfile(
            returnedResult.data[i]['user_id'].toString(),
            returnedResult.data[i]['user']['first_name'],
            returnedResult.data[i]['user']['last_name'],
            returnedResult.data[i]['user']['middle_name'],
            returnedResult.data[i]['avatar']);
        result.add(user);
      }
    }

    setState(() {
      users = result;
      dublicateUsers = result;
    });
  }

  @override
  void initState() {
    items = dublicateItems;
    super.initState();
    getChats();
    items = dublicateItems;
    print("init state called");
    getUsers();
  }

  void filterSearchResults(String query) {
    setState(() {
      items = dublicateItems
          .where(
              (item) => item.name.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  _getCloseButton(context) {
    return Align(
      alignment: Alignment.topRight,
      child: IconButton(
        splashRadius: 1,
        icon: const Icon(
          Icons.clear,
          color: Colors.black,
        ),
        onPressed: () {
          Navigator.pop(context);
        },
      ),
    );
  }

  void userSettings() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        titlePadding: const EdgeInsets.all(0.0),
        title: Container(
            padding: EdgeInsets.fromLTRB(0, 0, 0, 8),
            child: Center(
                child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _getCloseButton(context),
                const Text("Настройки пользователя"),
              ],
            ))),
        content: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
          child: SizedBox(
            width: 270,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(0, 0, 0, 20),
                  child: Material(
                    elevation: 8,
                    shape: const CircleBorder(),
                    clipBehavior: Clip.antiAliasWithSaveLayer,
                    child: InkWell(
                      splashColor: Colors.black26,
                      onTap: () {},
                      child: Ink.image(
                        image: NetworkImage(widget.userData.avatar),
                        height: 120,
                        width: 120,
                      ),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: TextFormField(
                    //onEditingComplete: signIn,
                    controller: nameController,
                    decoration: const InputDecoration(
                        focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                                width: 1,
                                color: Color.fromARGB(255, 37, 87, 153))),
                        border: OutlineInputBorder(),
                        labelText: 'Имя',
                        hintText: 'Введите имя'),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: TextFormField(
                    //onEditingComplete: signIn,
                    controller: lastnameController,
                    decoration: const InputDecoration(
                        focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                                width: 1,
                                color: Color.fromARGB(255, 37, 87, 153))),
                        border: OutlineInputBorder(),
                        labelText: 'Фамилия',
                        hintText: 'Введите фамилию'),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: TextFormField(
                    //onEditingComplete: signIn,
                    controller: middlenameController,
                    decoration: const InputDecoration(
                        focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                                width: 1,
                                color: Color.fromARGB(255, 37, 87, 153))),
                        border: OutlineInputBorder(),
                        labelText: 'Отчество',
                        hintText: 'Введите отчество'),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: <Widget>[
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
              },
              style: ButtonStyle(
                  backgroundColor: const MaterialStatePropertyAll<Color>(
                      Color.fromARGB(255, 37, 87, 153)),
                  shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                      RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5.0),
                  ))),
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                child: const Text(
                  "Сохранить",
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w300),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void addChat() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        titlePadding: const EdgeInsets.all(0.0),
        title: Container(
            padding: EdgeInsets.fromLTRB(0, 0, 0, 8),
            child: Center(
                child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _getCloseButton(context),
                const Text("Создать чат"),
              ],
            ))),
        content: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
          child: SizedBox(
            width: 270,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(0, 0, 0, 20),
                  child: Material(
                    elevation: 8,
                    shape: const CircleBorder(),
                    clipBehavior: Clip.antiAliasWithSaveLayer,
                    child: InkWell(
                      splashColor: Colors.black26,
                      onTap: () {},
                      child: Ink.image(
                        image: NetworkImage(''),
                        height: 120,
                        width: 120,
                      ),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: TextFormField(
                    //onEditingComplete: signIn,
                    controller: nameController,
                    decoration: const InputDecoration(
                        focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                                width: 1,
                                color: Color.fromARGB(255, 37, 87, 153))),
                        border: OutlineInputBorder(),
                        labelText: 'Название чата',
                        hintText: 'Введите название'),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(0, 10, 0, 0),
                  child: const TextField(
                    //cursorColor: Color.fromARGB(255, 255, 255, 255),
                    style: TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
                    onChanged: null,

                    decoration: InputDecoration(
                        //suffixIconColor: Color.fromARGB(255, 255, 255, 255),
                        suffixIconConstraints:
                            BoxConstraints(minWidth: 32, minHeight: 40),
                        hintText: "Найти пользователя",
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
                Expanded(
                  child: ListView.builder(
                      padding: EdgeInsets.fromLTRB(0, 20, 0, 0),
                      scrollDirection: Axis.vertical,
                      shrinkWrap: true,
                      itemCount: users.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.fromLTRB(0, 6, 0, 6),
                          child: ListTile(
                            title:
                                Text(users[index].name + users[index].lastname),
                            leading: CircleAvatar(
                                backgroundColor:
                                    Color.fromARGB(1, 255, 255, 255),
                                backgroundImage:
                                    NetworkImage(users[index].avatar)),
                            onTap: () {},
                          ),
                        );
                      }),
                )
              ],
            ),
          ),
        ),
        actions: <Widget>[
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
              },
              style: ButtonStyle(
                  backgroundColor: const MaterialStatePropertyAll<Color>(
                      Color.fromARGB(255, 37, 87, 153)),
                  shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                      RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5.0),
                  ))),
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                child: const Text(
                  "Сохранить",
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w300),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        appBar: AppBar(
          title: ListTile(
            title: Text(
              '${widget.userData.name} ${widget.userData.lastname}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: Color.fromARGB(255, 39, 77, 126),
              ),
            ),
            subtitle: const Text(
              'Online',
              style: TextStyle(
                fontWeight: FontWeight.w400,
                fontSize: 14,
              ),
            ),
            leading: CircleAvatar(
              backgroundColor: const Color.fromARGB(1, 255, 255, 255),
              backgroundImage: NetworkImage(widget.userData.avatar),
            ),
            selectedTileColor: Colors.white,
            selected: false,
            onTap: () {
              userSettings();
            },
            hoverColor: Colors.transparent,
            splashColor: Colors.transparent,
          ),
          backgroundColor: const Color.fromARGB(255, 255, 255, 255),
          elevation: 0,
          titleSpacing: 0,
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
                  style: const TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
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
              child: Column(
                children: [
                  ListTile(
                    title: const Text(
                      'Группы',
                      style: TextStyle(fontSize: 18),
                    ),
                    trailing: IconButton(
                      icon: const Icon(
                        Icons.add,
                      ),
                      onPressed: addChat,
                      splashRadius: 1,
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 5),
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
                                backgroundColor:
                                    Color.fromARGB(1, 255, 255, 255),
                                backgroundImage:
                                    NetworkImage(items[index].avatar),
                              ),
                              selectedTileColor:
                                  Color.fromARGB(17, 255, 255, 255),
                              selected: isSelected,
                              onTap: () {
                                widget.onChatUpdated(
                                    items[index].chatId,
                                    items[index].name,
                                    items[index].avatar,
                                    items[index].membersCount);
                              },
                              hoverColor: Colors.transparent,
                              splashColor: Colors.transparent,
                            ),
                          );
                        },
                        controller: scrollController),
                  ),
                ],
              ),
            ),
          ],
        ));
  }
}
