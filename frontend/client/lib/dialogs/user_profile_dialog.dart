import 'package:client/models/chats.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../functions/extract_name.dart';
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

class UserProfileDialog extends StatefulWidget {
  Auth auth;
  final UserProfile user;
  final TextEditingController nameController;
  final Chats chat;
  final Function(int chatId, String name, String avatar, int membersCount,
      int adminId, String isGroupChat) onChatUpdated;

  UserProfileDialog({
    required this.auth,
    required this.user,
    required this.nameController,
    required this.chat,
    required this.onChatUpdated,
  });

  @override
  _UserProfileDialogState createState() => _UserProfileDialogState(
        user: user,
        nameController: nameController,
        chat: chat,
      );
}

class _UserProfileDialogState extends State<UserProfileDialog> {
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

  _UserProfileDialogState({
    //required this.admins,
    //required this.users,
    required this.user,
    //required this.members,
    //required this.outOfChatMembers,
    required this.nameController,
    required this.chat,
  });

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
        print(returnedResult.data);

        for (int i = 0;
            i < (returnedResult.data as List<dynamic>).length;
            i++) {
          if (returnedResult.data[i]['user_id'] == memberId) {
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

    setState(() {
      members = result;
    });
  }

  Future getUser(UserProfile user) async {
    var dio = Dio();
    Response returnedResult =
        await dio.get('http://localhost:8000/userprofiles/${user.userId}',
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

  Future<void> fetchData() async {
    try {
      await getChatMembersDetails();
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

  @override
  void initState() {
    print('doing init');
    super.initState();
    fetchData();
  }

  @override
  Widget build(BuildContext context) {
    print(user.lastname + " " + user.name);
    print("called user profile");
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

    return WillPopScope(
      onWillPop: () async {
        return true;
      },
      child: AlertDialog(
        contentPadding: const EdgeInsets.all(5),
        titlePadding: const EdgeInsets.all(0.0),
        title: Container(
            padding: const EdgeInsets.fromLTRB(0, 0, 0, 8),
            child: Center(
                child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _getCloseButton(context, () {
                  setState(() {});
                }),
                const Text(
                  "Профиль пользователя",
                ),
              ],
            ))),
        content: SizedBox(
          width: 360,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25),
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
                        image: NetworkImage(widget.user.avatar),
                        height: 120,
                        width: 120,
                      ),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text("${user.name} ${user.lastname}",
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.w500)),
                ),
                Text(
                  'Отдел: ',
                  textAlign: TextAlign.left,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                // Глава отдела
                Text(
                  'Глава отдела:',
                  textAlign: TextAlign.left,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                // Должность
                Text(
                  'Должность:',
                  textAlign: TextAlign.left,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
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
                getChatMembersDetails();
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
