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
  List<String> items = [];
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

    List<String> result = [];

    for (int i = 0; i < (returnedResult.data as List<dynamic>).length; i++) {
      result.add(returnedResult.data[i]['body']);
    }

    print(result);

    setState(() {
      items = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('New page'),
        actions: [
          TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16.0),
                textStyle: const TextStyle(fontSize: 20),
              ),
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) {
                  return ChatList();
                }));
              },
              child: Text('Chats')),
        ],
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
                    title: Text(items[index]),
                    subtitle: Text('2022.01.01'),
                    leading: CircleAvatar(),
                  );
                },
                controller: scrollController,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: TextField(
              onEditingComplete: () async {
                print(myController.text);
                try {
                  Response response =
                      await dio.post('http://localhost:8000/messages/', data: {
                    'sender_id': 1,
                    'chat_id': 1,
                    'body': myController.text,
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
                    scrollController.position.maxScrollExtent + 48,
                    duration: Duration(milliseconds: 300),
                    curve: Curves.easeOut);
                print("I called animated to");
              },
              controller: myController,
            ),
          )
        ]),
      ),
    );
  }
}
