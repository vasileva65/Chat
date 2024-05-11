import 'package:client/dialogs/chat_dialogs.dart';
import 'package:client/models/chats.dart';
import 'package:client/models/message.dart';
import 'package:client/models/userProfile.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';
import 'package:client/widgets/chat_list.dart';
import 'package:intl/intl.dart';
import 'package:client/models/auth.dart';
import 'package:client/models/userProfile.dart';

import '../dialogs/user_profile_dialog.dart';
import '../functions/extract_name.dart';

typedef UpdateChatData = void Function(Chats updateChatData);

class ChatPage extends StatefulWidget {
  Auth auth;
  UserProfile userData;
  Chats chat;
  final UpdateChatData updateChatData;

  final Function(int updatedMembersCount) updateMembersCount;
  ChatPage(this.auth, this.userData, this.chat,
      {required this.updateChatData,
      required this.updateMembersCount,
      super.key});

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
  bool isLoadingChat = true;
  List<UserProfile> users = [];
  List<UserProfile> outOfChatMembers = [];
  List<UserProfile> dublicateOutOfChatMembers = [];
  TextEditingController searchUserController = TextEditingController();
  TextEditingController searchMessageController = TextEditingController();

  String searchQuery = '';
  bool isSearchFieldVisible = false;
  bool isChatVisible = true;

  List<Message> filteredItems = [];

  void updateNameAvatar(Chats updatedChatData) {
    setState(() {
      widget.chat = updatedChatData;
      widget.updateChatData(updatedChatData);
    });
  }

