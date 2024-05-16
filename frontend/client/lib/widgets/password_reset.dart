import 'package:client/models/auth.dart';
import 'package:client/models/chat.dart';
import 'package:client/models/userProfile.dart';
import 'package:client/widgets/zero_page.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'main_screen.dart';

class PasswordResetRequestPage extends StatefulWidget {
  @override
  _PasswordResetRequestPage createState() => _PasswordResetRequestPage();
}

class _PasswordResetRequestPage extends State<PasswordResetRequestPage> {
  final dio = Dio();
  String errorText = '';
  final emailController = TextEditingController();
  String message = '';

  late UserProfile userData;
  Chat chat = Chat(0, '', '', 0, 0, '');

  Future sendPasswordResetRequest() async {
    try {
      Response response = await dio.post(
        'http://localhost:8000/password-reset/',
        data: {
          'email': emailController.text,
        },
      );
      setState(() {
        message = 'Password reset link has been sent to your email.';
        errorText = '';
      });
    } on DioError catch (e) {
      setState(() {
        errorText = e.response?.data['email']?.first ??
            'Failed to send password reset email.';
        message = '';
      });
    }
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
                      'Введите почту',
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
                      onEditingComplete: sendPasswordResetRequest,
                      controller: emailController,
                      decoration: InputDecoration(
                        focusedBorder: const OutlineInputBorder(
                            borderSide: BorderSide(
                                width: 1,
                                color: Color.fromARGB(255, 37, 87, 153))),
                        border: const OutlineInputBorder(),
                        labelText: 'Почта',
                        hintText: 'Введите почту, привязанную к аккаунту',
                        errorText: errorText.isEmpty ? null : errorText,
                      ),
                    ),
                  ),
                  // Container(
                  //   padding: const EdgeInsets.symmetric(vertical: 8),
                  //   child: TextFormField(
                  //     onEditingComplete: signIn,
                  //     controller: passController2,
                  //     obscureText: passwordVisible,
                  //     decoration: InputDecoration(
                  //       focusedBorder: const OutlineInputBorder(
                  //           borderSide: BorderSide(
                  //               width: 1,
                  //               color: Color.fromARGB(255, 37, 87, 153))),
                  //       border: const OutlineInputBorder(),
                  //       labelText: 'Пароль',
                  //       hintText: 'Придумайте пароль',
                  //       errorText: errorText.isEmpty ? null : errorText,
                  //       suffixIcon: IconButton(
                  //         splashRadius: 20,
                  //         icon: Icon(passwordVisible
                  //             ? Icons.visibility_off
                  //             : Icons.visibility),
                  //         onPressed: () {
                  //           setState(
                  //             () {
                  //               passwordVisible = !passwordVisible;
                  //             },
                  //           );
                  //         },
                  //       ),
                  //     ),
                  //   ),
                  // ),
                  // Container(
                  //   padding: const EdgeInsets.symmetric(vertical: 8),
                  //   child: TextFormField(
                  //     onEditingComplete: signIn,
                  //     controller: passController,
                  //     obscureText: passwordVisible2,
                  //     decoration: InputDecoration(
                  //       focusedBorder: const OutlineInputBorder(
                  //           borderSide: BorderSide(
                  //               width: 1,
                  //               color: Color.fromARGB(255, 37, 87, 153))),
                  //       border: const OutlineInputBorder(),
                  //       labelText: 'Повтор пароля',
                  //       hintText: 'Повторите пароль',
                  //       errorText: errorText.isEmpty ? null : errorText,
                  //       suffixIcon: IconButton(
                  //         splashRadius: 20,
                  //         icon: Icon(passwordVisible2
                  //             ? Icons.visibility_off
                  //             : Icons.visibility),
                  //         onPressed: () {
                  //           setState(
                  //             () {
                  //               passwordVisible2 = !passwordVisible2;
                  //             },
                  //           );
                  //         },
                  //       ),
                  //     ),
                  //   ),
                  // ),
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
                      onPressed: sendPasswordResetRequest,
                      style: ButtonStyle(
                          shape:
                              MaterialStateProperty.all<RoundedRectangleBorder>(
                                  RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5.0),
                      ))),
                      child: const Text(
                        'Получить письмо',
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
