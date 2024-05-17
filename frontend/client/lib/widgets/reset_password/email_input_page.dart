import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'otp_input_page.dart';

class EmailInputPage extends StatefulWidget {
  @override
  _EmailInputPageState createState() => _EmailInputPageState();
}

class _EmailInputPageState extends State<EmailInputPage> {
  final dio = Dio();
  final emailController = TextEditingController();
  String message = '';
  String errorText = '';

  Future sendPasswordResetRequest() async {
    try {
      Response response = await dio.post(
        'http://localhost:8000/password-reset/',
        data: {
          'email': emailController.text,
        },
      );
      setState(() {
        message = 'Код подтверждения для сброса пароля был отправлен на почту.';
        errorText = '';
      });
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OtpInputPage(email: emailController.text),
        ),
      );
    } on DioError catch (e) {
      setState(() {
        errorText =
            'Произошла ошибка. Убедитесь, что вы ввели почту, к которой привязан аккаунт.';
        message = '';
      });
    }
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
                      'Введите почту',
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
                  if (message.isNotEmpty)
                    Text(message, textAlign: TextAlign.center),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
