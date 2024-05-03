// идея этого класса в том чтобы организовать передачу информации между диалоговыми окнами

import 'package:client/dialogs/user_profile_dialog.dart';
import 'package:client/models/chats.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../models/auth.dart';
import '../models/userProfile.dart';

_getCloseButton(BuildContext context, VoidCallback onClose) {
  return Align(
    alignment: Alignment.topRight,
    child: IconButton(
      splashRadius: 1,
      icon: const Icon(
        Icons.clear,
        color: Colors.black,
      ),
      onPressed: () {
        onClose();
        Navigator.pop(context);
      },
    ),
  );
}

String confirmAdminRemoving =
    'Вы уверены, что хотите\nотозвать права администратора';
String confirmMemberRemoving =
    'Вы уверены, что хотите\nудалить участника группы';

class GroupChatSettingsDialog extends StatefulWidget {
  Auth auth;
  final UserProfile user;
  final TextEditingController nameController;
  final Chats chat;
  final Function(int chatId, String name, String avatar, int membersCount,
      int adminId, String isGroupChat) onChatUpdated;

  GroupChatSettingsDialog({
    required this.auth,
    required this.user,
    required this.nameController,
    required this.chat,
    required this.onChatUpdated,
  });

  @override
  _GroupChatSettingsDialogState createState() => _GroupChatSettingsDialogState(
        user: user,
        nameController: nameController,
        chat: chat,
      );
}

class _GroupChatSettingsDialogState extends State<GroupChatSettingsDialog> {
  List<int> admins = [];
  List<UserProfile> users = [];
  final UserProfile user;
  List<UserProfile> members = [];
  //final List<UserProfile> outOfChatMembers;
  final TextEditingController nameController;
  final Chats chat;
  List<UserProfile> adminMembers = [];
  List<UserProfile> regularMembers = [];
  bool isLoading = true;
  late UserProfile userToRemove;

  _GroupChatSettingsDialogState({
    //required this.admins,
    //required this.users,
    required this.user,
    //required this.members,
    //required this.outOfChatMembers,
    required this.nameController,
    required this.chat,
  });

  Future<List<int>> getChatAdminsIds() async {
    var dio = Dio();
    try {
      Response response = await dio.get('http://localhost:8000/chatadmins',
          options: Options(headers: {
            'Authorization': "Bearer ${widget.auth.token}",
          }));
      print("fetching users");
      print(response.data);

      List<int> adminIds = [];

      for (int i = 0; i < (response.data as List<dynamic>).length; i++) {
        if (widget.chat.chatId == response.data[i]['chat_id'] &&
            response.data[i]['left_at'] == null) {
          adminIds.add(response.data[i]['user_id']);
        }
      }
      print("ADMIN IDS");
      print(adminIds);
      return adminIds;
    } catch (e) {
      print('Error fetching chat members: $e');
      return []; // или возвращайте пустой список или другое значение по умолчанию
    }
  }

  Future<List<int>> getChatMembersIds() async {
    var dio = Dio();
    try {
      Response response = await dio.get('http://localhost:8000/chatmembers',
          options: Options(headers: {
            'Authorization': "Bearer ${widget.auth.token}",
          }));
      print("fetching users");
      print(response.data);

      List<int> memberIds = [];

      for (int i = 0; i < (response.data as List<dynamic>).length; i++) {
        if (widget.chat.chatId == response.data[i]['chat_id'] &&
            response.data[i]['left_at'] == null) {
          memberIds.add(response.data[i]['user_id']);
        }
      }
      print(memberIds);
      return memberIds;
    } catch (e) {
      print('Error fetching chat members: $e');
      return []; // или возвращайте пустой список или другое значение по умолчанию
    }
  }

