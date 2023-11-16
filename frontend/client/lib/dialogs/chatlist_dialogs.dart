import 'package:client/dialogs/buttons.dart';
import 'package:flutter/material.dart';

import '../models/userProfile.dart';

class ChatListDialogs {
  static void addChat(
      context,
      TextEditingController chatNameController,
      TextEditingController searchUserController,
      List<UserProfile> users,
      List<UserProfile> dublicateUsers,
      List<bool> _isChecked,
      List<UserProfile> selectedUsers) {
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
                Buttons.getCloseButton(context),
                const Text("Создать чат"),
              ],
            ))),
        content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
          return Padding(
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
                          image: const AssetImage('assets/images/default.jpg'),
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
                      controller: chatNameController,
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
                  Container(
                    padding: const EdgeInsets.fromLTRB(0, 10, 0, 0),
                    child: TextField(
                      onChanged: (query) {
                        setState(() {
                          users = dublicateUsers.where((item) {
                            return '${item.name.toLowerCase()} ${item.lastname.toLowerCase()}'
                                    .contains(query) ||
                                item.name.toLowerCase() +
                                        item.lastname.toLowerCase() ==
                                    query.toLowerCase() ||
                                item.name
                                    .toLowerCase()
                                    .contains(query.toLowerCase()) ||
                                item.lastname
                                    .toLowerCase()
                                    .contains(query.toLowerCase());
                          }).toList();
                        });
                      },
                      controller: searchUserController,
                      //cursorColor: Color.fromARGB(255, 255, 255, 255),
                      style:
                          const TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
                      decoration: const InputDecoration(
                          //suffixIconColor: Color.fromARGB(255, 255, 255, 255),
                          suffixIconConstraints:
                              BoxConstraints(minWidth: 32, minHeight: 40),
                          hintText: "Найти пользователя",
                          hintStyle: TextStyle(
                              //color: Color.fromARGB(255, 255, 255, 255),
                              fontSize: 14,
                              fontWeight: FontWeight.w100),
                          suffixIcon: Icon(Icons.search),
                          isDense: true,
                          contentPadding: EdgeInsets.only(
                              right: 10, top: 10, bottom: 10, left: 15),
                          focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                  width: 1,
                                  color: Color.fromARGB(255, 37, 87, 153))),
                          border: OutlineInputBorder(
                              borderSide: BorderSide(
                                  //color: Color.fromARGB(255, 255, 255, 255)),
                                  // borderRadius:
                                  //     BorderRadius.all(Radius.circular(15.0)
                                  ))),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(0, 20, 0, 0),
                        scrollDirection: Axis.vertical,
                        shrinkWrap: true,
                        itemCount: users.length,
                        itemBuilder: (context, index) {
                          return Padding(
                              padding: const EdgeInsets.fromLTRB(0, 6, 0, 6),
                              child: CheckboxListTile(
                                value: _isChecked[index],
                                title: Text(
                                    '${users[index].name} ${users[index].lastname}'),
                                secondary: CircleAvatar(
                                    backgroundColor:
                                        const Color.fromARGB(1, 255, 255, 255),
                                    backgroundImage:
                                        NetworkImage(users[index].avatar)),
                                onChanged: (bool? value) {
                                  setState(() {
                                    _isChecked[index] = value!;

                                    if (_isChecked[index]) {
                                      selectedUsers.add(users[index]);
                                    } else {
                                      selectedUsers.remove(users[index]);
                                    }
                                  });
                                },
                              ));
                        }),
                  )
                ],
              ),
            ),
          );
        }),
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

  static void userSettings(
    context,
    String avatar,
    TextEditingController nameController,
    TextEditingController lastnameController,
    TextEditingController middlenameController,
  ) {
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
                Buttons.getCloseButton(context),
                const Text("Настройки пользователя"),
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
                        image: NetworkImage(avatar),
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
                        labelText: 'Имя',
                        hintText: 'Введите имя'),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: TextFormField(
                    //onEditingComplete: signIn,
                    controller: lastnameController,
                    decoration: const InputDecoration(
                        focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                                width: 1,
                                color: Color.fromARGB(255, 37, 87, 153))),
                        border: OutlineInputBorder(),
                        labelText: 'Фамилия',
                        hintText: 'Введите фамилию'),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: TextFormField(
                    //onEditingComplete: signIn,
                    controller: middlenameController,
                    decoration: const InputDecoration(
                        focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                                width: 1,
                                color: Color.fromARGB(255, 37, 87, 153))),
                        border: OutlineInputBorder(),
                        labelText: 'Отчество',
                        hintText: 'Введите отчество'),
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
}
