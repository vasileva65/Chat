import 'package:client/models/message.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';
import 'package:client/widgets/chat_list.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final myController = TextEditingController();
  final dio = Dio();
  List<Message> items = [];
  ScrollController scrollController = ScrollController();

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
    print("I am fetching");
    Response returnedResult = await dio.get('http://localhost:8000/messages');
    print("I fetched");
    print(returnedResult.data);

    List<Message> result = [];

    for (int i = 0; i < (returnedResult.data as List<dynamic>).length; i++) {
      Message message = Message(returnedResult.data[i]['sender_id'],
          DateTime.now(), returnedResult.data[i]['body']);
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
                    title: const Text(
                      'Name',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    subtitle: Text(
                      items[index].body,
                      style: const TextStyle(
                          fontSize: 15, color: Color.fromARGB(255, 0, 0, 0)),
                    ),
                    leading: CircleAvatar(),
                    trailing: Text('2020-10-10'),
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
              onEditingComplete: () async {
                print(myController.text);
                try {
                  Response response =
                      await dio.post('http://localhost:8000/messages/', data: {
                    'sender_id': 1,
                    'chat_id': 1,
                    'body': myController.text,
                    //'created_at':
                  });
                  print(response);
                  print(response.data);
                } on DioError catch (e) {
                  if (e.response != null) {
                    print(e.response!.data);
                  }
                  return;
                }

                myController.text = '';

                print('max scroll extent: ${items.length}');
                await fetchMessages();

                print('max scroll extent: ${items.length}');

                print("I am animating");

                scrollController.animateTo(
                    scrollController.position.maxScrollExtent + 1000,
                    duration: Duration(milliseconds: 300),
                    curve: Curves.easeOut);
                print("I called animated to");
              },
              controller: myController,
              decoration: const InputDecoration(
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
