import 'dart:convert';
import 'package:client/models/userProfile.dart';
import 'package:client/widgets/main_screen.dart';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:client/widgets/main_screen.dart';
import 'package:client/models/auth.dart';
import 'package:client/models/userProfile.dart';

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
      // TODO: if authenticated. call GET /user/profile
      // so that we can fetch user id from server, and replace 1 with actual
      // user id.

      // GET /user/profile -> {user_id: username: email: first_name: last_name: avatat:}
      // GET /user/profile/<id>
      // PATCH /user/profile/<id>
      print(response.data['access']);
      return Auth(userData.userId, response.data['access'], true);
    } on DioError catch (e) {
      if (e.response != null) {
        return Auth('', '', false, authError: e.response!.data['detail']);
      }
      return Auth('', '', false, authError: 'Network error..');
    }
  }

  Future getUserProfileData(Response res) async {
    Response returnedResult =
        await dio.get('http://localhost:8000/user/profile',
            options: Options(headers: {
              'Authorization': "Bearer ${res.data['access']}",
            }));

    print(returnedResult.data);
    UserProfile user = UserProfile('');
    if ((returnedResult.data as List<dynamic>).length > 0) {
      user = UserProfile(
        returnedResult.data[0]['user_id'].toString(),
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
        title: const Text('Login Page'),
        backgroundColor: Color.fromARGB(255, 0, 102, 204),
      ),
      body: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        padding: EdgeInsets.symmetric(horizontal: 250),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const Text(
              'Пожалуйста войдите в аккаунт',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 35,
                color: Colors.black,
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: TextField(
                controller: usernameController,
                decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Username',
                    hintText: 'Enter your username'),
              ),
            ),
            TextField(
              controller: passController,
              obscureText: passwordVisible,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Password',
                hintText: 'Enter the password',
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
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 30),
              child: Container(
                height: 50,
                width: 150,
                decoration: const BoxDecoration(
                  color: Color.fromARGB(255, 0, 102, 204),
                ),
                child: TextButton(
                  onPressed: () async {
                    Auth auth = await login(
                        usernameController.text, passController.text);
                    setState(() {});
                    if (auth.authenticated) {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                            builder: (context) => MainScreen(auth)),
                        (Route<dynamic> route) => true,
                      );
                    } else {
                      setState(() {
                        errorText = auth.authError;
                      });
                    }
                  },
                  child: const Text(
                    'Войти',
                    style: TextStyle(color: Colors.white, fontSize: 25),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
