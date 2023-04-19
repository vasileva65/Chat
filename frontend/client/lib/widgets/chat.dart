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
  ChatPage(this.auth, this.userData, {super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final myController = TextEditingController();
  final dio = Dio();
  List<Message> items = [];
  ScrollController scrollController = ScrollController();

  final _channel =
      WebSocketChannel.connect(Uri.parse('ws://localhost:8080/ws'));

  Future sendMessages() async {
    print(myController.text);
    try {
      Response response = await dio.post('http://localhost:8000/messages/',
          data: {
            'sender_id': widget.auth.userId,
            'chat_id': 1,
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

    scrollController.animateTo(scrollController.position.maxScrollExtent + 1000,
        duration: Duration(milliseconds: 300), curve: Curves.easeOut);
  }

  @override
  void dispose() {
    myController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    // TODO: implement initState
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
      Message message = Message(
          returnedResult.data[i]['sender_first_name'],
          returnedResult.data[i]['sender_last_name'],
          DateTime.parse(returnedResult.data[i]['created_at']),
          returnedResult.data[i]['body']);
      result.add(message);
    }

    setState(() {
      items = result;
    });

    scrollController.animateTo(scrollController.position.maxScrollExtent + 1000,
        duration: Duration(milliseconds: 300), curve: Curves.easeOut);

    print('AVATAR');
    print(widget.userData.avatar);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        //centerTitle: true,
        title: const Text('Корпоративный чат'),
        backgroundColor: Color.fromARGB(255, 37, 87, 153),
      ),
      body: Center(
        child: Column(children: [
          Container(
            height: MediaQuery.of(context).size.height - 130,
            child: Flexible(
              child: ListView.builder(
                padding:
                    const EdgeInsets.symmetric(vertical: 15, horizontal: 3),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Container(
                      padding: EdgeInsets.only(bottom: 6),
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
                      backgroundImage: NetworkImage(
                          'http://localhost:8000/media/user_photos/User-Profile-PNG-Image_rywALHe.png'),
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
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
            child: TextFormField(
              onEditingComplete: sendMessages,
              controller: myController,
              decoration: InputDecoration(
                suffixIcon: IconButton(
                  icon: const Icon(Icons.send),
                  splashRadius: 20,
                  onPressed: sendMessages,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(5.0),
                  borderSide: const BorderSide(
                    width: 0,
                    style: BorderStyle.none,
                  ),
                ),
                filled: true,
                hintText: 'Введите сообщение...',
              ),
              //maxLines: 5,
              //minLines: 1,
            ),
          )
        ]),
      ),
    );
  }
}
