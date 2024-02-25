import 'package:client/dialogs/chat_dialogs.dart';
import 'package:client/models/chats.dart';
import 'package:client/models/message.dart';
import 'package:client/models/userProfile.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';
import 'package:client/widgets/chat_list.dart';
import 'package:intl/intl.dart';
import 'package:client/models/auth.dart';
import 'package:client/models/userProfile.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:windows_taskbar/windows_taskbar.dart';

import '../functions/extract_name.dart';

class ChatPage extends StatefulWidget {
  Auth auth;
  UserProfile userData;
  Chats chat;
  ChatPage(this.auth, this.userData, this.chat, {super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final myController = TextEditingController();
  final dio = Dio();
  List<Message> items = [];
  List<UserProfile> profiles = [];
  ScrollController scrollController = ScrollController();
  ScrollController privateChatSettingsScrollController = ScrollController();
  bool _isExpanded = false;
  final nameController = TextEditingController();
  List<UserProfile> members = [];
  List<int> admins = [];
  List<UserProfile> dublicateMembers = [];

  late UserProfile secondMember;

  List<UserProfile> users = [];
  List<UserProfile> outOfChatMembers = [];
  List<UserProfile> dublicateOutOfChatMembers = [];
  TextEditingController searchUserController = TextEditingController();
  final _channel =
      WebSocketChannel.connect(Uri.parse('ws://localhost:8080/ws'));

  static void profanityCheckDialog(BuildContext context) {
    showDialog<String>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Обнаружена ненормативная лексика'),
        content: const Text(
            'Пожалуйста, перепишите сообщение без \nиспользования ненормативной лексики. \n\nВ противном случае оно не будет отправлено.'),
        actions: <Widget>[
          TextButton(
            style: TextButton.styleFrom(
              padding: const EdgeInsets.all(16.0),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            onPressed: () => Navigator.pop(context, 'Переписать'),
            child: const Text('Переписать'),
          ),
        ],
      ),
    );
  }

  Future sendMessages() async {
    print('sendMessages' + myController.text);
    try {
      Response response = await dio.post('http://localhost:8000/messages/',
          data: {
            'sender_id': widget.auth.userId,
            'chat_id': widget.chat.chatId,
            'body': myController.text,
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
        if (e.response!.data['body'].toString() ==
            "[Please remove any profanity/swear words.]") {
          print(e.response!.data);
          return profanityCheckDialog(context);
        }
      }
      return;
    }

    myController.text = '';

    print('max scroll extent: ${items.length}');
    await fetchMessages();

    //print('max scroll extent: ${items.length}');

    scrollController.animateTo(0.0,
        duration: Duration(milliseconds: 300), curve: Curves.easeOut);
  }

  Future getPhotos() async {
    Response returnedResult =
        await dio.get('http://localhost:8000/user/profile',
            options: Options(headers: {
              'Authorization': "Bearer ${widget.auth.token}",
            }));
    print("PHOTOS");
    print(returnedResult.data);

    List<UserProfile> result = [];

    for (int i = 0; i < (returnedResult.data as List<dynamic>).length; i++) {
      UserProfile profile = UserProfile(
          returnedResult.data[i]['user_id'],
          returnedResult.data[i]['user']['username'],
          returnedResult.data[i]['user']['first_name'],
          returnedResult.data[i]['user']['last_name'],
          returnedResult.data[i]['user']['middle_name'],
          returnedResult.data[i]['avatar']);
      result.add(profile);
      print("PROFILE");
      print(profile);
    }

    setState(() {
      profiles = result;
    });
  }

  @override
  void dispose() {
    myController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    // TODO: implement initState
    print('doing init');
    super.initState();

    _channel.stream.listen((data) {
      print(data);
      fetchMessages();

      WindowsTaskbar.setFlashTaskbarAppIcon(
        mode: TaskbarFlashMode.all | TaskbarFlashMode.timernofg,
        timeout: const Duration(milliseconds: 500),
      );
    });

    fetchMessages();
    getPhotos();
    getChatMembersDetails();
    nameController.text = widget.chat.name;
    getUsers();
  }

  void _printLatestValue() {
    print('Second text field: ${myController.text}');
  }

  Future fetchMessages() async {
    Response returnedResult = await dio.get('http://localhost:8000/messages',
        options: Options(headers: {
          'Authorization': "Bearer ${widget.auth.token}",
        }));
    print("fetching");
    print(returnedResult.data);

    List<Message> result = [];

    for (int i = 0; i < (returnedResult.data as List<dynamic>).length; i++) {
      if (widget.chat.chatId == returnedResult.data[i]['chat_id']) {
        Message message = Message(
            returnedResult.data[i]['sender_first_name'],
            returnedResult.data[i]['sender_last_name'],
            DateTime.parse(returnedResult.data[i]['created_at']),
            returnedResult.data[i]['body']);
        result.insert(0, message);
      }
    }

    if (mounted) {
      setState(() {
        items = result;
      });

      scrollController.animateTo(0.0,
          duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }

    print('AVATAR');
    print(widget.userData.avatar);
  }

  Future<List<int>> getChatAdminsIds() async {
    try {
      Response response = await dio.get('http://localhost:8000/chatadmins',
          options: Options(headers: {
            'Authorization': "Bearer ${widget.auth.token}",
          }));
      print("fetching users");
      print(response.data);

      List<int> adminIds = [];

      for (int i = 0; i < (response.data as List<dynamic>).length; i++) {
        if (widget.chat.chatId == response.data[i]['chat_id']) {
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
    try {
      Response response = await dio.get('http://localhost:8000/chatmembers',
          options: Options(headers: {
            'Authorization': "Bearer ${widget.auth.token}",
          }));
      print("fetching users");
      print(response.data);

      List<int> memberIds = [];

      for (int i = 0; i < (response.data as List<dynamic>).length; i++) {
        if (widget.chat.chatId == response.data[i]['chat_id']) {
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
      admins = adminIds;
    });
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

  // Future<void> addGroupMembers() async {
  //   outOfChatMembers = users.where((user) => !members.contains(user)).toList();
  //   dublicateOutOfChatMembers = outOfChatMembers;
  //   print("outOfChatMembers == users ??");
  //   print(outOfChatMembers == users);
  //   final result = await showDialog(
  //       context: context,
  //       builder: (ctx) => WillPopScope(
  //             onWillPop: () async {
  //               // Сбрасываем поля при закрытии диалога

  //               return true; // Разрешаем закрытие диалога
  //             },
  //             child: AlertDialog(
  //               titlePadding: const EdgeInsets.all(0.0),
  //               title: Container(
  //                   padding: const EdgeInsets.fromLTRB(0, 0, 0, 20),
  //                   child: Center(
  //                       child: Column(
  //                     mainAxisAlignment: MainAxisAlignment.center,
  //                     children: [
  //                       _getCloseButton(context),
  //                       const Text("Добавить участников"),
  //                     ],
  //                   ))),
  //               content: SizedBox(
  //                 width: 300,
  //                 child: Column(children: [
  //                   Container(
  //                     padding: const EdgeInsets.fromLTRB(0, 10, 0, 0),
  //                     child: TextField(
  //                       onChanged: (query) {
  //                         setState(() {
  //                           users = dublicateOutOfChatMembers.where((item) {
  //                             return '${item.name.toLowerCase()} ${item.lastname.toLowerCase()}'
  //                                     .contains(query) ||
  //                                 item.name.toLowerCase() +
  //                                         item.lastname.toLowerCase() ==
  //                                     query.toLowerCase() ||
  //                                 item.name
  //                                     .toLowerCase()
  //                                     .contains(query.toLowerCase()) ||
  //                                 item.lastname
  //                                     .toLowerCase()
  //                                     .contains(query.toLowerCase());
  //                           }).toList();
  //                         });
  //                       },
  //                       controller: searchUserController,
  //                       style: const TextStyle(
  //                           color: Color.fromARGB(255, 0, 0, 0)),
  //                       decoration: const InputDecoration(
  //                           suffixIconConstraints:
  //                               BoxConstraints(minWidth: 32, minHeight: 40),
  //                           hintText: "Найти пользователя",
  //                           hintStyle: TextStyle(
  //                               fontSize: 14, fontWeight: FontWeight.w100),
  //                           suffixIcon: Icon(Icons.search),
  //                           isDense: true,
  //                           contentPadding: EdgeInsets.only(
  //                               right: 10, top: 10, bottom: 10, left: 15),
  //                           focusedBorder: OutlineInputBorder(
  //                               borderSide: BorderSide(
  //                                   width: 1,
  //                                   color: Color.fromARGB(255, 37, 87, 153))),
  //                           border:
  //                               OutlineInputBorder(borderSide: BorderSide())),
  //                     ),
  //                   ),
  //                   Expanded(
  //                     child: ListView.builder(
  //                         padding: const EdgeInsets.fromLTRB(0, 20, 0, 0),
  //                         scrollDirection: Axis.vertical,
  //                         shrinkWrap: true,
  //                         itemCount: users.length,
  //                         itemBuilder: (context, index) {
  //                           return Padding(
  //                               padding: const EdgeInsets.fromLTRB(0, 6, 0, 6),
  //                               child: CheckboxListTile(
  //                                 value:
  //                                     outOfChatMembers.contains(users[index]),
  //                                 //_isChecked[users[index].userId] ??
  //                                 //false,
  //                                 ////_isChecked[index],
  //                                 title: Text(
  //                                     '${users[index].name} ${users[index].lastname}'),
  //                                 secondary: CircleAvatar(
  //                                     backgroundColor: const Color.fromARGB(
  //                                         1, 255, 255, 255),
  //                                     backgroundImage:
  //                                         NetworkImage(users[index].avatar)),
  //                                 onChanged: (bool? value) {
  //                                   setState(() {
  //                                     if (value != null) {
  //                                       //int originalIndex = dublicateUsers.indexOf(users[index]);
  //                                       //_isChecked[originalIndex] = value;
  //                                       //_isChecked[users[index].userId] = value;
  //                                       if (value) {
  //                                         outOfChatMembers.add(users[index]);
  //                                         //selectedUsers.add(users[index]);
  //                                       } else {
  //                                         outOfChatMembers.remove(users[index]);
  //                                         //selectedUsers.remove(users[index]);
  //                                       }
  //                                     }
  //                                   });
  //                                 },
  //                               ));
  //                         }),
  //                   ),
  //                   ElevatedButton(
  //                     onPressed: () {
  //                       // После выбора пользователей, передаем данные обратно
  //                       Navigator.pop(context, selectedUsers);
  //                     },
  //                     child: const Text('Завершить выбор'),
  //                   ),
  //                 ]),
  //               ),
  //             ),
  //           ));
  // }

  // void groupChatSettings() {
  //   print("called groupChat");
  //   List<UserProfile> adminMembers =
  //       members.where((member) => admins.contains(member.userId)).toList();

  //   List<UserProfile> regularMembers =
  //       members.where((member) => !admins.contains(member.userId)).toList();

  //   List<UserProfile> sortedMembers = [...adminMembers, ...regularMembers];

  //   showDialog(
  //     context: context,
  //     builder: (ctx) => AlertDialog(
  //       contentPadding: EdgeInsets.fromLTRB(5, 5, 5, 20),
  //       titlePadding: const EdgeInsets.all(0.0),
  //       title: Container(
  //           padding: const EdgeInsets.fromLTRB(0, 0, 0, 20),
  //           child: Center(
  //               child: Column(
  //             mainAxisAlignment: MainAxisAlignment.center,
  //             children: [
  //               _getCloseButton(context),
  //               const Text("Информация о чате"),
  //             ],
  //           ))),
  //       content: Scrollbar(
  //         interactive: false, // Отключаем интерактивность ползунка
  //         thumbVisibility: false,
  //         thickness: 6.0, // Регулирует толщину ползунка
  //         radius: Radius.circular(4.0), // Регулирует скругление углов ползунка
  //         //controller: privateChatSettingsScrollController,
  //         child: ScrollConfiguration(
  //           behavior:
  //               ScrollConfiguration.of(context).copyWith(scrollbars: false),
  //           child: SizedBox(
  //             width: 360,
  //             height: MediaQuery.of(context).size.height,
  //             child: Padding(
  //               padding: const EdgeInsets.symmetric(horizontal: 25),
  //               child: ListView(
  //                 children: [
  //                   if (admins.contains(widget.userData.userId))
  //                     Container(
  //                       padding: const EdgeInsets.fromLTRB(0, 0, 0, 20),
  //                       child: Material(
  //                         elevation: 8,
  //                         shape: const CircleBorder(),
  //                         clipBehavior: Clip.antiAliasWithSaveLayer,
  //                         child: InkWell(
  //                           splashColor: Colors.black26,
  //                           onTap: () {},
  //                           child: Ink.image(
  //                             image: NetworkImage(widget.userData.avatar),
  //                             height: 120,
  //                             width: 120,
  //                           ),
  //                         ),
  //                       ),
  //                     )
  //                   else
  //                     Container(
  //                       padding: const EdgeInsets.fromLTRB(0, 0, 0, 20),
  //                       child: Material(
  //                         elevation: 8,
  //                         shape: const CircleBorder(),
  //                         clipBehavior: Clip.antiAliasWithSaveLayer,
  //                         child: InkWell(
  //                           splashColor: Colors.black26,
  //                           child: Ink.image(
  //                             image: NetworkImage(widget.userData.avatar),
  //                             height: 120,
  //                             width: 120,
  //                           ),
  //                         ),
  //                       ),
  //                     ),
  //                   if (admins.contains(widget.userData.userId))
  //                     Container(
  //                       padding: const EdgeInsets.symmetric(vertical: 8),
  //                       child: TextFormField(
  //                         //onEditingComplete: signIn,
  //                         controller: nameController,
  //                         decoration: const InputDecoration(
  //                             focusedBorder: OutlineInputBorder(
  //                                 borderSide: BorderSide(
  //                                     width: 1,
  //                                     color: Color.fromARGB(255, 37, 87, 153))),
  //                             border: OutlineInputBorder(),
  //                             labelText: 'Название чата',
  //                             hintText: 'Введите название'),
  //                       ),
  //                     )
  //                   else
  //                     Container(
  //                       padding: const EdgeInsets.symmetric(vertical: 8),
  //                       child: Text(
  //                         nameController.text,
  //                         textAlign: TextAlign.center,
  //                         style: const TextStyle(
  //                             fontSize: 20, fontWeight: FontWeight.w500),
  //                       ),
  //                     ),
  //                   Container(
  //                     padding: const EdgeInsets.fromLTRB(0, 35, 0, 0),
  //                     child: Align(
  //                       alignment: Alignment.centerLeft,
  //                       child: Row(
  //                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //                         children: [
  //                           const Expanded(
  //                             child: Text(
  //                               'Администраторы',
  //                               style: TextStyle(
  //                                   fontSize: 16, fontWeight: FontWeight.w500),
  //                             ),
  //                           ),
  //                           if (admins.contains(widget.userData.userId))
  //                             Tooltip(
  //                               message: "Добавить администратора",
  //                               child: IconButton(
  //                                 icon: const Icon(Icons.add),
  //                                 splashRadius: 1,
  //                                 onPressed: () {
  //                                   // Действие при нажатии на кнопку плюс
  //                                 },
  //                               ),
  //                             ),
  //                         ],
  //                       ),
  //                     ),
  //                   ),
  //                   ListView.builder(
  //                     padding: const EdgeInsets.fromLTRB(0, 15, 0, 0),
  //                     scrollDirection: Axis.vertical,
  //                     shrinkWrap: true,

  //                     itemCount: adminMembers.length,
  //                     itemBuilder: (context, index) {
  //                       print("MEMBER ID ${sortedMembers[index].userId}");

  //                       print("ADMIN IDS: ${admins}");
  //                       bool isAdmin =
  //                           admins.contains(sortedMembers[index].userId);
  //                       print(
  //                           "User ID: ${sortedMembers[index].userId}, isAdmin: $isAdmin");

  //                       print(regularMembers);
  //                       print("CHAT ADMIN ID ${widget.chat.adminId}");
  //                       print("USER ID ${widget.userData.userId}");
  //                       print(widget.chat.adminId == widget.userData.userId);
  //                       if (admins.contains(widget.userData.userId)) {
  //                         return Padding(
  //                           padding: const EdgeInsets.fromLTRB(0, 6, 0, 6),
  //                           child: ListTile(
  //                             title: Container(
  //                               padding: const EdgeInsets.only(bottom: 6),
  //                               child: Text(
  //                                 "${adminMembers[index].name} ${adminMembers[index].lastname}",
  //                                 style: const TextStyle(
  //                                   fontSize: 16,
  //                                   fontWeight: FontWeight.w500,
  //                                   color: Color.fromARGB(255, 39, 77, 126),
  //                                 ),
  //                               ),
  //                             ),
  //                             trailing: const Tooltip(
  //                               message: "Отозвать права администратора",
  //                               child: Icon(
  //                                 Icons.group_remove_outlined,
  //                                 color: Colors.black,
  //                               ),
  //                             ),
  //                             leading: CircleAvatar(
  //                               backgroundColor: Colors.white,
  //                               backgroundImage:
  //                                   NetworkImage(adminMembers[index].avatar),
  //                             ),
  //                             minVerticalPadding: 15.0,
  //                             onTap: () {},
  //                           ),
  //                         );
  //                       }
  //                       //если пользователь не является админом
  //                       else {
  //                         return Padding(
  //                           padding: const EdgeInsets.fromLTRB(0, 6, 0, 6),
  //                           child: ListTile(
  //                             title: Container(
  //                               padding: const EdgeInsets.only(bottom: 6),
  //                               child: Text(
  //                                 "${adminMembers[index].name} ${adminMembers[index].lastname}",
  //                                 style: const TextStyle(
  //                                   fontSize: 16,
  //                                   fontWeight: FontWeight.w500,
  //                                   color: Color.fromARGB(255, 39, 77, 126),
  //                                 ),
  //                               ),
  //                             ),
  //                             leading: CircleAvatar(
  //                               backgroundColor: Colors.white,
  //                               backgroundImage:
  //                                   NetworkImage(adminMembers[index].avatar),
  //                             ),
  //                             minVerticalPadding: 15.0,
  //                             onTap: () {},
  //                           ),
  //                         );
  //                       }
  //                     },
  //                     //controller: privateChatSettingsScrollController,
  //                   ),
  //                   Container(
  //                     padding: const EdgeInsets.fromLTRB(0, 24, 0, 0),
  //                     child: Align(
  //                       alignment: Alignment.centerLeft,
  //                       child: Row(
  //                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //                         children: [
  //                           const Expanded(
  //                             child: Text(
  //                               'Участники чата',
  //                               style: TextStyle(
  //                                   fontSize: 16, fontWeight: FontWeight.w500),
  //                             ),
  //                           ),
  //                           if (admins.contains(widget.userData.userId))
  //                             Tooltip(
  //                               message: "Добавить участника",
  //                               child: IconButton(
  //                                 icon: const Icon(Icons.add),
  //                                 splashRadius: 1,
  //                                 onPressed: () async {
  //                                   // Открываем диалоговое окно добавления участников
  //                                   addGroupMembers();

  //                                   // Обрабатываем результат
  //                                 },
  //                               ),
  //                             ),
  //                         ],
  //                       ),
  //                     ),
  //                   ),
  //                   ListView.builder(
  //                     padding: const EdgeInsets.fromLTRB(0, 15, 0, 0),
  //                     scrollDirection: Axis.vertical,
  //                     shrinkWrap: true,

  //                     itemCount: regularMembers.length,
  //                     itemBuilder: (context, index) {
  //                       print("MEMBER ID ${sortedMembers[index].userId}");

  //                       print("ADMIN IDS: ${admins}");
  //                       bool isAdmin =
  //                           admins.contains(sortedMembers[index].userId);
  //                       print(
  //                           "User ID: ${sortedMembers[index].userId}, isAdmin: $isAdmin");

  //                       print(regularMembers);
  //                       if (admins.contains(widget.userData.userId)) {
  //                         return Padding(
  //                           padding: const EdgeInsets.fromLTRB(0, 6, 0, 6),
  //                           child: ListTile(
  //                             title: Container(
  //                               padding: const EdgeInsets.only(bottom: 6),
  //                               child: Text(
  //                                 "${regularMembers[index].name} ${regularMembers[index].lastname}",
  //                                 style: const TextStyle(
  //                                   fontSize: 16,
  //                                   fontWeight: FontWeight.w500,
  //                                   color: Color.fromARGB(255, 39, 77, 126),
  //                                 ),
  //                               ),
  //                             ),
  //                             trailing: const Tooltip(
  //                               message: 'Удалить участника',
  //                               child: Icon(
  //                                 Icons.group_remove_outlined,
  //                                 color: Colors.black,
  //                               ),
  //                             ),
  //                             leading: CircleAvatar(
  //                               backgroundColor: Colors.white,
  //                               backgroundImage:
  //                                   NetworkImage(regularMembers[index].avatar),
  //                             ),
  //                             minVerticalPadding: 15.0,
  //                             onTap: () {},
  //                           ),
  //                         );
  //                       }
  //                       //если пользователь не админ
  //                       else {
  //                         return Padding(
  //                           padding: const EdgeInsets.fromLTRB(0, 6, 0, 6),
  //                           child: ListTile(
  //                             title: Container(
  //                               padding: const EdgeInsets.only(bottom: 6),
  //                               child: Text(
  //                                 "${regularMembers[index].name} ${regularMembers[index].lastname}",
  //                                 style: const TextStyle(
  //                                   fontSize: 16,
  //                                   fontWeight: FontWeight.w500,
  //                                   color: Color.fromARGB(255, 39, 77, 126),
  //                                 ),
  //                               ),
  //                             ),
  //                             leading: CircleAvatar(
  //                               backgroundColor: Colors.white,
  //                               backgroundImage:
  //                                   NetworkImage(regularMembers[index].avatar),
  //                             ),
  //                             minVerticalPadding: 15.0,
  //                             onTap: () {},
  //                           ),
  //                         );
  //                       }
  //                     },
  //                     //controller: privateChatSettingsScrollController,
  //                   )
  //                 ],
  //               ),
  //             ),
  //           ),
  //         ),
  //       ),
  //       actions: <Widget>[
  //         Padding(
  //           padding: const EdgeInsets.all(8.0),
  //           child: TextButton(
  //             onPressed: () {
  //               Navigator.of(ctx).pop();
  //             },
  //             style: ButtonStyle(
  //                 backgroundColor: const MaterialStatePropertyAll<Color>(
  //                     Color.fromARGB(255, 37, 87, 153)),
  //                 shape: MaterialStateProperty.all<RoundedRectangleBorder>(
  //                     RoundedRectangleBorder(
  //                   borderRadius: BorderRadius.circular(5.0),
  //                 ))),
  //             child: Container(
  //               padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
  //               child: const Text(
  //                 "Сохранить",
  //                 style: TextStyle(
  //                     color: Colors.white, fontWeight: FontWeight.w300),
  //               ),
  //             ),
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  void userPage(UserProfile user) {
    print("called userPage");
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        contentPadding: EdgeInsets.all(5),
        titlePadding: const EdgeInsets.all(0.0),
        title: Container(
            padding: const EdgeInsets.fromLTRB(0, 0, 0, 8),
            child: Center(
                child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _getCloseButton(context),
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
                        image: NetworkImage(widget.userData.avatar),
                        height: 120,
                        width: 120,
                      ),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                      extractDisplayName(widget.chat.name, widget.userData.name,
                          widget.userData.lastname),
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.w500)),
                ),
                const Expanded(
                  child: Text(
                    'Отдел',
                    textAlign: TextAlign.left,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
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
    print("WIDGET USERS");
    print(users);
    outOfChatMembers = users.where((user) => !members.contains(user)).toList();
    dublicateOutOfChatMembers = outOfChatMembers;
    print('doing rebuild');
    print(widget.chat.chatId);
    print(widget.chat.name);
    print("COUNT");
    print(widget.chat.membersCount);
    print("AVATAR CHAT" + widget.chat.avatar);
    if (members.length == 2) {
      for (int i = 0; i < members.length; i++) {
        if (members[i].userId != widget.userData.userId) {
          secondMember = members[i];
        }
      }
    }
    return Scaffold(
      appBar: AppBar(
        shape: const Border(
            bottom:
                BorderSide(width: 0.2, color: Color.fromARGB(255, 0, 0, 0))),
        //centerTitle: true,
        title: ListTile(
          leading: CircleAvatar(
            backgroundImage: NetworkImage(widget.chat.avatar),
            backgroundColor: Colors.white,
          ),
          title: Text(
            extractDisplayName(widget.chat.name, widget.userData.name,
                widget.userData.lastname),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: Color.fromARGB(255, 39, 77, 126),
            ), //style: const TextStyle(color: Color.fromARGB(1, 0, 0, 0)),
          ),
          subtitle: Text(widget.chat.membersCount > 1
              ? widget.chat.membersCount.toString() + ' участника'
              : widget.chat.membersCount.toString() + ' участник'),
          onTap: () {
            if (widget.chat.isGroupChat == "True") {
              showDialog(
                context: context,
                builder: (context) => GroupChatSettingsDialog(
                  auth: widget.auth,
                  //admins: admins,
                  //users: users,
                  user: widget.userData,
                  //members: members,
                  //outOfChatMembers: outOfChatMembers,
                  nameController: nameController,
                  chat: widget.chat,
                ),
              );
            }
            if (widget.chat.isGroupChat == "False") userPage(secondMember);
          },
          hoverColor: Colors.transparent,
          splashColor: Colors.transparent,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.search),
                splashRadius: 1,
              ),
              if (widget.chat.isGroupChat == "True")
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'viewChatInfo') {
                      print("USERS");
                      print(users);
                      print("OUT OF CHAT MEM");
                      print(outOfChatMembers);
                      print("CHAT MEMBERS");
                      print(members);
                      showDialog(
                        context: context,
                        builder: (context) => GroupChatSettingsDialog(
                          auth: widget.auth,
                          //admins: admins,
                          //users: users,
                          user: widget.userData,
                          //members: members,
                          //outOfChatMembers: outOfChatMembers,
                          nameController: nameController,
                          chat: widget.chat,
                        ),
                      );
                    } else if (value == 'leaveChat') {
                      // Вызовите метод для выхода из чата
                      //leaveChat();
                    }
                  },
                  icon: const Icon(Icons.settings),
                  offset: const Offset(0, 40),
                  tooltip: '',
                  splashRadius: 1,
                  itemBuilder: (context) => [
                    PopupMenuItem<String>(
                      value: 'viewChatInfo',
                      child: Row(
                        children: const [
                          Icon(
                            Icons.info_outline_rounded,
                            color: Colors.black,
                          ), // Иконка для "Посмотреть профиль"
                          SizedBox(width: 4), // Пробел между иконкой и текстом
                          Text('Информация о чате'),
                        ],
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'leaveChat',
                      child: Row(
                        children: const [
                          Icon(
                            Icons.exit_to_app,
                            color: Colors.red,
                          ), // Иконка для "Выйти из чата"
                          SizedBox(width: 4), // Пробел между иконкой и текстом
                          Text(
                            'Выйти из чата',
                            style: TextStyle(color: Colors.red),
                          ),
                        ],
                      ),
                    ),
                  ],
                )
              else
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'viewProfile') {
                      // Вызовите метод для просмотра профиля
                      //viewProfile();
                    } else if (value == 'leaveChat') {
                      // Вызовите метод для выхода из чата
                      //leaveChat();
                    }
                  },
                  icon: const Icon(Icons.settings),
                  offset: const Offset(0, 40),
                  tooltip: '',
                  splashRadius: 1,
                  itemBuilder: (context) => [
                    PopupMenuItem<String>(
                      value: 'viewProfile',
                      child: Row(
                        children: const [
                          Icon(
                            Icons.person,
                            color: Colors.black,
                          ),
                          SizedBox(width: 4),
                          Text('Посмотреть профиль'),
                        ],
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'leaveChat',
                      child: Row(
                        children: const [
                          Icon(
                            Icons.exit_to_app,
                            color: Colors.red,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Выйти из чата',
                            style: TextStyle(color: Colors.red),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
        elevation: 0,
        titleSpacing: 0,
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        shadowColor: const Color.fromARGB(1, 255, 255, 255),
      ),
      body: Center(
        child: Column(children: [
          Expanded(
            child: ListView.builder(
              reverse: true,
              padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 3),
              itemCount: items.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Container(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      "${items[index].name} ${items[index].lastname}",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Color.fromARGB(255, 39, 77, 126),
                      ),
                    ),
                  ),
                  subtitle: Text(
                    items[index].body,
                    style: const TextStyle(
                        fontSize: 15, color: Color.fromARGB(255, 0, 0, 0)),
                  ),
                  leading: const CircleAvatar(
                    //backgroundColor: Colors.grey,
                    backgroundImage: NetworkImage(''),
                  ),
                  trailing: Text(
                    DateFormat('dd.MM.yyyy kk:mm')
                        .format(items[index].dateTime)
                        .toString(),
                    style: const TextStyle(
                      fontWeight: FontWeight.w100,
                      fontSize: 13,
                    ),
                  ),
                  minVerticalPadding: 15.0,
                );
              },
              controller: scrollController,
            ),
          ),
          //поле отправки сообщений
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
            child: TextField(
              onEditingComplete: sendMessages,
              controller: myController,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.only(
                    right: 10, top: 10, bottom: 10, left: 15),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.send),
                  splashRadius: 1,
                  onPressed: sendMessages,
                ),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(5.0),
                    borderSide: const BorderSide(
                        width: 1, color: Color.fromARGB(255, 37, 87, 153))),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(5.0),
                  borderSide: const BorderSide(
                    width: 0.2,
                    style: BorderStyle.none,
                  ),
                ),
                //filled: true,
                hintText: 'Введите сообщение... Для чата ${widget.chat.chatId}',
              ),
              keyboardType: TextInputType.multiline,
              maxLines: 5,
              minLines: 1,
              textAlignVertical: TextAlignVertical.top,
            ),
          )
        ]),
      ),
    );
  }
}
