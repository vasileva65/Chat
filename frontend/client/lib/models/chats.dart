import 'package:flutter/material.dart';

class Chats {
  String name;
  int chatId;
  String avatar;
  int membersCount;
  int adminId;
  String isGroupChat;
  Chats(this.chatId, this.name, this.avatar, this.membersCount, this.adminId,
      this.isGroupChat);
}
