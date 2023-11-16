import 'package:client/dialogs/buttons.dart';
import 'package:flutter/material.dart';

class ChatDialogs {
  static void profanityCheckDialog(BuildContext context) {
    showDialog<String>(
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

  static void chatSettings(
    BuildContext context,
    int adminId,
    String userId,
    String userAvatar,
    TextEditingController nameController,
  ) {
    if (adminId.toString() == userId) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          titlePadding: const EdgeInsets.all(0.0),
          title: Container(
              padding: const EdgeInsets.fromLTRB(0, 0, 0, 8),
              child: Center(
                  child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Buttons.getCloseButton(context),
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
                          image: NetworkImage(userAvatar),
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
    } else {}
  }
}