  Future getChatMembersDetails() async {
    List<int> memberIds = await getChatMembersIds();
    List<int> adminIds = await getChatAdminsIds();

    List<UserProfile> result = [];
    var dio = Dio();
    for (int memberId in memberIds) {
      try {
        Response returnedResult = await dio.get(
          'http://localhost:8000/userprofiles/',
          options: Options(headers: {
            'Authorization': "Bearer ${widget.auth.token}",
          }),
        );
        print("DETAILS");
        //print(returnedResult.data);
        print(memberId);
        for (int i = 0;
            i < (returnedResult.data as List<dynamic>).length;
            i++) {
          if (returnedResult.data[i]['user_id'] == memberId &&
              !result.any((user) => user.userId == memberId)) {
            print(returnedResult.data[i]);
            UserProfile user = UserProfile(
              returnedResult.data[i]['user_id'],
              returnedResult.data[i]['user']['username'],
              returnedResult.data[i]['user']['first_name'],
              returnedResult.data[i]['user']['last_name'],
              returnedResult.data[i]['user']['middle_name'],
              returnedResult.data[i]['avatar'],
            );

            result.add(user);
          }
        }
      } catch (e) {
        print('Error fetching user profile: $e');
        // обработка ошибок, если не удается получить данные пользователя
      }
    }
    print("USERS IN RESULT");
    for (var user in result) {
      print(user.userId);
    }
    setState(() {
      members = result;
      admins = adminIds;
    });
  }

