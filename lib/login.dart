import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'main_screen.dart';
import 'first_screen.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  TextEditingController _passwordController = TextEditingController();
  late String savedPassword;
  final LocalAuthentication _localAuthentication = LocalAuthentication();
  String enteredPin = '';

  @override
  void initState() {
    super.initState();
    _getSavedPassword();
  }

  _getSavedPassword() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      savedPassword = prefs.getString('pin') ?? "";
    });
  }

  Future<void> _authorizeNow() async {
    bool isAuthorized = false;
    try {
      isAuthorized = await _localAuthentication.authenticate(
        localizedReason: "Please authenticate to Login",
      );
    } catch (e) {
      print(e);
    }

    if (isAuthorized) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => MyHome()),
      );
    } else {
      print("Not Authorized!");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        title: Text('Verify Yourself',style: TextStyle(
          color: Colors.white60,
        ),),
        backgroundColor: Colors.grey[850],
      ),
      body: Stack(
    children: [
    // Background Image
    Image.asset(
    'assets/wel.jpeg',
    width: double.infinity,
    height: double.infinity,
    fit: BoxFit.cover,
    ),
    // Login UI
    SingleChildScrollView(
    child: Column(
    children: [

          Container(
            padding: EdgeInsets.only(top: 10, bottom: 10),
            child: Text(
              "You can Login with FingerPrint or FaceID",
              style: TextStyle(color: Colors.white60),
            ),
          ),
          Center(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.8,
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[700],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  PinCodeTextField(
                    appContext: context,
                    length: 4,
                    obscureText: true,cursorColor: Colors.white60,
                    obscuringCharacter: '*',
                    onChanged: (value) {
                      enteredPin = value;

                    },
                    pinTheme: PinTheme(
                      shape: PinCodeFieldShape.underline,
                      inactiveColor: Colors.white,
                      activeColor: Colors.white,
                      activeFillColor: Colors.white,
                      inactiveFillColor: Colors.white,
                      selectedColor: Colors.white,
                    ),
                    textStyle: TextStyle(color: Colors.white),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    child: Text('Login'),
                    onPressed: () {
                      if (enteredPin == savedPassword) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => MyHome()),
                        );
                      } else {
                        // show some error message
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          SizedBox(width: 40),
          Row(
            mainAxisSize: MainAxisSize.min, // set it to min
            children: [
              ElevatedButton(
                onPressed: _authorizeNow,
                child: Icon(Icons.fingerprint),
              ),
              SizedBox(width: 10),
              ElevatedButton(
                onPressed: _authorizeNow,
                child: Icon(Icons.face_unlock_sharp),
              )
            ],
          ),
        ],
      ),
    ),
      ],
      ),
    );
  }
}