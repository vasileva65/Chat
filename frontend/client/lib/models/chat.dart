import 'package:flutter/material.dart';

class Chat {
  String name;
  int chatId;
  String avatar;
  int membersCount;
  int adminId;
  String isGroupChat;
  Chat(this.chatId, this.name, this.avatar, this.membersCount, this.adminId,
      this.isGroupChat);
}