  void updateChatMembersCount(int count) {
    setState(() {
      widget.chat.membersCount = count;
      widget.updateChatData(widget.chat);
    });
  }

// Метод для фильтрации сообщений по тексту
  void filterMessages(String query) {
    setState(() {
      // Очищаем список отфильтрованных сообщений перед применением нового фильтра
      // filteredItems.clear();

      // Проходим по всем сообщениям и добавляем те, которые содержат введенный запрос
      // for (Message item in items) {
      //   if (item.body.toLowerCase().contains(query.toLowerCase())) {
      //     filteredItems.add(item);
      //   }
      // }
      if (query.isEmpty) {
        // Если поле поиска пустое, отображаем все сообщения
        filteredItems = List.from(items);
      } else {
        // Иначе фильтруем сообщения по запросу
        filteredItems = items
            .where(
                (item) => item.body.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
      // items = filteredItems;
    });
  }

  void _handleUpdateMembersCount(int updatedMembersCount) {
    print('UPDATED MEMBERS COUNT: $updatedMembersCount');
    // Другая логика, если необходимо
  }

  // void updateChatInfoCallback(
  //   int chatId,
  //   String newName,
  //   String newAvatar,
  //   int membersCount,
  //   int adminId,
  //   String isGroupChat,
  // ) {
  //   // Update chat information in the ChatPage widget
  //   setState(() {
  //     widget.chat = Chats(
  //       chatId,
  //       newName,
  //       newAvatar,
  //       membersCount,
  //       adminId,
  //       isGroupChat,
  //     );
  //   });
  //   widget.onChatUpdated(
  //     chatId,
  //     newName,
  //     newAvatar,
  //     membersCount,
  //     adminId,
  //     isGroupChat,
  //   );
  // }

  static void adminLeavingWarning(BuildContext context) {
    showDialog<String>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Вы являетесь единственным администратором чата'),
        content: const Text(
            'Пожалуйста, передайте права \nадминистратора другому пользователю. \n\nВ противном случае оно не будет отправлено.'),
        actions: <Widget>[
          TextButton(
            style: TextButton.styleFrom(
              padding: const EdgeInsets.all(16.0),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            onPressed: () => Navigator.pop(context, 'Передать права'),
            child: const Text('Передать права'),
          ),
        ],
      ),
    );
  }

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
      await dio.get('http://localhost:8080/?chat_id=${widget.chat.chatId}');
    } on DioError catch (e) {
      if (e.response != null) {
        if (e.response!.statusCode == 401) {
          Navigator.pop(context);
        }
        print(e.response!.data);
        if (e.response!.data['error']
                .toString()
                .contains("Please remove any profanity/swear words.") &&
            e.response!.statusCode == 400) {
          print(e.response!.data);
          print("VALIDTION PROFANITY");

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
    //fetchChatData();

    //fetchData();
    fetchMessages();
    getPhotos();
    getChatMembersDetails();
    getChatAdminsIds();
    nameController.text = widget.chat.name;
    // items = filteredItems;
    //getUsers();
  }

  void _printLatestValue() {
    print('Second text field: ${myController.text}');
  }

  Future fetchMessages() async {
    Response returnedResult = await dio.get('http://localhost:8000/messages',
        options: Options(headers: {
          'Authorization': "Bearer ${widget.auth.token}",
        }));
    print("fetching" + widget.chat.name);
    // print(returnedResult.data);

    List<Message> result = [];

    for (int i = 0; i < (returnedResult.data as List<dynamic>).length; i++) {
      if (widget.chat.chatId == returnedResult.data[i]['chat_id']) {
        Message message = Message(
            returnedResult.data[i]['sender_first_name'],
            returnedResult.data[i]['sender_last_name'],
            DateTime.parse(returnedResult.data[i]['created_at']),
            returnedResult.data[i]['body'],
            returnedResult.data[i]['avatar']);
        result.insert(0, message);
      }
    }

    if (mounted) {
      setState(() {
        items = result;
        filteredItems = items;
      });

      scrollController.animateTo(0.0,
          duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }

    print('AVATAR');
    print(widget.userData.avatar);
  }

  Future<void> fetchChatData() async {
    try {
      Response returnedResult =
          await dio.get('http://localhost:8000/chats/${widget.chat.chatId}',
              options: Options(headers: {
                'Authorization': "Bearer ${widget.auth.token}",
              }));
      print("fetching chats");
      print(returnedResult.data);

      //if (returnedResult.data['user_id'].toString() == widget.auth.userId) {
      Chats chatInfo = Chats(
          returnedResult.data['chat_id'],
          returnedResult.data['chat_name'],
          returnedResult.data['avatar'],
          returnedResult.data['people_count'],
          returnedResult.data['user_id'],
          returnedResult.data['group_chat'].toString());
      print("CHAT INFO COUNT");
      print(chatInfo.membersCount);
      print("CHATINFO == WIDGET CHAT");

      //}
      setState(() {
        widget.chat = chatInfo;
        widget.updateChatData(chatInfo);
      });
    } catch (error) {
      print('Error fetching chat data: $error');
    }
  }

  Future<void> fetchData() async {
    try {
      // Здесь происходит загрузка данных
      //await getPhotos();
      fetchChatData();
      //await fetchMessages();

      // После завершения всех операций устанавливаем isLoading в false
      setState(() {
        isLoadingChat = false;
      });
    } catch (error) {
      print('Error fetching data: $error');
      // Обработка ошибок при загрузке данных
      setState(() {
        isLoadingChat =
            false; // Устанавливаем isLoading в false в случае ошибки
      });
    }
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

  Future getChatAdminsIds() async {
    var dio = Dio();
    List<int> adminIds = [];
    try {
      Response response = await dio.get('http://localhost:8000/chatadmins',
          options: Options(headers: {
            'Authorization': "Bearer ${widget.auth.token}",
          }));
      print("fetching users");
      print(response.data);

      for (int i = 0; i < (response.data as List<dynamic>).length; i++) {
        if (widget.chat.chatId == response.data[i]['chat_id'] &&
            response.data[i]['left_at'] == null) {
          adminIds.add(response.data[i]['user_id']);
        }
      }
      print("ADMIN IDS");
      print(adminIds);
    } catch (e) {
      print('Error fetching chat members: $e');
      // или возвращайте пустой список или другое значение по умолчанию
    }
    setState(() {
      admins = adminIds;
    });
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
    print("MEMBER IDS");
    print(memberIds.length);
    List<UserProfile> result = [];

    try {
      Response returnedResult = await dio.get(
        'http://localhost:8000/userprofiles/',
        options: Options(headers: {
          'Authorization': "Bearer ${widget.auth.token}",
        }),
      );
      print("DETAILS");
      //print(returnedResult.data);

      print((returnedResult.data as List<dynamic>).length);
      for (int memberId in memberIds) {
        print(memberId);
        var userProfileData = returnedResult.data.firstWhere(
          (profile) => profile['user_id'] == memberId,
          orElse: () => null,
        );
        if (userProfileData != null) {
          // Создаем UserProfile из полученных данных
          UserProfile user = UserProfile(
            userProfileData['user_id'],
            userProfileData['user']['username'],
            userProfileData['user']['first_name'],
            userProfileData['user']['last_name'],
            userProfileData['user']['middle_name'],
            userProfileData['avatar'],
          );
          // if (returnedResult.data[i]['user_id'] == memberId) {
          //   print(returnedResult.data[i]);
          //   UserProfile user = UserProfile(
          //     returnedResult.data[i]['user_id'],
          //     returnedResult.data[i]['user']['username'],
          //     returnedResult.data[i]['user']['first_name'],
          //     returnedResult.data[i]['user']['last_name'],
          //     returnedResult.data[i]['user']['middle_name'],
          //     returnedResult.data[i]['avatar'],
          //   );

          result.add(user);
        }
      }
      print("RESULT COUNT");
      print(result.length);
    } catch (e) {
      print('Error fetching user profile: $e');
      // обработка ошибок, если не удается получить данные пользователя
    }

    setState(() {
      members = result;
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
      admins.remove(userToRemove.userId);
    });
  }

  Future removeChatMember(Chats chat, UserProfile userToRemove) async {
    print('removeChatMemberAdmin called');
    print(chat.chatId);
    print(userToRemove.userId);
    if (admins.contains(userToRemove.userId))
      await removeChatAdmin(chat, userToRemove);
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
      updateChatMembersCount(members.length);
      // regularMembers.remove(userToRemove);

      //Call back
      // widget.updateChatMembersCount(members.length);
    });
    // await fetchChatData();
  }

  @override
  Widget build(BuildContext context) {
    //print("WIDGET USERS");
    //print(users);
    outOfChatMembers = users.where((user) => !members.contains(user)).toList();
    dublicateOutOfChatMembers = outOfChatMembers;
    print('doing rebuild');
    print(widget.chat.chatId);
    print(widget.chat.name);
    print("COUNT");
    print(widget.chat.membersCount);
    //print("AVATAR CHAT" + widget.chat.avatar);
    if (members.length == 2) {
      for (int i = 0; i < members.length; i++) {
        if (members[i].userId != widget.userData.userId) {
          secondMember = members[i];
        }
      }
    }
    print("members:" + members.length.toString());
    members.forEach((user) {
      print('User ID: ${user.userId}');
    });
    // if (isLoadingChat) {
    //   // Return a loading indicator or some other widget
    //   return Center(
    //       //child: CircularProgressIndicator(), // Индикатор загрузки
    //       ); // Example of a loading indicator
    // } else {
    return Scaffold(
      appBar: AppBar(
        shape: const Border(
            bottom:
                BorderSide(width: 0.2, color: Color.fromARGB(255, 0, 0, 0))),
        //centerTitle: true,
        title: Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  Visibility(
                    visible: isChatVisible,
                    child: Expanded(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundImage: NetworkImage(widget.chat.avatar),
                          backgroundColor: Colors.white,
                        ),
                        title: Text(
                          extractDisplayName(widget.chat.name,
                              widget.userData.name, widget.userData.lastname),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            color: Color.fromARGB(255, 39, 77, 126),
                          ), //style: const TextStyle(color: Color.fromARGB(1, 0, 0, 0)),
                        ),
                        subtitle: Text(widget.chat.membersCount > 1
                            ? widget.chat.membersCount.toString() +
                                ' участников'
                            : widget.chat.membersCount.toString() +
                                ' участник'),
                        onTap: () {
                          print("TAPPED");
                          print(widget.chat.membersCount);
                          if (widget.chat.isGroupChat == "True" ||
                              widget.chat.isGroupChat == "true") {
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
                                updateChatData: updateNameAvatar,
                                updateChatMembersCount: updateChatMembersCount,
                                // updateChatMembersCount: (updatedMembersCount) {
                                //   setState(() {
                                //     print("DRAWN CHAT PAGE");
                                //     widget.updateMembersCount(
                                //         updatedMembersCount);
                                //   }); // Вызываем обновление из виджета
                                //   _handleUpdateMembersCount(
                                //       updatedMembersCount); // Отладочный print
                                // },
                                // onChatUpdated: updateChatInfoCallback,
                                // updateChatList: widget.onChatUpdated,
                              ),
                            );
                          }
                          if (widget.chat.isGroupChat == "False" ||
                              widget.chat.isGroupChat == "false") {
                            print("second mem:" +
                                secondMember.name +
                                " " +
                                secondMember.lastname);
                            showDialog(
                              context: context,
                              builder: (context) => UserProfileDialog(
                                auth: widget.auth,
                                //admins: admins,
                                //users: users,
                                user: secondMember,
                                //members: members,
                                //outOfChatMembers: outOfChatMembers,
                                nameController: nameController,
                                chat: widget.chat,
                              ),
                            );
                          }
                        },
                        hoverColor: Colors.transparent,
                        splashColor: Colors.transparent,
                      ),
                    ),
                  ),
                  Visibility(
                    visible: isSearchFieldVisible,
                    child: Expanded(
                      child: SizedBox(
                        child: TextField(
                          // controller: searchMessageController,
                          onChanged: (value) {
                            setState(() {
                              searchQuery = value;
                              filterMessages(value);
                            });
                          },
                          decoration: InputDecoration(
                            hintText: 'Поиск по сообщениям',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                  8.0), // Радиус скругления углов
                              borderSide: BorderSide(
                                  color: Colors.grey), // Цвет границы
                            ),
                            isDense: true, // Added this
                            contentPadding: EdgeInsets.all(12),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: () {
                      setState(() {
                        isSearchFieldVisible = !isSearchFieldVisible;
                      });
                    },
                    icon: const Icon(
                      Icons.search,
                      color: Colors.grey,
                    ),
                    splashRadius: 1,
                  ),
                  if (widget.chat.isGroupChat == "True" ||
                      widget.chat.isGroupChat == "true")
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        print("IF WORKED TRUE");
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
                              updateChatData: updateNameAvatar,
                              updateChatMembersCount: updateChatMembersCount,
                              // updateChatMembersCount: (updatedMembersCount) {
                              //   setState(() {
                              //     print("DRAWN CHAT PAGE");
                              //     widget
                              //         .updateMembersCount(updatedMembersCount);
                              //   }); // Вызываем обновление из виджета
                              //   _handleUpdateMembersCount(
                              //       updatedMembersCount); // Отладочный print
                              // },
                              // onChatUpdated: (int chatId,
                              //     String name,
                              //     String avatar,
                              //     int membersCount,
                              //     int adminId,
                              //     String isGroupChat) {
                              //   // Обновление данных о чате в ChatList

                              // },
                              // updateChatList: widget.updateChatList(),
                            ),
                          );
                        } else if (value == 'leaveChat') {
                          print("ADMINS LENGTH");
                          print(admins.length);
                          if (admins.length == 1 &&
                              admins.contains(widget.userData.userId))
                            adminLeavingWarning(context);
                          else
                            removeChatMember(widget.chat, widget.userData);
                        }
                      },
                      icon: const Icon(
                        Icons.settings,
                        color: Colors.grey,
                      ),
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
                              SizedBox(
                                  width: 4), // Пробел между иконкой и текстом
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
                              SizedBox(
                                  width: 4), // Пробел между иконкой и текстом
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
                          showDialog(
                            context: context,
                            builder: (context) => UserProfileDialog(
                              auth: widget.auth,
                              //admins: admins,
                              //users: users,
                              user: secondMember,
                              //members: members,
                              //outOfChatMembers: outOfChatMembers,
                              nameController: nameController,
                              chat: widget.chat,
                            ),
                          );
                        } else if (value == 'leaveChat') {
                          removeChatMember(widget.chat, widget.userData);
                        }
                      },
                      icon: const Icon(
                        Icons.settings,
                        color: Colors.grey,
                      ),
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
                                Icons.delete,
                                color: Colors.red,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Удалить чат',
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
          ],
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
              itemCount: filteredItems.length,
              // itemCount: items.length,
              itemBuilder: (context, index) {
                {
                  return ListTile(
                    title: Container(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        "${filteredItems[index].name} ${filteredItems[index].lastname}",
                        // "${items[index].name} ${items[index].lastname}",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Color.fromARGB(255, 39, 77, 126),
                        ),
                      ),
                    ),
                    subtitle: Text(
                      filteredItems[index].body,
                      // items[index].body,
                      style: const TextStyle(
                          fontSize: 15, color: Color.fromARGB(255, 0, 0, 0)),
                    ),
                    leading: CircleAvatar(
                      // backgroundColor: Colors.grey,
                      backgroundImage:
                          NetworkImage(filteredItems[index].userAvatar),
                    ),
                    trailing: Text(
                      DateFormat('dd.MM.yyyy kk:mm')
                          .format(filteredItems[index].dateTime)
                          .toString(),
                      // DateFormat('dd.MM.yyyy kk:mm')
                      //     .format(items[index].dateTime)
                      //     .toString(),
                      style: const TextStyle(
                        fontWeight: FontWeight.w100,
                        fontSize: 13,
                      ),
                    ),
                    minVerticalPadding: 15.0,
                  );
                }
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
// }
