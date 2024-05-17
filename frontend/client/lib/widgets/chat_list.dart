import 'dart:io';

import 'package:client/dialogs/buttons.dart';
import 'package:client/dialogs/chatlist_dialogs.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:client/models/chat.dart';
import 'package:client/models/auth.dart';
import 'package:image_picker/image_picker.dart';
import '../functions/extract_name.dart';
import '../models/department.dart';
import '../models/roles.dart';
import '../models/userProfile.dart';
import 'package:file_picker/file_picker.dart';

import 'login_page.dart';

typedef ChatUpdated = void Function(int chatId, String name, String avatar,
    int membersCount, int adminId, String isGroupChat);
typedef UpdateUserData = void Function(UserProfile updatedUserData);
typedef OnChatListUpdated = void Function();

class ChatList extends StatefulWidget {
  Auth auth;
  UserProfile userData;
  Chat chat;
  Set<String> updatedChats;
  final UpdateUserData updateUserData;
  ChatUpdated onChatUpdated;
  OnChatListUpdated onChatListUpdated;
  bool reloadNeeded;
  ChatList(this.auth, this.userData, this.chat, this.updatedChats,
      {required this.onChatListUpdated,
      required this.reloadNeeded,
      required this.updateUserData,
      required this.onChatUpdated,
      Key? key})
      : super(key: key);

  @override
  State<ChatList> createState() => _ChatListState();
}

class _ChatListState extends State<ChatList> {
  List<Chat> items = [];
  List<Chat> dublicateItems = [];
  List<UserProfile> users = [];
  List<UserProfile> dublicateUsers = [];
  List<UserProfile> selectedUsers = [];
  bool isSelected = false;
  UserProfile? selectedUser;
  final dio = Dio();
  late Chat chat;
  ScrollController scrollGroupChatController = ScrollController();
  ScrollController scrollPrivateChatController = ScrollController();
  TextEditingController searchChatController = TextEditingController();
  TextEditingController searchUserController = TextEditingController();

  TextEditingController nameController = TextEditingController();
  TextEditingController lastnameController = TextEditingController();
  TextEditingController middlenameController = TextEditingController();
  final chatNameController = TextEditingController();
  //late List<bool> _isChecked;
  //late Map<String, bool> _isChecked; // Используем Map с типом ключа String
  late Set<String> selectedUserIds;
  Chat? selectedChat;

  bool isExpanded = false;

  late List<Role> roles;
  late List<Department> departments;

  late String userDepartment;
  late String userRole;
  bool isLoading = true;

  // void updateChatData(Chats updatedChatData) {
  //   setState(() {
  //     widget.chat = updatedChatData;
  //   });
  // }

