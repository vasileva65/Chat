import 'package:client/models/auth.dart';
import 'package:client/models/chats.dart';
import 'package:client/models/userProfile.dart';
import 'package:client/widgets/login_page.dart';
import 'package:client/widgets/zero_page.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'main_screen.dart';

class RegistrationPage extends StatefulWidget {
  @override
  _RegistrationPage createState() => _RegistrationPage();
}

class _RegistrationPage extends State<RegistrationPage> {
  final dio = Dio();
  final usernameController = TextEditingController();
  final passController = TextEditingController();
  final passController2 = TextEditingController();
  final nameController = TextEditingController();
  final lastnameController = TextEditingController();
  final middlenameController = TextEditingController();
  String errorText = '';

  late UserProfile userData;
  Chats chat = Chats(0, '', '', 0, 0, '');

  Future signIn() async {
    Auth auth = await register();
    setState(() {});
    if (auth.authenticated) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
            builder: (context) => MainScreen(auth, userData,
                chat: chat, showUsernameDialog: true)),
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
        'http://localhost:8000/register/',
        data: {
          'first_name': nameController.text,
          'last_name': lastnameController.text,
          'middle_name': middlenameController.text,
          'password': passController.text,
          'password2': passController2.text,
        },
      );
      print(response);
      await getUserProfileData(response);

      print("user data userId");
      print(userData.userId);

      // GET /user/profile -> {user_id: username: email: first_name: last_name: avatat:}
      // GET /user/profile/<id>
      // PATCH /user/profile/<id>
      print(response.data['access']);

      return Auth(userData.userId.toString(), response.data['access'], true);
    } on DioError catch (e) {
      print("RES");
      print(e.response!.data);
      //print(e.response!.data['password'][0]);
      if (e.response!.data['password'] != null) {
        return Auth('', '', false, authError: e.response!.data['password'][0]);
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
        returnedResult.data[0]['id'],
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
                      'Создайте аккаунт',
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
                      onEditingComplete: signIn,
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
                      onEditingComplete: signIn,
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
                        errorMaxLines: 2,
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
                        errorMaxLines: 2,
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
                        'Регистрация',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        height: 40,
                        child: const Text('Уже есть аккаунт?',
                            style: TextStyle(fontSize: 16)),
                      ),
                      //const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 7),
                        height: 38,
                        child: TextButton(
                          style: TextButton.styleFrom(
                            textStyle: const TextStyle(fontSize: 16),
                          ),
                          onPressed: () {
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => LoginPage()),
                              (Route<dynamic> route) => false,
                            );
                          },
                          child: const Text('Войти'),
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
