import 'dart:convert';
import 'dart:ffi';
import 'package:client/models/userProfile.dart';
import 'package:client/widgets/forgot_password_page.dart';
import 'package:client/widgets/main_screen.dart';
import 'package:client/widgets/registration.dart';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:client/widgets/main_screen.dart';
import 'package:client/models/auth.dart';
import 'package:client/models/userProfile.dart';
import 'package:windows_taskbar/windows_taskbar.dart';

import '../models/chats.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPage createState() => _LoginPage();
}

class _LoginPage extends State<LoginPage> {
  final dio = Dio();
  final usernameController = TextEditingController();
  final passController = TextEditingController();
  String errorText = '';

  late UserProfile userData;
  Chats chat = Chats(0, '', '', 0, 0, '');

  Future signIn() async {
    Auth auth = await login();
    setState(() {});
    if (auth.authenticated) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
            builder: (context) => MainScreen(auth, userData,
                chat: chat, showUsernameDialog: false)),
        (Route<dynamic> route) => false,
      );
    } else {
      setState(() {
        errorText = auth.authError;
      });
    }
  }

  Future login() async {
    // Returns true if auth succeeded.
    try {
      Response response = await dio.post(
        'http://localhost:8000/token/',
        data: {
          'username': usernameController.text,
          'password': passController.text,
        },
      );

      await getUserProfileData(response);

      print("user data userId");
      print(userData.userId.toString() +
          userData.lastname +
          userData.middlename +
          userData.name);

      // GET /user/profile -> {user_id: username: email: first_name: last_name: avatat:}
      // GET /user/profile/<id>
      // PATCH /user/profile/<id>
      print(response.data['access']);
      return Auth(userData.userId.toString(), response.data['access'], true);
    } on DioError catch (e) {
      if (e.response!.data['detail'] == null) {
        return Auth('', '', false, authError: 'Поле не может быть пустым');
      } else if (e.response != null) {
        return Auth('', '', false, authError: e.response!.data['detail']);
      }
      return Auth('', '', false, authError: 'Ошибка сети..');
    }
  }

  Future getUserProfileData(Response res) async {
    Response returnedResult =
        await dio.get('http://localhost:8000/user/profile',
            options: Options(headers: {
              'Authorization': "Bearer ${res.data['access']}",
            }));

    print(returnedResult.data);
    UserProfile user = UserProfile('', '', '', '', '', '');
    if ((returnedResult.data as List<dynamic>).length > 0) {
      user = UserProfile(
        returnedResult.data[0]['user_id'].toString(),
        returnedResult.data[0]['user']['username'],
        returnedResult.data[0]['user']['first_name'],
        returnedResult.data[0]['user']['last_name'],
        returnedResult.data[0]['user']['middle_name'],
        returnedResult.data[0]['avatar'],
      );
    }
    print("here is the result");
    print(returnedResult.data);

    setState(() {
      userData = user;
      print('userdata changed');
      print(userData.lastname.toString() + userData.name + userData.middlename);
    });
  }

  bool passwordVisible = false;

  @override
  void initState() {
    super.initState();
    passwordVisible = true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //backgroundColor: Color.fromARGB(255, 114, 154, 207),
      appBar: AppBar(
        title: const Text(''),
        backgroundColor: Color.fromARGB(255, 255, 255, 255),
        elevation: 0,
      ),
      body: SizedBox(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        //padding: EdgeInsets.symmetric(horizontal: 250),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 400,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.only(bottom: 25),
                    child: const Text(
                      'Войдите в аккаунт',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 33,
                        fontWeight: FontWeight.w300,
                        color: Colors.black,
                      ),
                    ),
                  ),

                  //
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: TextFormField(
                      onEditingComplete: signIn,
                      controller: usernameController,
                      decoration: const InputDecoration(
                          focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                  width: 1,
                                  color: Color.fromARGB(255, 37, 87, 153))),
                          border: OutlineInputBorder(),
                          labelText: 'Имя пользователя',
                          hintText: 'Введите имя пользователя'),
                    ),
                  ),

                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: TextFormField(
                      onEditingComplete: signIn,
                      controller: passController,
                      obscureText: passwordVisible,
                      decoration: InputDecoration(
                        focusedBorder: const OutlineInputBorder(
                            borderSide: BorderSide(
                                width: 1,
                                color: Color.fromARGB(255, 37, 87, 153))),
                        border: const OutlineInputBorder(),
                        labelText: 'Пароль',
                        hintText: 'Введите пароль',
                        errorText: errorText.isEmpty ? null : errorText,
                        suffixIcon: IconButton(
                          splashRadius: 20,
                          icon: Icon(passwordVisible
                              ? Icons.visibility_off
                              : Icons.visibility),
                          onPressed: () {
                            setState(
                              () {
                                passwordVisible = !passwordVisible;
                              },
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  /*TextButton(
                    onPressed: () {
                      //TODO FORGOT PASSWORD SCREEN
                    },
                    child: const Text(
                      'Забыли пароль?',
                      style: TextStyle(
                          color: Color.fromARGB(255, 0, 102, 204), fontSize: 15),
                    ),
                  ),*/
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    height: 65,
                    child: ElevatedButton(
                      onPressed: signIn,
                      style: ButtonStyle(
                          shape:
                              MaterialStateProperty.all<RoundedRectangleBorder>(
                                  RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5.0),
                      ))),
                      child: const Text(
                        'Войти',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 7),
                        height: 40,
                        child: TextButton(
                          style: TextButton.styleFrom(
                            textStyle: const TextStyle(fontSize: 16),
                          ),
                          onPressed: () {
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => RegistrationPage()),
                              (Route<dynamic> route) => true,
                            );
                          },
                          child: const Text('Регистрация'),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 7),
                        height: 40,
                        child: TextButton(
                          style: TextButton.styleFrom(
                            textStyle: const TextStyle(fontSize: 16),
                          ),
                          onPressed: () {
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => ChangePassPage()),
                              (Route<dynamic> route) => true,
                            );
                          },
                          child: const Text('Забыли пароль?'),
                        ),
                      )
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
