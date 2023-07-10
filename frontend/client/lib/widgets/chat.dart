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

  final _channel =
      WebSocketChannel.connect(Uri.parse('ws://localhost:8080/ws'));

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
          return showDialog<String>(
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
          returnedResult.data[i]['user_id'].toString(),
          returnedResult.data[i]['avatar']);
      result.add(profile);
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

  @override
  Widget build(BuildContext context) {
    print('doing rebuild');
    print(widget.chat.chatId);
    print(widget.chat.name);
    return Scaffold(
      appBar: AppBar(
        shape: const Border(
            bottom:
                BorderSide(width: 0.2, color: Color.fromARGB(255, 0, 0, 0))),
        //centerTitle: true,
        title: Text(
          widget.chat.name,
          style: const TextStyle(
              fontSize: 15,
              color: Color.fromARGB(255, 0, 0,
                  0)), //style: const TextStyle(color: Color.fromARGB(1, 0, 0, 0)),
        ),
        backgroundColor: Color.fromARGB(255, 255, 255, 255),
        shadowColor: const Color.fromARGB(1, 255, 255, 255),
      ),
      body: Center(
        child: Column(children: [
          SizedBox(
            height: MediaQuery.of(context).size.height - 130,
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
            child: Expanded(
              child: TextField(
                onEditingComplete: sendMessages,
                controller: myController,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.only(
                      right: 10, top: 10, bottom: 10, left: 15),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.send),
                    splashRadius: 20,
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
                  hintText:
                      'Введите сообщение... Для чата ${widget.chat.chatId}',
                ),
                keyboardType: TextInputType.multiline,
                maxLines: null,
              ),
            ),
          )
        ]),
      ),
    );
  }
}
