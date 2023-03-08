import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: ' Chat',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: MyHomePage());
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
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

  fetchMessages() async {
    Response returnedResult = await dio.get('http://localhost:8000/messages');
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
                    return Scaffold(
                        appBar: AppBar(
                          title: const Text('Chats'),
                        ),
                        body: const Center(
                          child: Text(
                            'The list of chats',
                            style: TextStyle(fontSize: 24),
                          ),
                        ));
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
                    Response response = await dio
                        .post('http://localhost:8000/messages/', data: {
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

                  fetchMessages();

                  scrollController.animateTo(
                      scrollController.position.maxScrollExtent,
                      duration: Duration(milliseconds: 300),
                      curve: Curves.easeOut);
                },
                controller: myController,
              ),
            )
          ]),
        ));
  }
}