  Future getUsers() async {
    var dio = Dio();
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
            returnedResult.data[i]['user_id'],
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
    });
  }

  Future removeChatAdmin(Chats chat, UserProfile userToRemove) async {
    print('removeChatMemberAdmin called');
    print(chat.chatId);
    print(userToRemove.userId);
    try {
      var dio = Dio();
      Response response = await dio.patch(
          'http://localhost:8000/chats/partial_update/${chat.chatId}/',
          data: {
            'admin_id': userToRemove.userId.toString(),
            //'user_id': '',
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
    setState(() {
      adminMembers.remove(userToRemove);
      regularMembers.add(userToRemove);
    });
  }

  Future removeChatMember(Chats chat, UserProfile userToRemove) async {
    print('removeChatMemberAdmin called');
    print(chat.chatId);
    print(userToRemove.userId);
    try {
      var dio = Dio();
      Response response = await dio.patch(
          'http://localhost:8000/chats/partial_update/${chat.chatId}/',
          data: {
            'user_id': userToRemove.userId.toString(),
            //'user_id': '',
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
    setState(() {
      members.remove(userToRemove);
      regularMembers.remove(userToRemove);
    });
  }

  Future<void> fetchData() async {
    try {
      await getChatMembersDetails();
      await getUsers();
      adminMembers =
          members.where((member) => admins.contains(member.userId)).toList();

      regularMembers =
          members.where((member) => !admins.contains(member.userId)).toList();

      setState(() {
        isLoading =
            false; // После загрузки данных устанавливаем isLoading в false
      });
    } catch (error) {
      print('Error fetching data: $error');
      // Обработка ошибок при загрузке данных
      setState(() {
        isLoading =
            false; // Даже в случае ошибки устанавливаем isLoading в false
      });
    }
  }

  Future<void> showConfirmationDialog(
      UserProfile userToRemove, String text, Function removeFunction) async {
    return showDialog<void>(
      context: context,
      barrierDismissible:
          true, // Запрещаем закрытие диалога при нажатии вне его
      builder: (BuildContext context) {
        return AlertDialog(
          //title: const Text('Подтвердите действие'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(text),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                // Закрываем диалог без выполнения действия
                Navigator.of(context).pop();
              },
              child: const Text('Отмена'),
            ),
            TextButton(
              onPressed: () async {
                try {
                  // Выполняем действие по отзыву прав администратора
                  await removeFunction(chat, userToRemove);

                  // Закрываем диалог
                  Navigator.of(context).pop();
                } catch (e) {
                  // Обработка ошибок, если необходимо
                  print('Error: $e');
                }
              },
              child: const Text('Подтвердить'),
            ),
          ],
        );
      },
    );
  }

  @override
  void initState() {
    print('doing init');
    super.initState();
    fetchData();
  }

  @override
  Widget build(BuildContext context) {
    print("called groupChat");
    if (isLoading) {
      return const SizedBox(
        height: 30,
        width: 30,
        child: Center(
          child: CircularProgressIndicator(
            strokeWidth: 3.0,
            color: Colors.white,
          ),
        ),
      );
    }
    String chatName = nameController.text;

    List<UserProfile> sortedMembers = [...adminMembers, ...regularMembers];
    return WillPopScope(
      onWillPop: () async {
        nameController.text = chatName;

        return true;
      },
      child: AlertDialog(
        contentPadding: EdgeInsets.fromLTRB(5, 5, 5, 20),
        titlePadding: const EdgeInsets.all(0.0),
        title: Container(
            padding: const EdgeInsets.fromLTRB(0, 0, 0, 20),
            child: Center(
                child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _getCloseButton(context, () {
                  setState(() {
                    nameController.text = chatName;
                  });
                }),
                const Text("Информация о группе"),
              ],
            ))),
        content: Scrollbar(
          interactive: false, // Отключаем интерактивность ползунка
          thumbVisibility: false,
          thickness: 6.0, // Регулирует толщину ползунка
          radius: Radius.circular(4.0), // Регулирует скругление углов ползунка
          //controller: privateChatSettingsScrollController,
          child: ScrollConfiguration(
            behavior:
                ScrollConfiguration.of(context).copyWith(scrollbars: false),
            child: SizedBox(
              width: 360,
              height: MediaQuery.of(context).size.height,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25),
                child: ListView(
                  children: [
                    if (admins.contains(user.userId))
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
                              image: NetworkImage(user.avatar),
                              height: 120,
                              width: 120,
                            ),
                          ),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.fromLTRB(0, 0, 0, 20),
                        child: Material(
                          elevation: 8,
                          shape: const CircleBorder(),
                          clipBehavior: Clip.antiAliasWithSaveLayer,
                          child: InkWell(
                            splashColor: Colors.black26,
                            child: Ink.image(
                              image: NetworkImage(user.avatar),
                              height: 120,
                              width: 120,
                            ),
                          ),
                        ),
                      ),
                    if (admins.contains(user.userId))
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
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          chatName,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.w500),
                        ),
                      ),
                    Container(
                      padding: const EdgeInsets.fromLTRB(0, 35, 0, 0),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Expanded(
                              child: Text(
                                'Администраторы',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w500),
                              ),
                            ),
                            if (admins.contains(user.userId))
                              Tooltip(
                                message: "Добавить администратора",
                                child: IconButton(
                                  icon: const Icon(Icons.add),
                                  splashRadius: 1,
                                  onPressed: () {
                                    print(" called add users");
                                    showDialog(
                                        context: context,
                                        barrierDismissible: true,
                                        builder: (BuildContext context) =>
                                            AddAdmins(
                                              chat: chat,
                                              auth: widget.auth,
                                              users: users,
                                              members: members,
                                              admins: adminMembers,
                                              onSelectionComplete:
                                                  (List<UserProfile>
                                                      selectedUsers) {
                                                // Обработка выбранных пользователей
                                                print(
                                                    'Selected users: $selectedUsers');
                                                // Обновляем данные в основном виджете
                                                setState(() {
                                                  adminMembers
                                                      .addAll(selectedUsers);
                                                  regularMembers.removeWhere(
                                                      (user) => selectedUsers
                                                          .contains(user));
                                                });
                                              },
                                            ));
                                  },
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    ListView.builder(
                      padding: const EdgeInsets.fromLTRB(0, 15, 0, 0),
                      scrollDirection: Axis.vertical,
                      shrinkWrap: true,

                      itemCount: adminMembers.length,
                      itemBuilder: (context, index) {
                        print("MEMBER ID ${sortedMembers[index].userId}");

                        print("ADMIN IDS: ${admins}");
                        bool isAdmin =
                            admins.contains(sortedMembers[index].userId);
                        print(
                            "User ID: ${sortedMembers[index].userId}, isAdmin: $isAdmin");

                        print(regularMembers);
                        print("CHAT ADMIN ID ${chat.adminId}");
                        print("USER ID ${user.userId}");
                        print("USERS IN SETTINGS");
                        print(users);
                        print(chat.adminId == user.userId);
                        if (admins.contains(user.userId)) {
                          return Padding(
                            padding: const EdgeInsets.fromLTRB(0, 6, 0, 6),
                            child: ListTile(
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => UserProfileDialog(
                                    auth: widget.auth,
                                    //admins: admins,
                                    //users: users,
                                    user: adminMembers[index],
                                    //members: members,
                                    //outOfChatMembers: outOfChatMembers,
                                    nameController: nameController,
                                    chat: widget.chat,
                                  ),
                                );
                              },
                              title: Container(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Text(
                                  "${adminMembers[index].name} ${adminMembers[index].lastname}",
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Color.fromARGB(255, 39, 77, 126),
                                  ),
                                ),
                              ),
                              // trailing: const Tooltip(
                              //   message: "Отозвать права администратора",
                              //   child: Icon(
                              //     Icons.group_remove_outlined,
                              //     color: Colors.black,
                              //   ),
                              // ),
                              trailing: Tooltip(
                                message: "Отозвать права администратора",
                                child: IconButton(
                                  splashRadius: 1,
                                  icon: const Icon(
                                    Icons.group_remove_outlined,
                                    color: Colors.black,
                                  ),
                                  onPressed: () {
                                    showConfirmationDialog(
                                      adminMembers[index],
                                      confirmAdminRemoving,
                                      (chat, userToRemove) async {
                                        await removeChatAdmin(
                                            chat, userToRemove);
                                      },
                                    );
                                  },
                                ),
                              ),
                              leading: CircleAvatar(
                                backgroundColor: Colors.white,
                                backgroundImage:
                                    NetworkImage(adminMembers[index].avatar),
                              ),
                              minVerticalPadding: 15.0,
                            ),
                          );
                        }
                        //если пользователь не является админом
                        else {
                          return Padding(
                            padding: const EdgeInsets.fromLTRB(0, 6, 0, 6),
                            child: ListTile(
                              title: Container(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Text(
                                  "${adminMembers[index].name} ${adminMembers[index].lastname}",
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Color.fromARGB(255, 39, 77, 126),
                                  ),
                                ),
                              ),
                              leading: CircleAvatar(
                                backgroundColor: Colors.white,
                                backgroundImage:
                                    NetworkImage(adminMembers[index].avatar),
                              ),
                              minVerticalPadding: 15.0,
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => UserProfileDialog(
                                    auth: widget.auth,
                                    //admins: admins,
                                    //users: users,
                                    user: adminMembers[index],
                                    //members: members,
                                    //outOfChatMembers: outOfChatMembers,
                                    nameController: nameController,
                                    chat: widget.chat,
                                  ),
                                );
                              },
                            ),
                          );
                        }
                      },
                      //controller: privateChatSettingsScrollController,
                    ),
                    Container(
                      padding: const EdgeInsets.fromLTRB(0, 24, 0, 0),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Expanded(
                              child: Text(
                                'Участники чата',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w500),
                              ),
                            ),
                            if (admins.contains(user.userId))
                              Tooltip(
                                  message: "Добавить участника",
                                  child: IconButton(
                                      icon: const Icon(Icons.add),
                                      splashRadius: 1,
                                      onPressed: () {
                                        print(" called add users");
                                        showDialog(
                                            context: context,
                                            barrierDismissible: true,
                                            builder: (BuildContext context) =>
                                                AddMembers(
                                                  chat: chat,
                                                  auth: widget.auth,
                                                  users: users,
                                                  members: members,
                                                  onSelectionComplete:
                                                      //updateRegularMembers,
                                                      (List<UserProfile>
                                                          selectedUsers) {
                                                    // Обработка выбранных пользователей
                                                    print(
                                                        'Selected users: $selectedUsers');
                                                    // Обновляем данные в основном виджете
                                                    setState(() {
                                                      members.addAll(
                                                          selectedUsers);
                                                      regularMembers.addAll(
                                                          selectedUsers);
                                                    });
                                                  },
                                                  onChatUpdated: (int chatId,
                                                      String name,
                                                      String avatar,
                                                      int membersCount,
                                                      int adminId,
                                                      String isGroupChat) {
                                                    // Обновление данных о чате в ChatList
                                                    widget.onChatUpdated(
                                                        chatId,
                                                        name,
                                                        avatar,
                                                        membersCount + 1,
                                                        adminId,
                                                        isGroupChat);
                                                  },
                                                ));
                                      }))
                          ],
                        ),
                      ),
                    ),
                    ListView.builder(
                      padding: const EdgeInsets.fromLTRB(0, 15, 0, 0),
                      scrollDirection: Axis.vertical,
                      shrinkWrap: true,

                      itemCount: regularMembers.length,
                      itemBuilder: (context, index) {
                        print("MEMBER ID ${sortedMembers[index].userId}");

                        print("ADMIN IDS: ${admins}");
                        bool isAdmin =
                            admins.contains(sortedMembers[index].userId);
                        print(
                            "User ID: ${sortedMembers[index].userId}, isAdmin: $isAdmin");

                        print(regularMembers);
                        if (admins.contains(user.userId)) {
                          return Padding(
                            padding: const EdgeInsets.fromLTRB(0, 6, 0, 6),
                            child: ListTile(
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => UserProfileDialog(
                                    auth: widget.auth,
                                    user: sortedMembers[index],
                                    nameController: nameController,
                                    chat: widget.chat,
                                  ),
                                );
                              },
                              title: Container(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Text(
                                  "${regularMembers[index].name} ${regularMembers[index].lastname}",
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Color.fromARGB(255, 39, 77, 126),
                                  ),
                                ),
                              ),
                              trailing: Tooltip(
                                message: "Удалить участника",
                                child: IconButton(
                                  splashRadius: 1,
                                  icon: const Icon(
                                    Icons.group_remove_outlined,
                                    color: Colors.black,
                                  ),
                                  onPressed: () {
                                    showConfirmationDialog(
                                      regularMembers[index],
                                      confirmMemberRemoving,
                                      (chat, userToRemove) async {
                                        await removeChatMember(
                                            chat, userToRemove);
                                      },
                                    );
                                  },
                                ),
                              ),
                              leading: CircleAvatar(
                                backgroundColor: Colors.white,
                                backgroundImage:
                                    NetworkImage(regularMembers[index].avatar),
                              ),
                              minVerticalPadding: 15.0,
                            ),
                          );
                        }
                        //если пользователь не админ
                        else {
                          return Padding(
                            padding: const EdgeInsets.fromLTRB(0, 6, 0, 6),
                            child: ListTile(
                              title: Container(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Text(
                                  "${regularMembers[index].name} ${regularMembers[index].lastname}",
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Color.fromARGB(255, 39, 77, 126),
                                  ),
                                ),
                              ),
                              leading: CircleAvatar(
                                backgroundColor: Colors.white,
                                backgroundImage:
                                    NetworkImage(regularMembers[index].avatar),
                              ),
                              minVerticalPadding: 15.0,
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => UserProfileDialog(
                                    auth: widget.auth,
                                    //admins: admins,
                                    //users: users,
                                    user: regularMembers[index],
                                    //members: members,
                                    //outOfChatMembers: outOfChatMembers,
                                    nameController: nameController,
                                    chat: widget.chat,
                                  ),
                                );
                              },
                            ),
                          );
                        }
                      },
                      //controller: privateChatSettingsScrollController,
                    )
                  ],
                ),
              ),
            ),
          ),
        ),
        actions: <Widget>[
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextButton(
              onPressed: () {
                Navigator.of(context).pop();
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
}

class AddMembers extends StatefulWidget {
  Chats chat;
  Auth auth;
  List<UserProfile> users;
  List<UserProfile> members;
  final Function(int chatId, String name, String avatar, int membersCount,
      int adminId, String isGroupChat) onChatUpdated;

  final Function(List<UserProfile> selectedUsers) onSelectionComplete;

  AddMembers({
    required this.chat,
    required this.auth,
    required this.users,
    required this.members,
    required this.onSelectionComplete,
    required this.onChatUpdated,
  });
  @override
  _AddMembersState createState() => _AddMembersState();
}

class _AddMembersState extends State<AddMembers> {
  TextEditingController searchUserController = TextEditingController();
  List<UserProfile> dublicateOutOfChatMembers = [];
  List<UserProfile> outOfChatMembers = [];
  List<UserProfile> selectedUsers = [];
  late Set<String> selectedUserIds = Set<String>();

  void filterUsers(String query) {
    print("Query: $query");
    print("Original users: $dublicateOutOfChatMembers");
    setState(() {
      if (query.isEmpty) {
        // If the query is empty, show all users
        outOfChatMembers = dublicateOutOfChatMembers.toList();
      } else {
        outOfChatMembers = dublicateOutOfChatMembers.where((item) {
          bool matches =
              '${item.name.toLowerCase()} ${item.lastname.toLowerCase()}'
                      .contains(query.toLowerCase()) ||
                  item.name.toLowerCase() + item.lastname.toLowerCase() ==
                      query.toLowerCase() ||
                  item.name.toLowerCase().contains(query.toLowerCase()) ||
                  item.lastname.toLowerCase().contains(query.toLowerCase());
          print("Item: $item, Matches: $matches");
          return matches;
        }).toList();
      }
      print("Updated outOfChatMembers: $outOfChatMembers");
    });
  }

  Future addChatMembers(Chats chat) async {
    print('add new group chat called');
    try {
      var dio = Dio();
      Response response = await dio.patch(
          'http://localhost:8000/chats/partial_update/${chat.chatId}/',
          data: {
            //'chat_name': chatNameController.text,
            'user_ids':
                selectedUsers.map((user) => user.userId.toString()).toList(),

            //'admin_id': widget.userData.userId,
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

    print('AddMembers called');
  }

  @override
  Widget build(BuildContext context) {
    print("members == users ??");
    print(widget.members == widget.users);
    print("ADD MEMBER CALLED");
    print("USERS IN ADD MEMBERS");
    //print(widget.users);
    outOfChatMembers =
        widget.users.where((user) => !widget.members.contains(user)).toList();

    dublicateOutOfChatMembers = outOfChatMembers;
    print("outOfChatMembers == users ??");
    print(outOfChatMembers == widget.users);
    print("USER IDS: ${widget.users.map((user) => user.userId).toList()}");
    print("MEMBERS IDS: ${widget.members.map((user) => user.userId).toList()}");
    print(
        "OUT OF CHAT USERS IDS: ${outOfChatMembers.map((user) => user.userId).toList()}");

    return WillPopScope(
        onWillPop: () async {
          // Сбрасываем поля при закрытии диалога
          //nameController.clear();

          return true; // Разрешаем закрытие диалога
        },
        child: AlertDialog(
          titlePadding: const EdgeInsets.all(0.0),
          title: Container(
              padding: const EdgeInsets.fromLTRB(0, 0, 0, 20),
              child: Center(
                  child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _getCloseButton(context, () {
                    setState(() {
                      selectedUserIds.clear();
                    });
                  }),
                  const Text("Добавить участников"),
                ],
              ))),
          content: SizedBox(
            width: 320,
            child: Column(children: [
              Container(
                padding: const EdgeInsets.fromLTRB(0, 10, 0, 0),
                child: TextField(
                  onChanged: (query) {
                    setState(() {
                      outOfChatMembers =
                          dublicateOutOfChatMembers.where((item) {
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
                  style: const TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
                  decoration: const InputDecoration(
                      suffixIconConstraints:
                          BoxConstraints(minWidth: 32, minHeight: 40),
                      hintText: "Найти пользователя",
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
              Expanded(
                child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(0, 20, 0, 0),
                    scrollDirection: Axis.vertical,
                    shrinkWrap: true,
                    itemCount: outOfChatMembers.length,
                    itemBuilder: (context, index) {
                      // print("outOfChatMembers");
                      // print(widget.outOfChatMembers);
                      return Padding(
                          padding: const EdgeInsets.fromLTRB(0, 6, 0, 6),
                          child: CheckboxListTile(
                            value: selectedUserIds.contains(
                                outOfChatMembers[index].userId.toString()),
                            //_isChecked[users[index].userId] ??
                            //false,
                            ////_isChecked[index],
                            title: Text(
                                '${outOfChatMembers[index].name} ${outOfChatMembers[index].lastname}'),
                            secondary: CircleAvatar(
                                backgroundColor:
                                    const Color.fromARGB(1, 255, 255, 255),
                                backgroundImage: NetworkImage(
                                    outOfChatMembers[index].avatar)),
                            onChanged: (bool? value) {
                              setState(() {
                                if (value != null) {
                                  //int originalIndex = dublicateUsers.indexOf(users[index]);
                                  //_isChecked[originalIndex] = value;
                                  //_isChecked[users[index].userId] = value;
                                  if (value) {
                                    selectedUserIds.add(outOfChatMembers[index]
                                        .userId
                                        .toString());
                                    selectedUsers.add(outOfChatMembers[index]);
                                    //selectedUsers.add(users[index]);
                                  } else {
                                    selectedUserIds.remove(
                                        outOfChatMembers[index]
                                            .userId
                                            .toString());
                                    selectedUsers
                                        .remove(outOfChatMembers[index]);
                                    //selectedUsers.remove(users[index]);
                                  }
                                }
                              });
                            },
                          ));
                    }),
              ),

              // onPressed: () {
              //   // После выбора пользователей, передаем данные обратно
              //   Navigator.pop(context, selectedUsers);
              // },
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 20, 0, 0),
                child: TextButton(
                  onPressed: () {
                    addChatMembers(widget.chat);
                    print(
                        "SELECTED USER IDS: ${selectedUsers.map((user) => user.userId).toList()}");
                    widget.onSelectionComplete(selectedUsers);
                    // widget.onChatUpdated(
                    //   widget.chat.chatId,
                    //   widget.chat.name,
                    //   widget.chat.avatar,
                    //   widget.members.length,
                    //   widget.chat.adminId,
                    //   widget.chat.isGroupChat,
                    // );
                    Navigator.pop(context, selectedUsers);
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
            ]),
          ),
        ));
  }
}

class AddAdmins extends StatefulWidget {
  Chats chat;
  Auth auth;
  List<UserProfile> users;
  List<UserProfile> members;
  List<UserProfile> admins;

  final Function(List<UserProfile> selectedUsers) onSelectionComplete;

  AddAdmins({
    required this.chat,
    required this.auth,
    required this.users,
    required this.members,
    required this.admins,
    required this.onSelectionComplete,
  });
  @override
  _AddAdminsState createState() => _AddAdminsState();
}

class _AddAdminsState extends State<AddAdmins> {
  TextEditingController searchUserController = TextEditingController();
  List<UserProfile> dublicateOutOfChatAdmins = [];
  List<UserProfile> outOfChatAdmins = [];

  List<UserProfile> selectedAdmins = [];
  late Set<String> selectedUserIds = Set<String>();

  void filterUsers(String query) {
    print("Query: $query");
    print("Original users: $dublicateOutOfChatAdmins");
    setState(() {
      if (query.isEmpty) {
        // If the query is empty, show all users
        outOfChatAdmins = dublicateOutOfChatAdmins.toList();
      } else {
        outOfChatAdmins = dublicateOutOfChatAdmins.where((item) {
          bool matches =
              '${item.name.toLowerCase()} ${item.lastname.toLowerCase()}'
                      .contains(query.toLowerCase()) ||
                  item.name.toLowerCase() + item.lastname.toLowerCase() ==
                      query.toLowerCase() ||
                  item.name.toLowerCase().contains(query.toLowerCase()) ||
                  item.lastname.toLowerCase().contains(query.toLowerCase());
          print("Item: $item, Matches: $matches");
          return matches;
        }).toList();
      }
      print("Updated outOfChatMembers: $outOfChatAdmins");
    });
  }

  Future addChatAdmins(Chats chat) async {
    print('add new group chat called');
    try {
      var dio = Dio();
      Response response = await dio.patch(
          'http://localhost:8000/chats/partial_update/${chat.chatId}/',
          data: {
            //'chat_name': chatNameController.text,
            'admin_ids':
                selectedAdmins.map((user) => user.userId.toString()).toList(),

            //'admin_id': widget.userData.userId,
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

    print('AddAdmins called');
  }

  @override
  Widget build(BuildContext context) {
    print("members == users ??");
    print(widget.admins == widget.users);
    print("ADD ADMIN CALLED");
    print("USERS IN ADD ADMINS");
    //print(widget.users);
    List<UserProfile> adminMembers = widget.members
        .where((member) => widget.admins.contains(member))
        .toList();
    print(
        "WIDGET MEMBERS: ${widget.members.map((user) => user.userId).toList()}");
    print(
        "OUT OF CHAT ADMINS MEMBERS: ${adminMembers.map((user) => user.userId).toList()}");
    outOfChatAdmins =
        widget.members.where((user) => !adminMembers.contains(user)).toList();
    print(
        "OUT OF CHAT ADMINS IDS: ${outOfChatAdmins.map((user) => user.userId).toList()}");
    dublicateOutOfChatAdmins = List<UserProfile>.generate(
      outOfChatAdmins.length,
      (index) => outOfChatAdmins[index],
    );
    print("outOfChatMembers == users ??");
    print(outOfChatAdmins == widget.users);
    print("USER IDS: ${widget.users.map((user) => user.userId).toList()}");
    print("ADMINS IDS: ${adminMembers.map((user) => user.userId).toList()}");
    print(
        "OUT OF CHAT ADMINS IDS: ${outOfChatAdmins.map((user) => user.userId).toList()}");

    return WillPopScope(
        onWillPop: () async {
          // Сбрасываем поля при закрытии диалога
          //nameController.clear();

          return true; // Разрешаем закрытие диалога
        },
        child: AlertDialog(
          titlePadding: const EdgeInsets.all(0.0),
          title: Container(
              padding: const EdgeInsets.fromLTRB(0, 0, 0, 20),
              child: Center(
                  child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _getCloseButton(context, () {
                    setState(() {
                      selectedUserIds.clear();
                    });
                  }),
                  const Text("Добавить администраторов"),
                ],
              ))),
          content: SizedBox(
            width: 320,
            child: Column(children: [
              Container(
                padding: const EdgeInsets.fromLTRB(0, 10, 0, 0),
                child: TextField(
                  onChanged: (query) {
                    setState(() {
                      outOfChatAdmins = dublicateOutOfChatAdmins.where((item) {
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
                  style: const TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
                  decoration: const InputDecoration(
                      suffixIconConstraints:
                          BoxConstraints(minWidth: 32, minHeight: 40),
                      hintText: "Найти пользователя",
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
              Expanded(
                child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(0, 20, 0, 0),
                    scrollDirection: Axis.vertical,
                    shrinkWrap: true,
                    itemCount: outOfChatAdmins.length,
                    itemBuilder: (context, index) {
                      // print("outOfChatMembers");
                      // print(widget.outOfChatMembers);
                      return Padding(
                          padding: const EdgeInsets.fromLTRB(0, 6, 0, 6),
                          child: CheckboxListTile(
                            value: selectedUserIds.contains(
                                outOfChatAdmins[index].userId.toString()),
                            //_isChecked[users[index].userId] ??
                            //false,
                            ////_isChecked[index],
                            title: Text(
                                '${outOfChatAdmins[index].name} ${outOfChatAdmins[index].lastname}'),
                            secondary: CircleAvatar(
                                backgroundColor:
                                    const Color.fromARGB(1, 255, 255, 255),
                                backgroundImage: NetworkImage(
                                    outOfChatAdmins[index].avatar)),
                            onChanged: (bool? value) {
                              setState(() {
                                if (value != null) {
                                  //int originalIndex = dublicateUsers.indexOf(users[index]);
                                  //_isChecked[originalIndex] = value;
                                  //_isChecked[users[index].userId] = value;
                                  if (value) {
                                    selectedUserIds.add(outOfChatAdmins[index]
                                        .userId
                                        .toString());
                                    selectedAdmins.add(outOfChatAdmins[index]);
                                    //selectedUsers.add(users[index]);
                                  } else {
                                    selectedUserIds.remove(
                                        outOfChatAdmins[index]
                                            .userId
                                            .toString());
                                    selectedAdmins
                                        .remove(outOfChatAdmins[index]);
                                    //selectedUsers.remove(users[index]);
                                  }
                                }
                              });
                            },
                          ));
                    }),
              ),

              // onPressed: () {
              //   // После выбора пользователей, передаем данные обратно
              //   Navigator.pop(context, selectedUsers);
              // },
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 20, 0, 0),
                child: TextButton(
                  onPressed: () {
                    addChatAdmins(widget.chat);
                    print(
                        "SELECTED ADMINS IDS: ${selectedAdmins.map((user) => user.userId).toList()}");
                    widget.onSelectionComplete(selectedAdmins);
                    Navigator.pop(context, selectedAdmins);
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
                      "Завершить выбор",
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w300),
                    ),
                  ),
                ),
              ),
            ]),
          ),
        ));
  }
}
