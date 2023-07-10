import 'package:client/models/userProfile.dart';
import 'package:flutter/material.dart';
import 'package:client/widgets/chat.dart';
import 'package:client/widgets/chat_list.dart';
import 'package:client/models/auth.dart';

import '../models/chats.dart';

class ZeroPage extends StatefulWidget {
  Auth auth;
  ZeroPage(this.auth, {super.key});

  @override
  State<ZeroPage> createState() => _ZeroPageState();
}

class _ZeroPageState extends State<ZeroPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        //backgroundColor: Color.fromARGB(255, 114, 154, 207),

        body: SizedBox(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            //padding: EdgeInsets.symmetric(horizontal: 250),
            child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [SizedBox(width: 400, child: Column())])));
  }
}
