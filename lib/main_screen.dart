import 'dart:io';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:locker/contactses.dart';
import 'package:locker/first_screen.dart';
import 'package:locker/videoss.dart';
import 'signup.dart';
import 'filesss.dart';

class MyHome extends StatefulWidget {

  @override
  MainScreen createState() => MainScreen();
}

class MainScreen extends State<MyHome>{



  int _selectedIndex = 0;
  // ignore: prefer_final_fields
  List<Widget> _widgetOptions = [];

  @override
  void initState() {
    super.initState();

    // Initialize _widgetOptions in the initState method
    _widgetOptions = [
      Images(),
      Videos(),
      ContactVault(),
      FileStorageApp(),
      Container(
        child: ListView(
          children: [
            ElevatedButton(
              child: Text('Logout'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => HomePage()),
                );
              },
            ),
          ],
        ),
      ),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Privacy Vault"),

      ),
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
          items:  <BottomNavigationBarItem>[
            BottomNavigationBarItem(
                icon: Icon(Icons.image),
                label: 'Photos',
                backgroundColor: Colors.green
            ),
            BottomNavigationBarItem(
                icon: Icon(Icons.video_chat),
                label:'Video',
                backgroundColor: Colors.yellow
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.contacts),
              label:'Profile',
              backgroundColor: Colors.blue,
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.file_upload),
              label:'Passwords',
              backgroundColor: Colors.red,
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.logout),
              label:'Logout',
              backgroundColor: Colors.grey,
            ),


          ],
          type: BottomNavigationBarType.shifting,
          currentIndex: _selectedIndex,
          selectedItemColor: Colors.black,
          iconSize: 40,
          onTap: _onItemTapped,
          elevation: 5
      ),
    );
  }
}