  Future getChats() async {
    Response returnedResult = await dio.get('http://localhost:8000/chatmembers',
        options: Options(headers: {
          'Authorization': "Bearer ${widget.auth.token}",
        }));
    print("fetching chats");
    print(returnedResult.data);

    widget.onChatListUpdated();

    List<Chat> result = [];

    for (int i = 0; i < (returnedResult.data as List<dynamic>).length; i++) {
      // print(widget.auth.userId);
      // print('user name:');
      // print(widget.userData.userId);
      // print(widget.userData.name);

      if (returnedResult.data[i]['user_id'].toString() == widget.auth.userId) {
        Chat chat = Chat(
            returnedResult.data[i]['chat_id'],
            returnedResult.data[i]['chat_name'],
            returnedResult.data[i]['avatar'],
            returnedResult.data[i]['people_count'],
            returnedResult.data[i]['user_id'],
            returnedResult.data[i]['group_chat']);
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
      if (scrollGroupChatController.hasClients) {
        scrollGroupChatController.animateTo(0.0,
            duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    }
  }

  void showChatExistsWarning(BuildContext context) {
    OverlayEntry? overlayEntry;

    overlayEntry = OverlayEntry(
        builder: (BuildContext context) => Stack(children: <Widget>[
              // Показываем диалоговое окно поверх предупреждения
              Center(
                child: Material(
                  color: Colors.transparent,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      AlertDialog(
                        title: Text(
                            'Такой чат уже существует.\nИзмените имя или список участников'),
                        actions: <Widget>[
                          TextButton(
                            onPressed: () {
                              overlayEntry?.remove(); // Закрыть предупреждение
                            },
                            child: Text('OK'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ]));

    Overlay.of(context).insert(overlayEntry);
  }

  Future addNewGroupChat(BuildContext context) async {
    print('add new group chat called');
    try {
      FormData formData = FormData();

      // Добавляем поля к FormData
      formData.fields.add(MapEntry('chat_name', chatNameController.text));
      for (var userId in selectedUserIds) {
        formData.fields.add(MapEntry('user_ids', userId));
      }
      formData.fields
          .add(MapEntry('admin_id', widget.userData.userId.toString()));
      formData.fields.add(MapEntry('group_chat', 'true'));

      // Проверяем, есть ли выбранная аватара, и добавляем ее к FormData
      if (selectedFile != null) {
        formData.files.add(MapEntry(
            'avatar',
            await MultipartFile.fromFile(selectedFile!.path,
                filename: selectedFile!.path.split('/').last)));
      } else {
        // Добавляем пустое поле avatar для совместимости
        formData.files
            .add(MapEntry('avatar', MultipartFile.fromBytes([], filename: '')));
      }

      // Отправляем запрос на сервер с использованием FormData
      Response response = await dio.post(
        'http://localhost:8000/chats/create_chat/',
        data: formData,
        options: Options(headers: {
          'Authorization': "Bearer ${widget.auth.token}",
          'Content-Type': 'multipart/form-data',
        }),
      );
      print(response);
      print(response.data);
      Navigator.of(context).pop();
      // Clear the text field controllers
      chatNameController.clear();
      searchUserController.clear();
      selectedUserIds.clear();
      selectedFile = null;
    } on DioError catch (e) {
      print('Error: $e');
      if (e.response != null) {
        if (e.response!.statusCode == 401) {
          Navigator.pop(context);
        }
        if (e.response!.statusCode == 500) {
          String errorMessage = e.response!.data.toString();
          if (errorMessage.contains(
              "A chat with the same participants and name already exists.")) {
            print(errorMessage);
            print("A chat with the same participants and name already exists.");
            showChatExistsWarning(context);
          }
        }
      }
      return;
    }

    print('AddNewChat called');
    await getChats();

    if (scrollGroupChatController.hasClients) {
      scrollGroupChatController.animateTo(0.0,
          duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }
  }

  Future addNewPersonalChat() async {
    print('add new group chat called');
    try {
      FormData formData = FormData();

      // Добавляем поля к FormData
      formData.fields
          .add(MapEntry('chat_name', '')); // Пустое имя чата для личного чата
      formData.fields
          .add(MapEntry('user_ids', [selectedUser?.userId].join(',')));
      formData.fields
          .add(MapEntry('admin_id', widget.userData.userId.toString()));
      formData.fields.add(MapEntry('group_chat', 'false'));

      if (selectedFile != null) {
        formData.files.add(MapEntry(
            'avatar',
            await MultipartFile.fromFile(selectedFile!.path,
                filename: selectedFile!.path.split('/').last)));
      } else {
        // Добавляем пустое поле avatar для совместимости
        formData.files
            .add(MapEntry('avatar', MultipartFile.fromBytes([], filename: '')));
      }

      // Отправляем запрос на сервер с использованием FormData
      Response response = await dio.post(
        'http://localhost:8000/chats/create_chat/',
        data: formData,
        options: Options(headers: {
          'Authorization': "Bearer ${widget.auth.token}",
          'Content-Type': 'multipart/form-data',
        }),
      );
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

    if (scrollGroupChatController.hasClients) {
      scrollGroupChatController.animateTo(0.0,
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

      int userId = returnedResult.data[i]['user_id'];

      if (returnedResult.data[i]['user_id'].toString() != widget.auth.userId &&
          !result.any((user) => user.userId == userId)) {
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
    print("USERS FRON GET USERS");
    for (var user in result) {
      print(user.userId);
    }

    setState(() {
      users = result;
      dublicateUsers = result;
      selectedUserIds = Set<String>();
      // _isChecked = Map<String, bool>.fromIterable(
      //   users,
      //   key: (user) => user.userId,
      //   value: (_) => false,
      // );
      //_isChecked = List<bool>.filled(users.length, false);
    });
  }

  @override
  void initState() {
    super.initState();
    getChats();
    items = dublicateItems;
    print("init state called");

    getUsers();
    users = dublicateUsers;
    fetchUserData();
    // fetchData(widget.userData);
  }

  void selectChat(Chat chat) {
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

  void filterUsers(String query) {
    print("Query: $query");
    print("Original users: $dublicateUsers");
    setState(() {
      if (query.isEmpty) {
        // If the query is empty, show all users
        users = dublicateUsers.toList();
      } else {
        users = dublicateUsers.where((item) {
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
      print("Updated users: $users");
    });
  }

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

  Future getUserRoleDepartment(UserProfile user) async {
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
      userDepartment = resp_department;
      userRole = resp_role;
      // department_id = resp_department_id;
    });
  }

  Future getRoles() async {
    var dio = Dio();
    Response returnedResult = await dio.get('http://localhost:8000/roles/',
        options: Options(headers: {
          'Authorization': "Bearer ${widget.auth.token}",
        }));
    print("fetching roles");
    print(returnedResult.data);
    List<Role> result = [];
    for (int i = 0; i < (returnedResult.data as List<dynamic>).length; i++) {
      print(widget.auth.userId);
      Role role = Role(returnedResult.data[i]['role_id'],
          returnedResult.data[i]['role_name']);
      result.add(role); // Найден нужный департамент, выходим из цикла
    }
    print('Список roles:');
    for (Role role in result) {
      print(role.name);
    }
    setState(() {
      roles = result;
    });
  }

  Future getDepartments() async {
    var dio = Dio();
    Response returnedResult =
        await dio.get('http://localhost:8000/departments/',
            options: Options(headers: {
              'Authorization': "Bearer ${widget.auth.token}",
            }));
    print("fetching departments");
    print(returnedResult.data);
    List<Department> result = [];
    for (int i = 0; i < (returnedResult.data as List<dynamic>).length; i++) {
      print(widget.auth.userId);
      Department department = Department(
          returnedResult.data[i]['department_id'],
          returnedResult.data[i]['department_name']);
      result.add(department); // Найден нужный департамент, выходим из цикла
    }

    print('Список отделов:');
    for (Department department in result) {
      print(department.name);
    }
    setState(() {
      departments = result;
    });
  }

  Future updateUserSettings(
      UserProfile userData, String department, String role) async {
    print('add new group chat called');
    try {
      Response response = await dio.patch(
          'http://localhost:8000/user/profile/${userData.userId}/',
          data: {
            'user_id': userData.userId,
            'user': {
              'first_name': nameController.text,
              'last_name': lastnameController.text,
              'middle_name': middlenameController.text,
            },
            'department_employee': {
              'department_name': department,
              'role': role,
            },
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

    print('updateUserSettings called');
  }

  Future<void> fetchData(UserProfile user) async {
    try {
      nameController.text = widget.userData.name;
      lastnameController.text = widget.userData.lastname;
      middlenameController.text = widget.userData.middlename;
      await getUserRoleDepartment(user);
      await getRoles();
      await getDepartments();
      //await getUsers();

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

  File? selectedFile;

// Функция для выбора файла
  Future<void> pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null) {
      String? filePath = result.files.single.path;
      if (filePath != null) {
        // Обновите переменную selectedFile выбранным файлом
        setState(() {
          selectedFile = File(filePath);
        });
      } else {
        // Если пользователь не выбрал файл (нажал "Отмена" или закрыл диалоговое окно), сбросьте выбранное изображение
        setState(() {
          selectedFile = null;
        });
      }
    }
  }

  Future fetchUserData() async {
    Response returnedResult = await dio.get(
        'http://localhost:8000/user/profile/${widget.userData.userId}',
        options: Options(headers: {
          'Authorization': "Bearer ${widget.auth.token}",
        }));
    print("USER DATA");
    print(returnedResult.data);
    late UserProfile user;

    user = UserProfile(
        returnedResult.data['user_id'],
        returnedResult.data['user']['username'],
        returnedResult.data['user']['first_name'],
        returnedResult.data['user']['last_name'],
        returnedResult.data['user']['middle_name'],
        returnedResult.data['avatar']);

    print("PROFILE");

    setState(() {
      widget.userData = user;
      widget.updateUserData(user);
    });
  }

// Функция для загрузки аватара на сервер
  Future<void> uploadAvatar(UserProfile user) async {
    if (selectedFile != null) {
      Dio dio = Dio();

      try {
        FormData formData = FormData.fromMap({
          'avatar': await MultipartFile.fromFile(selectedFile!.path,
              filename: selectedFile!.path.split('/').last),
        });

        Response response = await dio.patch(
          'http://localhost:8000/user/profile/${user.userId}/',
          data: formData,
          options: Options(headers: {
            'Authorization': "Bearer ${widget.auth.token}",
          }),
        );

        if (response.statusCode == 200) {
          print('Avatar uploaded successfully');
        } else {
          print('Failed to upload avatar');
        }
      } catch (e) {
        print('Error uploading avatar: $e');
      }
    } else {
      print('No file selected');
    }
    await fetchUserData();
    setState(() {
      selectedFile = null;
    });
  }

  Future<void> logout() async {
    try {
      Response response = await dio.post('http://localhost:8000/logout/',
          data: {'refresh_token': widget.auth.refreshToken},
          options: Options(headers: {
            'Authorization': "Bearer ${widget.auth.token}",
          }));
      print("logout");
      print(response.data);
      if (response.statusCode == 205) {
        // Успешный выход из приложения
        print("Logged out successfully");
        // Здесь вы можете выполнить какие-либо дополнительные действия, например, переход на экран входа в приложение
      } else {
        // Обработка других статусов ответа, если это необходимо
        print("Failed to log out");
      }
    } catch (e) {
      // Обработка ошибок, возникших во время отправки запроса
      print("Error during logout: $e");
    }
    setState(() {});
  }

  void logoutWarning(BuildContext context) {
    showDialog<String>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Подтвердите выход'),
        content:
            const Text('Вы уверены, что хотите выйти\nиз своего аккаунта?'),
        actions: <Widget>[
          Row(
            children: [
              Expanded(
                child: TextButton(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.all(16.0),
                    backgroundColor: Color.fromARGB(255, 37, 87, 153),
                  ),
                  onPressed: () async {
                    final navigator = Navigator.of(context);
                    // Вызываем logout() и дожидаемся его завершения
                    await logout();
                    // После завершения logout() переходим на страницу логина
                    navigator.pushReplacement(
                        MaterialPageRoute(builder: (context) => LoginPage()));
                  },
                  child: const Text(
                    'Да',
                    style: TextStyle(
                      color: Color.fromARGB(255, 213, 225, 241),
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: TextButton(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.all(16.0),
                    backgroundColor: Color.fromARGB(255, 240, 240, 240),
                  ),
                  onPressed: () => Navigator.pop(context, 'Нет'),
                  child: const Text(
                    'Нет',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void userSettings() {
    // await fetchData(widget.userData);
    print("user settings called");
    showDialog(
        context: context,
        builder: (ctx) {
          return StatefulBuilder(
              builder: (BuildContext context, StateSetter dialogSetState) {
            // Начинаем загрузку данных
            if (isLoading) {
              fetchData(widget.userData).then((_) {
                // Обновляем состояние диалогового окна после загрузки данных
                dialogSetState(() {});
              });
            }

            // Возвращаем содержимое диалогового окна в зависимости от состояния isLoading
            return isLoading
                ? const SizedBox(
                    height: 30,
                    width: 30,
                    child: Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 3.0,
                        color: Colors.white,
                      ),
                    ),
                  )
                : WillPopScope(
                    onWillPop: () async {
                      // Обнуляем selectedFile при закрытии диалогового окна
                      setState(() {
                        selectedFile = null;
                      });
                      return true; // Разрешаем закрытие диалога
                    },
                    child: StatefulBuilder(
                        builder: (BuildContext context, StateSetter setState) {
                      return AlertDialog(
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
                        content: SizedBox(
                          width: 300,
                          child: StatefulBuilder(builder:
                              (BuildContext context, StateSetter setState) {
                            return Column(
                              children: [
                                Container(
                                  padding:
                                      const EdgeInsets.fromLTRB(0, 0, 0, 40),
                                  child: Material(
                                    elevation: 8,
                                    shape: const CircleBorder(),
                                    clipBehavior: Clip.antiAliasWithSaveLayer,
                                    child: InkWell(
                                      // splashColor: Colors.black26,
                                      onTap: () async {
                                        await pickFile();
                                        setState(() {});
                                      },
                                      child: Ink.image(
                                        image: selectedFile != null
                                            ? FileImage(selectedFile!)
                                                as ImageProvider
                                            : NetworkImage(
                                                widget.userData.avatar),
                                        height: 120,
                                        width: 120,
                                      ),
                                    ),
                                  ),
                                ),

                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(width: 20),
                                    // Левая часть: заголовки
                                    Container(
                                      width: 120, // ширина левой части
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Имя\nпользователя:',
                                            style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold),
                                          ),
                                          const SizedBox(height: 25),
                                          const Text(
                                            'Имя:',
                                            style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold),
                                          ),
                                          const SizedBox(height: 25),
                                          const Text(
                                            'Фамилия:',
                                            style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold),
                                          ),
                                          const SizedBox(height: 25),
                                          const Text(
                                            'Отчество:',
                                            style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold),
                                          ),
                                          if (userDepartment != '') ...[
                                            const SizedBox(height: 25),
                                            const Text(
                                              'Отдел:',
                                              style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                          ],
                                          if (userRole != '') ...[
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
                                        width:
                                            20), // отступ между левой и правой частями
                                    // Правая часть: значения
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                            0, 20, 0, 0),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              widget.userData.username,
                                              style:
                                                  const TextStyle(fontSize: 16),
                                            ),
                                            const SizedBox(height: 25),
                                            Text(
                                              widget.userData.name,
                                              style:
                                                  const TextStyle(fontSize: 16),
                                            ),
                                            const SizedBox(height: 25),
                                            Text(
                                              widget.userData.lastname,
                                              style:
                                                  const TextStyle(fontSize: 16),
                                            ),
                                            const SizedBox(height: 25),
                                            Text(
                                              widget.userData.middlename,
                                              style:
                                                  const TextStyle(fontSize: 16),
                                            ),
                                            if (userDepartment != '') ...[
                                              const SizedBox(height: 25),
                                              Text(
                                                userDepartment,
                                                style: const TextStyle(
                                                    fontSize: 16),
                                              ),
                                            ],
                                            if (userRole != '') ...[
                                              const SizedBox(height: 25),
                                              Text(
                                                userRole,
                                                style: const TextStyle(
                                                    fontSize: 16),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                // Если делать настройки, которые можно менять
                                // Container(
                                //   padding: const EdgeInsets.symmetric(vertical: 8),
                                //   child: TextFormField(
                                //     controller: nameController,
                                //     readOnly: true,
                                //     decoration: const InputDecoration(
                                //         focusedBorder: OutlineInputBorder(
                                //             borderSide: BorderSide(
                                //                 width: 1,
                                //                 color: Color.fromARGB(255, 37, 87, 153))),
                                //         border: OutlineInputBorder(),
                                //         labelText: 'Имя',
                                //         hintText: 'Введите имя'),
                                //   ),
                                // ),
                                // Container(
                                //   padding: const EdgeInsets.symmetric(vertical: 8),
                                //   child: TextFormField(
                                //     controller: lastnameController,
                                //     decoration: const InputDecoration(
                                //         focusedBorder: OutlineInputBorder(
                                //             borderSide: BorderSide(
                                //                 width: 1,
                                //                 color: Color.fromARGB(255, 37, 87, 153))),
                                //         border: OutlineInputBorder(),
                                //         labelText: 'Фамилия',
                                //         hintText: 'Введите фамилию'),
                                //   ),
                                // ),
                                // Container(
                                //   padding: const EdgeInsets.symmetric(vertical: 8),
                                //   child: TextFormField(
                                //     controller: middlenameController,
                                //     decoration: const InputDecoration(
                                //         focusedBorder: OutlineInputBorder(
                                //             borderSide: BorderSide(
                                //                 width: 1,
                                //                 color: Color.fromARGB(255, 37, 87, 153))),
                                //         border: OutlineInputBorder(),
                                //         labelText: 'Отчество',
                                //         hintText: 'Введите отчество'),
                                //   ),
                                // ),
                                // Container(
                                //   padding: const EdgeInsets.symmetric(vertical: 8),
                                //   child: SingleChildScrollView(
                                //     child: DropdownButtonFormField<String>(
                                //       value: userDepartment,
                                //       decoration: const InputDecoration(
                                //         focusedBorder: OutlineInputBorder(
                                //             borderSide: BorderSide(
                                //                 width: 1,
                                //                 color: Color.fromARGB(255, 37, 87, 153))),
                                //         border: OutlineInputBorder(),
                                //         labelText: 'Отдел',
                                //       ),
                                //       isExpanded: true,
                                //       items: departments.map((Department department) {
                                //         return DropdownMenuItem<String>(
                                //           value: department.name,
                                //           child: Text(department.name),
                                //         );
                                //       }).toList(),
                                //       onChanged: (String? newValue) {
                                //         if (newValue != null) {
                                //           setState(() {
                                //             userDepartment = newValue;
                                //           });
                                //         }
                                //       },
                                //     ),
                                //   ),
                                // ),
                                // Container(
                                //   padding: const EdgeInsets.symmetric(vertical: 8),
                                //   child: SingleChildScrollView(
                                //     child: DropdownButtonFormField<String>(
                                //       value: userRole,
                                //       decoration: const InputDecoration(
                                //         focusedBorder: OutlineInputBorder(
                                //             borderSide: BorderSide(
                                //                 width: 1,
                                //                 color: Color.fromARGB(255, 37, 87, 153))),
                                //         border: OutlineInputBorder(),
                                //         labelText: 'Должность',
                                //       ),
                                //       isExpanded: true,
                                //       items: roles.map((Role role) {
                                //         return DropdownMenuItem<String>(
                                //           value: role.name,
                                //           child: Text(role.name),
                                //         );
                                //       }).toList(),
                                //       onChanged: (String? newValue) {
                                //         if (newValue != null) {
                                //           setState(() {
                                //             userRole = newValue;
                                //           });
                                //         }
                                //       },
                                //     ),
                                //   ),
                                // ),
                              ],
                            );
                          }),
                        ),
                        actions: <Widget>[
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: TextButton(
                              onPressed: () async {
                                await uploadAvatar(widget.userData);
                                Navigator.of(ctx).pop();
                              },
                              style: ButtonStyle(
                                  backgroundColor:
                                      const MaterialStatePropertyAll<Color>(
                                          Color.fromARGB(255, 37, 87, 153)),
                                  shape: MaterialStateProperty.all<
                                          RoundedRectangleBorder>(
                                      RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(5.0),
                                  ))),
                              child: Container(
                                padding:
                                    const EdgeInsets.fromLTRB(20, 10, 20, 10),
                                child: const Text(
                                  "Сохранить",
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w300),
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    }),
                  );
          });
        });
  }

  void showUserWarning(BuildContext context) {
    OverlayEntry? overlayEntry;

    overlayEntry = OverlayEntry(
        builder: (BuildContext context) => Stack(children: <Widget>[
              // Показываем диалоговое окно поверх предупреждения
              Center(
                child: Material(
                  color: Colors.transparent,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      AlertDialog(
                        title: Text('Вы не выбрали пользователей'),
                        actions: <Widget>[
                          TextButton(
                            onPressed: () {
                              overlayEntry?.remove(); // Закрыть предупреждение
                            },
                            child: Text('OK'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ]));

    Overlay.of(context).insert(overlayEntry);
  }

  void addGroupChat() {
    showDialog(
      context: context,
      builder: (ctx) => WillPopScope(
        onWillPop: () async {
          // Сбрасываем поля при закрытии диалога
          chatNameController.clear();
          searchUserController.clear();
          selectedUserIds.clear();
          filterUsers('');

          return true; // Разрешаем закрытие диалога
        },
        child: AlertDialog(
          titlePadding: const EdgeInsets.all(0.0),
          title: Container(
              padding: const EdgeInsets.fromLTRB(0, 0, 0, 8),
              child: Center(child: Builder(builder: (context) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _getCloseButton(context, () {
                      setState(() {
                        chatNameController.clear();
                        searchUserController.clear();
                        selectedUserIds.clear();
                        filterUsers('');
                        selectedFile = null;
                      });
                    }),
                    const Text("Создать чат"),
                  ],
                );
              }))),
          content: StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
            return SizedBox(
              width: 340,
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
                          onTap: () async {
                            await pickFile();
                            setState(() {});
                          },
                          child: Ink.image(
                            image: selectedFile != null
                                ? FileImage(selectedFile!) as ImageProvider
                                : const AssetImage('assets/images/default.jpg'),
                            height: 120,
                            width: 120,
                          )),
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
                                value: selectedUserIds
                                    .contains(users[index].userId.toString()),
                                //_isChecked[users[index].userId] ??
                                //false,
                                ////_isChecked[index],
                                title: Text(
                                    '${users[index].name} ${users[index].lastname}'),
                                secondary: CircleAvatar(
                                    backgroundColor:
                                        const Color.fromARGB(1, 255, 255, 255),
                                    backgroundImage:
                                        NetworkImage(users[index].avatar)),
                                onChanged: (bool? value) {
                                  setState(() {
                                    if (value != null) {
                                      //int originalIndex = dublicateUsers.indexOf(users[index]);
                                      //_isChecked[originalIndex] = value;
                                      //_isChecked[users[index].userId] = value;
                                      if (value) {
                                        print(
                                            'selectedUserIds IF: $selectedUserIds');
                                        selectedUserIds.add(
                                            users[index].userId.toString());
                                        //selectedUsers.add(users[index]);
                                      } else {
                                        print(
                                            'selectedUserIds ELSE: $selectedUserIds');
                                        selectedUserIds.remove(
                                            users[index].userId.toString());
                                        //selectedUsers.remove(users[index]);
                                      }
                                    }
                                  });
                                },
                              ));
                        }),
                  )
                ],
              ),
            );
          }),
          actions: <Widget>[
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextButton(
                onPressed: () {
                  if (selectedUserIds.isNotEmpty) {
                    print("if called");
                    addNewGroupChat(context);
                    // Navigator.of(ctx).pop();
                    // // Clear the text field controllers
                    // chatNameController.clear();
                    // searchUserController.clear();
                    // selectedUserIds.clear();
                    // selectedFile = null;
                  } else {
                    print("else called");
                    showUserWarning(context);
                    // selectedUsersCountWarning(context);
                  }

                  // _isChecked = Map<String, bool>.from(
                  //     _isChecked); // Создаем копию текущего состояния

                  // for (String userId in _isChecked.keys) {
                  //   _isChecked[userId] =
                  //       false; // Устанавливаем все значения в false
                  // }
                  //_isChecked = List<bool>.filled(users.length, false);
                  // Clear the selected users list
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
      ),
    );
    print('selectedUserIds: $selectedUserIds');
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
                _getCloseButton(context, () {
                  // Clear the selected users list when the close button is pressed
                  setState(() {
                    searchUserController.clear();
                    selectedUser = null;
                    selectedFile = null;
                    filterUsers('');
                  });
                }),
                const Text("Создать чат"),
              ],
            ))),
        content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
          return SizedBox(
            width: 340,
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
                        onTap: () async {
                          await pickFile();
                          setState(() {});
                        },
                        child: Ink.image(
                          image: selectedFile != null
                              ? FileImage(selectedFile!) as ImageProvider
                              : const AssetImage('assets/images/default.jpg'),
                          height: 120,
                          width: 120,
                        )),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(0, 10, 0, 0),
                  child: TextField(
                    onChanged:
                        // (query) {
                        //   filterUsers(query);
                        // },
                        (query) {
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
                    style: const TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
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
          );
        }),
        actions: <Widget>[
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextButton(
              onPressed: () {
                addNewPersonalChat();
                Navigator.of(ctx).pop();
                searchUserController.clear();
                selectedUser = null;
                selectedFile = null;
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
    print("Chat list build");
    print(widget.updatedChats);

    if (widget.reloadNeeded) {
      getChats();
    }

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      appBar: AppBar(
        title: Row(
          children: [
            Expanded(
              child: ListTile(
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
                onTap: userSettings,
                hoverColor: Colors.transparent,
                splashColor: Colors.transparent,
              ),
            ),
            IconButton(
              splashRadius: 1,
              icon: const Icon(
                Icons.logout,
                color: Colors.grey,
              ),
              onPressed: () {
                // Действие при нажатии кнопки выхода из аккаунта
                // Например, вызов метода для выхода из аккаунта
                //logout();
                logoutWarning(context);
              },
            ),
          ],
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
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
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
                            width: 1, color: Color.fromARGB(255, 37, 87, 153))),
                    border: OutlineInputBorder(borderSide: BorderSide())),
              ),
            ),
          ),
          Expanded(
            child: CustomScrollView(
              slivers: [
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (BuildContext context, int index) {
                      // Блок для отображения групповых чатов
                      var groupItems = items
                          .where((item) => item.isGroupChat == "True")
                          .toList();
                      return Theme(
                        data: Theme.of(context)
                            .copyWith(dividerColor: Colors.transparent),
                        child: ExpansionTile(
                          initiallyExpanded: false,
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
                            ListView.builder(
                              shrinkWrap: true,
                              physics: NeverScrollableScrollPhysics(),
                              itemCount: groupItems.length,
                              itemBuilder: (context, index) {
                                return Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 5),
                                  child: ListTile(
                                    title: Text(
                                      groupItems[index].name,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: Color.fromARGB(255, 39, 77, 126),
                                      ),
                                    ),
                                    trailing: widget.updatedChats.contains(
                                            groupItems[index].chatId.toString())
                                        ? const Icon(
                                            Icons.circle,
                                            color: Colors.red,
                                          )
                                        : null,
                                    leading: CircleAvatar(
                                      backgroundColor:
                                          Color.fromARGB(1, 255, 255, 255),
                                      backgroundImage: NetworkImage(
                                          groupItems[index].avatar),
                                    ),
                                    onTap: () {
                                      print("On chat updated called");
                                      widget.onChatUpdated(
                                          groupItems[index].chatId,
                                          groupItems[index].name,
                                          groupItems[index].avatar,
                                          groupItems[index].membersCount,
                                          groupItems[index].adminId,
                                          groupItems[index].isGroupChat);
                                    },
                                    hoverColor: Colors.transparent,
                                    splashColor: Colors.transparent,
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      );
                    },
                    childCount: 1, // Отображаем только одну группу
                  ),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(
                      height: 20), // Регулируйте высоту по вашему желанию
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (BuildContext context, int index) {
                      // Блок для отображения личных чатов
                      var privateItems = items
                          .where((item) => item.isGroupChat == "False")
                          .toList();
                      return Theme(
                        data: Theme.of(context)
                            .copyWith(dividerColor: Colors.transparent),
                        child: ExpansionTile(
                          initiallyExpanded: false,
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
                          children: [
                            ListView.builder(
                              shrinkWrap: true,
                              physics: NeverScrollableScrollPhysics(),
                              itemCount: privateItems.length,
                              itemBuilder: (context, index) {
                                return Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 5),
                                  child: ListTile(
                                    title: Text(
                                      extractDisplayName(
                                          privateItems[index].name,
                                          widget.userData.name,
                                          widget.userData.lastname),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: Color.fromARGB(255, 39, 77, 126),
                                      ),
                                    ),
                                    leading: CircleAvatar(
                                      backgroundColor:
                                          Color.fromARGB(1, 255, 255, 255),
                                      backgroundImage: NetworkImage(
                                          privateItems[index].avatar),
                                    ),
                                    onTap: () {
                                      widget.onChatUpdated(
                                          privateItems[index].chatId,
                                          privateItems[index].name,
                                          privateItems[index].avatar,
                                          privateItems[index].membersCount,
                                          privateItems[index].adminId,
                                          privateItems[index].isGroupChat);
                                    },
                                    hoverColor: Colors.transparent,
                                    splashColor: Colors.transparent,
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      );
                    },
                    childCount: 1, // Отображаем только один личный чат
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
//             SingleChildScrollView(
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   Flexible(
//                     child: ExpansionTile(
//                       initiallyExpanded: false,
//                       // onExpansionChanged: (expanded) {
//                       //   setState(() {
//                       //     isExpanded = expanded;
//                       //   });
//                       // },
//                       //initiallyExpanded: isExpanded,
//                       title: const Text(
//                         'Группы',
//                         style: TextStyle(fontSize: 18),
//                       ),
//                       trailing: IconButton(
//                         icon: const Icon(
//                           Icons.add,
//                         ),
//                         onPressed: () {
//                           addGroupChat();
//                         },
//                         splashRadius: 1,
//                       ),
//                       children: [
//                         ListView.builder(
//                           padding: const EdgeInsets.symmetric(vertical: 10),
//                           itemCount: items
//                               .where((item) => item.isGroupChat == "True")
//                               .length,
//                           itemBuilder: (context, index) {
//                             var groupItems = items
//                                 .where((item) => item.isGroupChat == "True")
//                                 .toList();
//                             return Padding(
//                               padding: const EdgeInsets.symmetric(vertical: 5),
//                               child: ListTile(
//                                 title: Text(
//                                   groupItems[index].name,
//                                   style: const TextStyle(
//                                     fontSize: 16,
//                                     fontWeight: FontWeight.w500,
//                                     color: Color.fromARGB(255, 39, 77, 126),
//                                   ),
//                                 ),
//                                 leading: CircleAvatar(
//                                   backgroundColor:
//                                       Color.fromARGB(1, 255, 255, 255),
//                                   backgroundImage:
//                                       NetworkImage(groupItems[index].avatar),
//                                 ),
//                                 selectedTileColor:
//                                     Color.fromARGB(17, 255, 255, 255),
//                                 selected: isSelected,
//                                 onTap: () {
//                                   widget.onChatUpdated(
//                                       groupItems[index].chatId,
//                                       groupItems[index].name,
//                                       groupItems[index].avatar,
//                                       groupItems[index].membersCount,
//                                       groupItems[index].adminId,
//                                       groupItems[index].isGroupChat);
//                                 },
//                                 hoverColor: Colors.transparent,
//                                 splashColor: Colors.transparent,
//                               ),
//                             );
//                           },
//                           //controller: scrollGroupChatController
//                         ),
//                       ],
//                     ),
//                   ),
//                   Flexible(
//                     child: ExpansionTile(
//                       initiallyExpanded: false,
//                       // onExpansionChanged: (expanded) {
//                       //   setState(() {
//                       //     isExpanded = expanded;
//                       //   });
//                       // },
//                       title: const Text(
//                         'Личные чаты',
//                         style: TextStyle(fontSize: 18),
//                       ),
//                       trailing: IconButton(
//                         icon: const Icon(
//                           Icons.add,
//                         ),
//                         onPressed: () {
//                           addPersonalChat();
//                         },
//                         splashRadius: 1,
//                       ),
//                       children: [
//                         ListView.builder(
//                           padding: const EdgeInsets.symmetric(vertical: 10),
//                           itemCount: items
//                               .where((item) => item.isGroupChat == "False")
//                               .length,
//                           itemBuilder: (context, index) {
//                             var privateItems = items
//                                 .where((item) => item.isGroupChat == "False")
//                                 .toList();
//                             return Padding(
//                               padding: const EdgeInsets.symmetric(vertical: 5),
//                               child: ListTile(
//                                 title: Text(
//                                   extractDisplayName(
//                                       privateItems[index].name,
//                                       widget.userData.name,
//                                       widget.userData.lastname),
//                                   style: const TextStyle(
//                                     fontSize: 16,
//                                     fontWeight: FontWeight.w500,
//                                     color: Color.fromARGB(255, 39, 77, 126),
//                                   ),
//                                 ),
//                                 leading: CircleAvatar(
//                                   backgroundColor:
//                                       Color.fromARGB(1, 255, 255, 255),
//                                   backgroundImage:
//                                       NetworkImage(privateItems[index].avatar),
//                                 ),
//                                 selectedTileColor:
//                                     Color.fromARGB(17, 255, 255, 255),
//                                 selected: isSelected,
//                                 onTap: () {
//                                   widget.onChatUpdated(
//                                       privateItems[index].chatId,
//                                       privateItems[index].name,
//                                       privateItems[index].avatar,
//                                       privateItems[index].membersCount,
//                                       privateItems[index].adminId,
//                                       privateItems[index].isGroupChat);
//                                 },
//                                 hoverColor: Colors.transparent,
//                                 splashColor: Colors.transparent,
//                               ),
//                             );
//                           },
//                           //controller: scrollPrivateChatController
//                         ),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),

//             ),
//           ],
//         ));
//   }
// }
}
