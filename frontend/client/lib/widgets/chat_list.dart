import 'package:client/dialogs/buttons.dart';
import 'package:client/dialogs/chatlist_dialogs.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:client/models/chats.dart';
import 'package:client/models/auth.dart';
import 'package:image_picker/image_picker.dart';
import '../models/userProfile.dart';

typedef ChatUpdated = void Function(
    int chatId, String name, String avatar, int membersCount, int adminId);

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
  List<UserProfile> selectedUsers = [];
  bool isSelected = false;
  UserProfile? selectedUser;
  final dio = Dio();
  late Chats chat;
  ScrollController scrollController = ScrollController();
  TextEditingController searchChatController = TextEditingController();
  TextEditingController searchUserController = TextEditingController();

  final nameController = TextEditingController();
  final lastnameController = TextEditingController();
  final middlenameController = TextEditingController();
  final chatNameController = TextEditingController();
  int _selectedUserIndex = -1;
  late List<bool> _isChecked;

  Chats? selectedChat;

  bool isExpanded = false;

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
            returnedResult.data[i]['people_count'],
            returnedResult.data[i]['user_id']);
        print("CHATS");
        print(chat);
        result.add(chat);
      }
      print(result);
    }

    if (mounted) {
      setState(() {
        items = result;
        dublicateItems = result;
      });
      if (scrollController.hasClients) {
        scrollController.animateTo(0.0,
            duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    }
  }

  Future addNewGroupChat() async {
    print('add new group chat called');
    try {
      Response response =
          await dio.post('http://localhost:8000/chats/create_chat/',
              data: {
                'chat_name': chatNameController.text,
                'user_ids': selectedUsers
                    .map((user) => user.userId.toString())
                    .toList(),
                'avatar': null,
                'admin_id': widget.userData.userId,
                'group_chat': true,
              },
              options: Options(headers: {
                'Authorization': "Bearer ${widget.auth.token}",
              }));
      print(response);
      print(response.data);
    } on DioError catch (e) {
      print('Error: $e');
      if (e.response != null) {
        if (e.response!.statusCode == 401) {
          Navigator.pop(context);
        }
      }
      return;
    }

    print('AddNewChat called');
    await getChats();

    if (scrollController.hasClients) {
      scrollController.animateTo(0.0,
          duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }
  }

  Future addNewPersonalChat() async {
    print('add new group chat called');
    try {
      Response response =
          await dio.post('http://localhost:8000/chats/create_chat/',
              data: {
                'chat_name':
                    '${widget.userData.lastname} +  ${selectedUser?.lastname}',
                'user_ids': selectedUser?.userId,
                'avatar': null,
                'admin_id': widget.userData.userId,
                'group_chat': false,
              },
              options: Options(headers: {
                'Authorization': "Bearer ${widget.auth.token}",
              }));
      print(response);
      print(response.data);
    } on DioError catch (e) {
      print('Error: $e');
      if (e.response != null) {
        if (e.response!.statusCode == 401) {
          Navigator.pop(context);
        }
      }
      return;
    }

    print('AddNewPersonalChat called');
    await getChats();

    if (scrollController.hasClients) {
      scrollController.animateTo(0.0,
          duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }
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
            returnedResult.data[i]['user']['username'],
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
      _isChecked = List<bool>.filled(users.length, false);
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

  void selectChat(Chats chat) {
    setState(() {
      selectedChat = chat;
      isExpanded = true;
    });
  }

  void filterSearchChatsResults(String query) {
    setState(() {
      if (selectedChat != null && !isExpanded) {
        // Если выбран чат и он не в раскрытом состоянии, раскрываем список
        items = [selectedChat!] +
            dublicateItems
                .where((item) =>
                    item.name.toLowerCase().contains(query.toLowerCase()))
                .toList();
        isExpanded = true; // Помещаем выбранный чат в начало списка
      } else {
        // Иначе выполняем поиск в обычных чатах
        items = dublicateItems
            .where(
                (item) => item.name.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
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
            padding: const EdgeInsets.fromLTRB(0, 0, 0, 8),
            child: Center(
                child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Buttons.getCloseButton(context),
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

  void addGroupChat() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        titlePadding: const EdgeInsets.all(0.0),
        title: Container(
            padding: const EdgeInsets.fromLTRB(0, 0, 0, 8),
            child: Center(
                child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _getCloseButton(context),
                const Text("Создать чат"),
              ],
            ))),
        content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
          return Padding(
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
                          image: const AssetImage('assets/images/default.jpg'),
                          height: 120,
                          width: 120,
                        ),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: TextFormField(
                      controller: chatNameController,
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
                    child: TextField(
                      onChanged: (query) {
                        setState(() {
                          users = dublicateUsers.where((item) {
                            return '${item.name.toLowerCase()} ${item.lastname.toLowerCase()}'
                                    .contains(query) ||
                                item.name.toLowerCase() +
                                        item.lastname.toLowerCase() ==
                                    query.toLowerCase() ||
                                item.name
                                    .toLowerCase()
                                    .contains(query.toLowerCase()) ||
                                item.lastname
                                    .toLowerCase()
                                    .contains(query.toLowerCase());
                          }).toList();
                        });
                      },
                      controller: searchUserController,
                      style:
                          const TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
                      decoration: const InputDecoration(
                          suffixIconConstraints:
                              BoxConstraints(minWidth: 32, minHeight: 40),
                          hintText: "Найти пользователя",
                          hintStyle: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w100),
                          suffixIcon: Icon(Icons.search),
                          isDense: true,
                          contentPadding: EdgeInsets.only(
                              right: 10, top: 10, bottom: 10, left: 15),
                          focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                  width: 1,
                                  color: Color.fromARGB(255, 37, 87, 153))),
                          border: OutlineInputBorder(borderSide: BorderSide())),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(0, 20, 0, 0),
                        scrollDirection: Axis.vertical,
                        shrinkWrap: true,
                        itemCount: users.length,
                        itemBuilder: (context, index) {
                          return Padding(
                              padding: const EdgeInsets.fromLTRB(0, 6, 0, 6),
                              child: CheckboxListTile(
                                value: _isChecked[index],
                                title: Text(
                                    '${users[index].name} ${users[index].lastname}'),
                                secondary: CircleAvatar(
                                    backgroundColor:
                                        const Color.fromARGB(1, 255, 255, 255),
                                    backgroundImage:
                                        NetworkImage(users[index].avatar)),
                                onChanged: (bool? value) {
                                  setState(() {
                                    _isChecked[index] = value!;

                                    if (_isChecked[index]) {
                                      selectedUsers.add(users[index]);
                                    } else {
                                      selectedUsers.remove(users[index]);
                                    }
                                  });
                                },
                              ));
                        }),
                  )
                ],
              ),
            ),
          );
        }),
        actions: <Widget>[
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextButton(
              onPressed: () {
                addNewGroupChat();
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

  void addPersonalChat() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        titlePadding: const EdgeInsets.all(0.0),
        title: Container(
            padding: const EdgeInsets.fromLTRB(0, 0, 0, 8),
            child: Center(
                child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _getCloseButton(context),
                const Text("Создать чат"),
              ],
            ))),
        content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
          return Padding(
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
                          image: const AssetImage('assets/images/default.jpg'),
                          height: 120,
                          width: 120,
                        ),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: TextFormField(
                      controller: chatNameController,
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
                    child: TextField(
                      onChanged: (query) {
                        setState(() {
                          users = dublicateUsers.where((item) {
                            return '${item.name.toLowerCase()} ${item.lastname.toLowerCase()}'
                                    .contains(query) ||
                                item.name.toLowerCase() +
                                        item.lastname.toLowerCase() ==
                                    query.toLowerCase() ||
                                item.name
                                    .toLowerCase()
                                    .contains(query.toLowerCase()) ||
                                item.lastname
                                    .toLowerCase()
                                    .contains(query.toLowerCase());
                          }).toList();
                        });
                      },
                      controller: searchUserController,
                      style:
                          const TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
                      decoration: const InputDecoration(
                          suffixIconConstraints:
                              BoxConstraints(minWidth: 32, minHeight: 40),
                          hintText: "Найти пользователя",
                          hintStyle: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w100),
                          suffixIcon: Icon(Icons.search),
                          isDense: true,
                          contentPadding: EdgeInsets.only(
                              right: 10, top: 10, bottom: 10, left: 15),
                          focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                  width: 1,
                                  color: Color.fromARGB(255, 37, 87, 153))),
                          border: OutlineInputBorder(borderSide: BorderSide())),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(0, 20, 0, 0),
                        scrollDirection: Axis.vertical,
                        shrinkWrap: true,
                        itemCount: users.length,
                        itemBuilder: (context, index) {
                          return Padding(
                              padding: const EdgeInsets.fromLTRB(0, 6, 0, 6),
                              child: CheckboxListTile(
                                value: selectedUser == users[index],
                                title: Text(
                                    '${users[index].name} ${users[index].lastname}'),
                                secondary: CircleAvatar(
                                    backgroundColor:
                                        const Color.fromARGB(1, 255, 255, 255),
                                    backgroundImage:
                                        NetworkImage(users[index].avatar)),
                                onChanged: (bool? value) {
                                  setState(() {
                                    if (value!) {
                                      selectedUser = users[index];
                                    } else {
                                      selectedUser = null;
                                    }
                                  });
                                },
                              ));
                        }),
                  )
                ],
              ),
            ),
          );
        }),
        actions: <Widget>[
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextButton(
              onPressed: () {
                addNewGroupChat();
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
              ChatListDialogs.userSettings(context, widget.userData.avatar,
                  nameController, lastnameController, middlenameController);
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
                  style: TextStyle(fontSize: 18),
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
                    filterSearchChatsResults(value);
                  },
                  controller: searchChatController,
                  decoration: const InputDecoration(
                      suffixIconConstraints:
                          BoxConstraints(minWidth: 32, minHeight: 32),
                      hintText: "Найти чат",
                      hintStyle:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.w100),
                      suffixIcon: Icon(Icons.search),
                      isDense: true,
                      contentPadding: EdgeInsets.only(
                          right: 10, top: 10, bottom: 10, left: 15),
                      focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                              width: 1,
                              color: Color.fromARGB(255, 37, 87, 153))),
                      border: OutlineInputBorder(borderSide: BorderSide())),
                ),
              ),
            ),
            Expanded(
              child: Column(
                children: [
                  ExpansionTile(
                    onExpansionChanged: (expanded) {
                      setState(() {
                        isExpanded = expanded;
                      });
                    },
                    //initiallyExpanded: isExpanded,
                    title: const Text(
                      'Группы',
                      style: TextStyle(fontSize: 18),
                    ),
                    trailing: IconButton(
                      icon: const Icon(
                        Icons.add,
                      ),
                      onPressed: () {
                        addGroupChat();
                      },
                      splashRadius: 1,
                    ),
                    children: [
                      SizedBox(
                        height: 200,
                        child: ListView.builder(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            itemCount: items.length,
                            itemBuilder: (context, index) {
                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 5),
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
                                        items[index].membersCount,
                                        items[index].adminId);
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
                  ListTile(
                    title: const Text(
                      'Личные чаты',
                      style: TextStyle(fontSize: 18),
                    ),
                    trailing: IconButton(
                      icon: const Icon(
                        Icons.add,
                      ),
                      onPressed: () {
                        addPersonalChat();
                      },
                      splashRadius: 1,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ));
  }
}
