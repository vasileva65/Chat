// идея этого класса в том чтобы организовать передачу информации между диалоговыми окнами

import 'package:client/models/chats.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../models/userProfile.dart';

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

class GroupChatSettingsDialog extends StatelessWidget {
  final List<int> admins;
  final List<UserProfile> users;
  final UserProfile user;
  final List<UserProfile> members;
  final List<UserProfile> outOfChatMembers;
  final TextEditingController nameController;
  final Chats chat;

  GroupChatSettingsDialog({
    required this.admins,
    required this.users,
    required this.user,
    required this.members,
    required this.outOfChatMembers,
    required this.nameController,
    required this.chat,
  });

  @override
  Widget build(BuildContext context) {
    print("called groupChat");
    List<UserProfile> adminMembers =
        members.where((member) => admins.contains(member.userId)).toList();

    List<UserProfile> regularMembers =
        members.where((member) => !admins.contains(member.userId)).toList();

    List<UserProfile> sortedMembers = [...adminMembers, ...regularMembers];
    return AlertDialog(
      contentPadding: EdgeInsets.fromLTRB(5, 5, 5, 20),
      titlePadding: const EdgeInsets.all(0.0),
      title: Container(
          padding: const EdgeInsets.fromLTRB(0, 0, 0, 20),
          child: Center(
              child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _getCloseButton(context),
              const Text("Информация о чате"),
            ],
          ))),
      content: Scrollbar(
        interactive: false, // Отключаем интерактивность ползунка
        thumbVisibility: false,
        thickness: 6.0, // Регулирует толщину ползунка
        radius: Radius.circular(4.0), // Регулирует скругление углов ползунка
        //controller: privateChatSettingsScrollController,
        child: ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
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
                        nameController.text,
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
                                  // Действие при нажатии на кнопку плюс
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
                      print(chat.adminId == user.userId);
                      if (admins.contains(user.userId)) {
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
                            trailing: const Tooltip(
                              message: "Отозвать права администратора",
                              child: Icon(
                                Icons.group_remove_outlined,
                                color: Colors.black,
                              ),
                            ),
                            leading: CircleAvatar(
                              backgroundColor: Colors.white,
                              backgroundImage:
                                  NetworkImage(adminMembers[index].avatar),
                            ),
                            minVerticalPadding: 15.0,
                            onTap: () {},
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
                            onTap: () {},
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
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AddMembersDialog(
                                        users: users,
                                        members: members,
                                        outOfChatMembers: outOfChatMembers,
                                      );
                                    },
                                  );
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
                            trailing: const Tooltip(
                              message: 'Удалить участника',
                              child: Icon(
                                Icons.group_remove_outlined,
                                color: Colors.black,
                              ),
                            ),
                            leading: CircleAvatar(
                              backgroundColor: Colors.white,
                              backgroundImage:
                                  NetworkImage(regularMembers[index].avatar),
                            ),
                            minVerticalPadding: 15.0,
                            onTap: () {},
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
                            onTap: () {},
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
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.w300),
              ),
            ),
          ),
        ),
      ],

      // // Кнопка добавления участников
      // if (admins.contains(user.userId))
      //   ElevatedButton(
      //     onPressed: () async {
      //       final addMembersResult = await showDialog(
      //         context: context,
      //         builder: (ctx) => AddMembersDialog(
      //           members: members,
      //           outOfChatMembers: outOfChatMembers,
      //         ),
      //       );

      //       // Проверяем результат после закрытия диалогового окна добавления участников
      //       if (addMembersResult != null &&
      //           addMembersResult is List<UserProfile>) {
      //         // Обновляем данные после закрытия диалогового окна добавления участников
      //         Navigator.of(context).pop(addMembersResult);
      //       }
      //     },
      //     child: Text('Добавить участника'),
      //   ),
    );
  }
}

class AddMembersDialog extends StatefulWidget {
  List<UserProfile> users;
  List<UserProfile> members;
  final List<UserProfile> outOfChatMembers;

  AddMembersDialog({
    required this.users,
    required this.members,
    required this.outOfChatMembers,
  });
  @override
  _AddMembersDialogState createState() => _AddMembersDialogState();
}

class _AddMembersDialogState extends State<AddMembersDialog> {
  TextEditingController searchUserController = TextEditingController();
  List<UserProfile> dublicateOutOfChatMembers = [];
  List<UserProfile> outOfChatMembers = [];
  List<UserProfile> selectedUsers = [];

  @override
  Widget build(BuildContext context) {
    print("ADD MEMBER CALLED");
    outOfChatMembers =
        widget.users.where((user) => !widget.members.contains(user)).toList();
    dublicateOutOfChatMembers = outOfChatMembers;
    return AlertDialog(
      titlePadding: const EdgeInsets.all(0.0),
      title: Container(
          padding: const EdgeInsets.fromLTRB(0, 0, 0, 20),
          child: Center(
              child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _getCloseButton(context),
              const Text("Добавить участников"),
            ],
          ))),
      content: SizedBox(
        width: 300,
        child: Column(children: [
          Container(
            padding: const EdgeInsets.fromLTRB(0, 10, 0, 0),
            child: TextField(
              onChanged: (query) {
                setState(() {
                  widget.users = dublicateOutOfChatMembers.where((item) {
                    return '${item.name.toLowerCase()} ${item.lastname.toLowerCase()}'
                            .contains(query) ||
                        item.name.toLowerCase() + item.lastname.toLowerCase() ==
                            query.toLowerCase() ||
                        item.name.toLowerCase().contains(query.toLowerCase()) ||
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
                  contentPadding:
                      EdgeInsets.only(right: 10, top: 10, bottom: 10, left: 15),
                  focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                          width: 1, color: Color.fromARGB(255, 37, 87, 153))),
                  border: OutlineInputBorder(borderSide: BorderSide())),
            ),
          ),
          Expanded(
            child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(0, 20, 0, 0),
                scrollDirection: Axis.vertical,
                shrinkWrap: true,
                itemCount: widget.users.length,
                itemBuilder: (context, index) {
                  return Padding(
                      padding: const EdgeInsets.fromLTRB(0, 6, 0, 6),
                      child: CheckboxListTile(
                        value: widget.outOfChatMembers
                            .contains(widget.users[index]),
                        //_isChecked[users[index].userId] ??
                        //false,
                        ////_isChecked[index],
                        title: Text(
                            '${widget.users[index].name} ${widget.users[index].lastname}'),
                        secondary: CircleAvatar(
                            backgroundColor:
                                const Color.fromARGB(1, 255, 255, 255),
                            backgroundImage:
                                NetworkImage(widget.users[index].avatar)),
                        onChanged: (bool? value) {
                          setState(() {
                            if (value != null) {
                              //int originalIndex = dublicateUsers.indexOf(users[index]);
                              //_isChecked[originalIndex] = value;
                              //_isChecked[users[index].userId] = value;
                              if (value) {
                                widget.outOfChatMembers
                                    .add(widget.users[index]);
                                //selectedUsers.add(users[index]);
                              } else {
                                widget.outOfChatMembers
                                    .remove(widget.users[index]);
                                //selectedUsers.remove(users[index]);
                              }
                            }
                          });
                        },
                      ));
                }),
          ),
          ElevatedButton(
            onPressed: () {
              // После выбора пользователей, передаем данные обратно
              Navigator.pop(context, selectedUsers);
            },
            child: const Text('Завершить выбор'),
          ),
        ]),
      ),
    );
  }
}
