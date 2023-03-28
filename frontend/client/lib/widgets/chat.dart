import 'package:client/models/message.dart';
import 'package:client/models/userProfile.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';
import 'package:client/widgets/chat_list.dart';
import 'package:intl/intl.dart';
import 'package:client/models/auth.dart';

class ChatPage extends StatefulWidget {
  Auth auth;
  ChatPage(this.auth, {super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final myController = TextEditingController();
  final dio = Dio();
  List<Message> items = [];
  ScrollController scrollController = ScrollController();

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
        print(e.response!.data);
      }
      return;
    }

    myController.text = '';

    print('max scroll extent: ${items.length}');
    await fetchMessages();

    print('max scroll extent: ${items.length}');

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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Chat'),
        backgroundColor: Color.fromARGB(255, 0, 102, 204),
      ),
      body: Center(
        child: Column(children: [
          Container(
            height: MediaQuery.of(context).size.height - 130,
            child: Flexible(
              child: ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(
                      items[index].name + " " + items[index].lastname,
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    subtitle: Text(
                      items[index].body,
                      style: const TextStyle(
                          fontSize: 15, color: Color.fromARGB(255, 0, 0, 0)),
                    ),
                    leading: CircleAvatar(),
                    trailing: Text(DateFormat('dd.MM.yyyy kk:mm')
                        .format(items[index].dateTime)
                        .toString()),
                    minVerticalPadding: 10.0,
                  );
                },
                controller: scrollController,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: TextFormField(
              onEditingComplete: sendMessages,
              controller: myController,
              decoration: InputDecoration(
                suffixIcon: IconButton(
                  icon: const Icon(Icons.send),
                  splashRadius: 20,
                  onPressed: sendMessages,
                ),
                border: InputBorder.none,
                filled: true,
                //borderRadius: BorderRadius.all(Radius.circular(25.0)),
                //borderSide: BorderSide()),
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
