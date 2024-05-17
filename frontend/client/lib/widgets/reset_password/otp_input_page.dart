import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'new_password_page.dart';

class OtpInputPage extends StatefulWidget {
  final String email;

  OtpInputPage({required this.email});

  @override
  _OtpInputPageState createState() => _OtpInputPageState();
}

class _OtpInputPageState extends State<OtpInputPage> {
  final dio = Dio();
  final otpController = TextEditingController();
  String errorText = '';

  Future verifyOtp() async {
    try {
      Response response = await dio.post(
        'http://localhost:8000/otp-verification/',
        data: {
          'email': widget.email,
          'otp': otpController.text,
        },
      );
      setState(() {
        errorText = '';
      });
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              NewPasswordPage(email: widget.email, otp: otpController.text),
        ),
      );
    } on DioError catch (e) {
      setState(() {
        errorText = 'Invalid OTP.';
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
                      'Введите код подтверждения',
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
                      onEditingComplete: verifyOtp,
                      controller: otpController,
                      decoration: InputDecoration(
                        focusedBorder: const OutlineInputBorder(
                            borderSide: BorderSide(
                                width: 1,
                                color: Color.fromARGB(255, 37, 87, 153))),
                        border: const OutlineInputBorder(),
                        labelText: 'Код подтверждения',
                        hintText: 'Введите код подтверждения',
                        errorText: errorText.isEmpty ? null : errorText,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    height: 65,
                    child: ElevatedButton(
                      onPressed: verifyOtp,
                      style: ButtonStyle(
                          shape:
                              MaterialStateProperty.all<RoundedRectangleBorder>(
                                  RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5.0),
                      ))),
                      child: const Text(
                        'Проверить код',
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
