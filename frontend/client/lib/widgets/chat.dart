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
  bool _isExpanded = false;
  final nameController = TextEditingController();

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

  void chatSettings() {
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
                const Text("Настройки чата"),
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
                        labelText: 'Название чата',
                        hintText: 'Введите название'),
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

  @override
  Widget build(BuildContext context) {
    print('doing rebuild');
    print(widget.chat.chatId);
    print(widget.chat.name);
    print("COUNT");
    print(widget.chat.membersCount);
    print("AVATAR CHAT" + widget.chat.avatar);
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
            widget.chat.name,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: Color.fromARGB(255, 39, 77, 126),
            ), //style: const TextStyle(color: Color.fromARGB(1, 0, 0, 0)),
          ),
          subtitle: Text(widget.chat.membersCount > 1
              ? widget.chat.membersCount.toString() + ' участника'
              : widget.chat.membersCount.toString() + ' участник'),
          onTap: chatSettings,
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
              IconButton(
                onPressed: chatSettings,
                icon: const Icon(Icons.settings),
                splashRadius: 1,
              )
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
