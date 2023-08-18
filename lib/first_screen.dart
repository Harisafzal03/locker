import 'package:flutter/material.dart';
import 'package:analog_clock/analog_clock.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login.dart';
import 'signing.dart';


class HomePage extends StatefulWidget {


  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool isRegistered = false;

  @override
  void initState() {
    super.initState();
    _checkRegistration();
  }

  _checkRegistration() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      isRegistered = prefs.getBool('isRegistered') ?? false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black12,
      body: Stack(
        children: [
          Image.asset(
            'assets/img_1.png',
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover,
          ),
          // Column(
          //   children: [
          //     Expanded(
          //       child: AnalogClock(
          //         decoration: BoxDecoration(
          //           border: Border.all(width: 2.0, color: Colors.white),
          //           color: Colors.transparent,
          //           shape: BoxShape.circle,
          //           boxShadow: [
          //             BoxShadow(
          //               offset: Offset(0, 2), // Position of shadow
          //               blurRadius: 50, // Softness of shadow
          //               color: Colors.white70.withOpacity(0.3), // Color with transparency
          //             ),
          //           ],
          //         ),
          //         width: 350.0,
          //         height: 650,
          //         isLive: true,
          //         hourHandColor: Colors.white,
          //         minuteHandColor: Colors.white70,
          //         showSecondHand: true,
          //         numberColor: Colors.white,
          //         showNumbers: true,
          //         showAllNumbers: false,
          //         textScaleFactor: 1.4,
          //         showTicks: true,
          //         showDigitalClock: true,
          //         digitalClockColor: Colors.white,
          //       ),
          //     ),
          //   ],
          // ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.all(8.0),
        child: TextButton(
          style: TextButton.styleFrom(
            backgroundColor: Colors.white70,
          ),
          child: Text('Set Pin', style: TextStyle(color: Colors.black)),
          onPressed: () async {
            var navigationResult = await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => isRegistered ? LoginPage() : SignUpPage()),
            );
            if(navigationResult == 'refresh') {
              _checkRegistration();
            }
          },
        ),
      ),
    );
  }
}