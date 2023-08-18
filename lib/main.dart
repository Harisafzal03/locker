import 'package:flutter/material.dart';
import 'package:locker/contactses.dart';
import 'package:locker/filesss.dart';
import 'package:locker/first_screen.dart';
import 'package:locker/main_screen.dart';
import 'package:locker/signup.dart';
import 'package:locker/videoss.dart';


void main() {
  runApp( MyApp());

}

class MyApp extends StatelessWidget {
  MyApp({super.key});


  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vault',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: HomePage(),
    );
  }
}


