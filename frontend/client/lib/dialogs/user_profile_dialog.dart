// ignore_for_file: avoid_print
import 'package:client/models/chat.dart';
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
  final Chat chat;

  UserProfileDialog({
    required this.auth,
    required this.user,
    required this.nameController,
    required this.chat,
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
  final Chat chat;
  List<UserProfile> adminMembers = [];
  List<UserProfile> regularMembers = [];
  bool isLoading = true;
  late UserProfile userToRemove;
  late String department;
  late String role;
  late int department_id;

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
        await dio.get('http://localhost:8000/userprofiles/',
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

  Future getEmployeesDepartment(UserProfile user) async {
    var dio = Dio();
    Response returnedResult =
        await dio.get('http://localhost:8000/userprofiles/',
            options: Options(headers: {
              'Authorization': "Bearer ${widget.auth.token}",
            }));
    print("fetching users");
    print(returnedResult.data);
    print("USER ID" + user.userId.toString());

    String resp_department = '';
    String resp_role = '';
    int resp_department_id = 0;

    for (int i = 0; i < (returnedResult.data as List<dynamic>).length; i++) {
      print(widget.auth.userId);
      List<dynamic> departmentEmployees =
          returnedResult.data[i]['department_employee'];
      for (int j = 0; j < departmentEmployees.length; j++) {
        if (departmentEmployees[j]['user_id'].toString() ==
            user.userId.toString()) {
          print("IF WORKED");
          print("fetch resp_department");
          resp_department =
              departmentEmployees[j]['department_name'].toString();
          print("fetch resp_role");
          resp_role = departmentEmployees[j]['role'].toString();
          print("fetch resp_department_id");
          resp_department_id = departmentEmployees[j]['department_id'];
          break; // Найден нужный департамент, выходим из цикла
        }
      }
    }
    print("RESP DEPARTMENT " + resp_department);
    print("RESP ROLE " + resp_role);
    print("RESP DEPARTMENT ID " + resp_department_id.toString());

    setState(() {
      department = resp_department;
      role = resp_role;
      department_id = resp_department_id;
    });
  }

  Future<void> fetchData() async {
    try {
      print(user.userId);
      await getEmployeesDepartment(user);
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
        content: Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: SizedBox(
            width: 360,
            height: 420,
            child: SingleChildScrollView(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.fromLTRB(0, 10, 0, 40),
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
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(width: 20),
                        // Левая часть: заголовки
                        Container(
                          width: 120, // ширина левой части
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Имя:',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 25),
                              const Text(
                                'Фамилия:',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 25),
                              const Text(
                                'Отчество:',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 25),
                              if (department != '') ...[
                                const SizedBox(height: 25),
                                const Text(
                                  'Отдел:',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                              if (role != '') ...[
                                const SizedBox(height: 25),
                                const Text(
                                  'Должность:',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(
                            width: 20), // отступ между левой и правой частями
                        // Правая часть: значения
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user.name,
                                style: const TextStyle(fontSize: 16),
                              ),
                              const SizedBox(height: 25),
                              Text(
                                user.lastname,
                                style: const TextStyle(fontSize: 16),
                              ),
                              const SizedBox(height: 25),
                              Text(
                                user.middlename,
                                style: const TextStyle(fontSize: 16),
                              ),
                              if (department != '') ...[
                                const SizedBox(height: 25),
                                Text(
                                  department,
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ],
                              if (role != '') ...[
                                const SizedBox(height: 25),
                                Text(
                                  role,
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
