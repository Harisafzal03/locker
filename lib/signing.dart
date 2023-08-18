import 'package:flutter/material.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SignUpPage extends StatefulWidget {
  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  String pin = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        title: Text('Set Pin',style: TextStyle(
          color: Colors.white60,
        ),),
        backgroundColor: Colors.grey[850],
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(
            'Set a Pin:',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
            ),
          ),
          SizedBox(height: 50),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 50.0),
            child: PinCodeTextField(
              appContext: context,
              length: 4,
              obscureText: true,cursorColor: Colors.white60,
              obscuringCharacter: '*',
              pinTheme: PinTheme(
                shape: PinCodeFieldShape.box,
                borderRadius: BorderRadius.circular(5),
                fieldHeight: 50,
                fieldWidth: 50,
                inactiveFillColor: Colors.white,
                activeFillColor: Colors.white,
                selectedFillColor: Colors.white,
                inactiveColor: Colors.white,
                activeColor: Colors.white,
                selectedColor: Colors.white,
              ),
              textStyle: TextStyle(fontSize: 20, height: 1.6, color: Colors.white60),
              onChanged: (value) {
                pin = value;
              },
              onCompleted: (value) async {
                SharedPreferences prefs = await SharedPreferences.getInstance();
                prefs.setString('pin', pin);
                prefs.setBool('isRegistered', true);
                Navigator.pop(context, 'refresh');
              },
            ),
          ),
        ],
      ),
    );
  }
}