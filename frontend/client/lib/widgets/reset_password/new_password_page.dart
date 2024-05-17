import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../login_page.dart';

class NewPasswordPage extends StatefulWidget {
  final String email;
  final String otp;

  NewPasswordPage({required this.email, required this.otp});

  @override
  _NewPasswordPageState createState() => _NewPasswordPageState();
}

class _NewPasswordPageState extends State<NewPasswordPage> {
  final dio = Dio();
  final passController = TextEditingController();
  final passController2 = TextEditingController();
  String errorText = '';
  bool passwordVisible = false;
  bool passwordVisible2 = false;

  Future resetPassword() async {
    try {
      Response response = await dio.post(
        'http://localhost:8000/set-new-password/',
        data: {
          'email': widget.email,
          'otp': widget.otp,
          'password': passController.text,
          'password2': passController2.text,
        },
      );
      if (response.statusCode == 200) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => LoginPage()),
          (Route<dynamic> route) => false,
        );
      } else {
        setState(() {
          errorText = 'Failed to reset password.';
        });
      }
    } on DioError catch (e) {
      setState(() {
        errorText = 'Failed to reset password.';
      });
    }
  }

  @override
  void initState() {
    super.initState();
    passwordVisible = true;
    passwordVisible2 = true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
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
                      'Введите новый пароль',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 33,
                        fontWeight: FontWeight.w300,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: TextFormField(
                      onEditingComplete: resetPassword,
                      controller: passController,
                      obscureText: passwordVisible,
                      decoration: InputDecoration(
                        focusedBorder: const OutlineInputBorder(
                            borderSide: BorderSide(
                                width: 1,
                                color: Color.fromARGB(255, 37, 87, 153))),
                        border: const OutlineInputBorder(),
                        labelText: 'Новый пароль',
                        hintText: 'Введите новый пароль',
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
                      onEditingComplete: resetPassword,
                      controller: passController2,
                      obscureText: passwordVisible2,
                      decoration: InputDecoration(
                        focusedBorder: const OutlineInputBorder(
                            borderSide: BorderSide(
                                width: 1,
                                color: Color.fromARGB(255, 37, 87, 153))),
                        border: const OutlineInputBorder(),
                        labelText: 'Подтвердите пароль',
                        hintText: 'Введите новый пароль еще раз',
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
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    height: 65,
                    child: ElevatedButton(
                      onPressed: resetPassword,
                      style: ButtonStyle(
                          shape:
                              MaterialStateProperty.all<RoundedRectangleBorder>(
                                  RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5.0),
                      ))),
                      child: const Text(
                        'Сбросить пароль',
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
