import 'dart:convert';
import 'package:client/models/userProfile.dart';
import 'package:client/widgets/main_screen.dart';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:client/widgets/main_screen.dart';
import 'package:client/models/auth.dart';
import 'package:client/models/userProfile.dart';
import 'package:windows_taskbar/windows_taskbar.dart';

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

  Future<Auth> login(String email, String password) async {
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
      print(userData.userId);

      // GET /user/profile -> {user_id: username: email: first_name: last_name: avatat:}
      // GET /user/profile/<id>
      // PATCH /user/profile/<id>
      print(response.data['access']);
      return Auth(userData.userId, response.data['access'], true);
    } on DioError catch (e) {
      if (e.response != null) {
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
    UserProfile user = UserProfile('', '');
    if ((returnedResult.data as List<dynamic>).length > 0) {
      user = UserProfile(
        returnedResult.data[0]['user_id'].toString(),
        returnedResult.data[0]['avatar'].toString(),
      );
    }
    print("here is the result");
    print(returnedResult.data);

    setState(() {
      userData = user;
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
        backgroundColor: Color.fromARGB(255, 37, 87, 153),
      ),
      body: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        //padding: EdgeInsets.symmetric(horizontal: 250),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
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
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: TextField(
                      controller: usernameController,
                      decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Имя пользователя',
                          hintText: 'Введите имя пользователя'),
                    ),
                  ),

                  Container(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: TextField(
                      controller: passController,
                      obscureText: passwordVisible,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
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
                    padding: EdgeInsets.symmetric(vertical: 8),
                    height: 65,
                    child: ElevatedButton(
                      onPressed: () async {
                        Auth auth = await login(
                            usernameController.text, passController.text);
                        setState(() {});
                        if (auth.authenticated) {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    MainScreen(auth, userData)),
                            (Route<dynamic> route) => false,
                          );
                        } else {
                          setState(() {
                            errorText = auth.authError;
                          });
                        }
                      },
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
                          fontSize: 24,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
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
