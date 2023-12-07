import 'package:client/models/auth.dart';
import 'package:client/models/chats.dart';
import 'package:client/models/userProfile.dart';
import 'package:client/widgets/zero_page.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'main_screen.dart';

class ChangePassPage extends StatefulWidget {
  @override
  _ChangePassPage createState() => _ChangePassPage();
}

class _ChangePassPage extends State<ChangePassPage> {
  final dio = Dio();
  final usernameController = TextEditingController();
  final passController = TextEditingController();
  final passController2 = TextEditingController();
  String errorText = '';

  late UserProfile userData;
  Chats chat = Chats(0, '', '', 0, 0);

  Future signIn() async {
    Auth auth = await register();
    setState(() {});
    if (auth.authenticated) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => ZeroPage(auth, userData)),
        (Route<dynamic> route) => true,
      );
    } else {
      setState(() {
        errorText = auth.authError;
      });
    }
  }

  Future register() async {
    // Returns true if auth succeeded.
    try {
      Response response = await dio.post(
        'http://localhost:8000/changepassword/',
        data: {
          'username': usernameController.text,
          'password': passController.text,
          'password2': passController2.text,
        },
      );

      await getUserProfileData(response);

      print("user data userId");
      print(userData.userId);

      // GET /user/profile -> {user_id: username: email: first_name: last_name: avatat:}
      // GET /user/profile/<id>
      // PATCH /user/profile/<id>
      print(response.data['access']);
      return Auth(userData.userId.toString(), response.data['access'], true);
    } on DioError catch (e) {
      if (e.response!.data['detail'] == null) {
        return Auth('', '', false,
            authError: 'Пароль должен содержать минимум 8 символов');
      } else if (e.response != null) {
        return Auth('', '', false, authError: e.response!.data['detail']);
      }
      return Auth('', '', false, authError: 'Ошибка сети..');
    }
  }

  Future getUserProfileData(Response res) async {
    Response returnedResult =
        await dio.get('http://localhost:8000/changepassword'
            //options: Options(headers: {
            //       'Authorization': "Bearer ${res.data['access']}",
            //     })
            );

    print(returnedResult.data);
    UserProfile user = UserProfile('', '', '', '', '', '');
    if ((returnedResult.data as List<dynamic>).length > 0) {
      user = UserProfile(
        returnedResult.data[0]['user_id'],
        returnedResult.data[0]['username'].toString(),
        returnedResult.data[0]['first_name'].toString(),
        returnedResult.data[0]['last_name'].toString(),
        returnedResult.data[0]['middle_name'].toString(),
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
  bool passwordVisible2 = false;

  @override
  void initState() {
    super.initState();
    passwordVisible = true;
    passwordVisible2 = true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //backgroundColor: Color.fromARGB(255, 114, 154, 207),
      appBar: AppBar(
        title: const Text(''),
        backgroundColor: Color.fromARGB(255, 255, 255, 255),
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
                      'Изменить пароль',
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
                      controller: passController2,
                      obscureText: passwordVisible,
                      decoration: InputDecoration(
                        focusedBorder: const OutlineInputBorder(
                            borderSide: BorderSide(
                                width: 1,
                                color: Color.fromARGB(255, 37, 87, 153))),
                        border: const OutlineInputBorder(),
                        labelText: 'Пароль',
                        hintText: 'Придумайте пароль',
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
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: TextFormField(
                      onEditingComplete: signIn,
                      controller: passController,
                      obscureText: passwordVisible2,
                      decoration: InputDecoration(
                        focusedBorder: const OutlineInputBorder(
                            borderSide: BorderSide(
                                width: 1,
                                color: Color.fromARGB(255, 37, 87, 153))),
                        border: const OutlineInputBorder(),
                        labelText: 'Повтор пароля',
                        hintText: 'Повторите пароль',
                        errorText: errorText.isEmpty ? null : errorText,
                        suffixIcon: IconButton(
                          splashRadius: 20,
                          icon: Icon(passwordVisible2
                              ? Icons.visibility_off
                              : Icons.visibility),
                          onPressed: () {
                            setState(
                              () {
                                passwordVisible2 = !passwordVisible2;
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
                        'Сменить пароль',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
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
