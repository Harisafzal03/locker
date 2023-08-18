import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:fluttertoast/fluttertoast.dart';

// void main() {
//   runApp(MyApp());
// }

class Contact {
  final int id;
  final String name;
  final String phoneNumber;

  Contact({required this.id, required this.name, required this.phoneNumber});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phoneNumber': phoneNumber,
    };
  }

  @override
  String toString() {
    return 'Contact{id: $id, name: $name, phoneNumber: $phoneNumber}';
  }
}

class DatabaseHelper {
  static Database? _database;

  static Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    // If _database is null, create a new database instance
    _database = await initDatabase();
    return _database!;
  }

  static Future<Database> initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String dbPath = path.join(documentsDirectory.path, 'contacts.db');
    return await openDatabase(
      dbPath,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE contacts (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            phoneNumber TEXT
          )
        ''');
      },
    );
  }

  static Future<void> insertContact(Contact contact) async {
    final db = await database;
    await db.insert('contacts', contact.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<List<Contact>> getContacts() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('contacts');
    return List.generate(maps.length, (i) {
      return Contact(
        id: maps[i]['id'],
        name: maps[i]['name'],
        phoneNumber: maps[i]['phoneNumber'],
      );
    });
  }

  static Future<void> deleteContact(int id) async {
    final db = await database;
    await db.delete('contacts', where: 'id = ?', whereArgs: [id]);
  }
}

// class MyApp extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       home: ContactVault(),
//     );
//   }
// }

class ContactVault extends StatefulWidget {
  @override
  _ContactVaultState createState() => _ContactVaultState();
}

class _ContactVaultState extends State<ContactVault> {
  TextEditingController nameController = TextEditingController();
  TextEditingController phoneNumberController = TextEditingController();
  List<Contact> contacts = [];

  @override
  void initState() {
    super.initState();
    refreshContacts();
  }

  void refreshContacts() async {
    List<Contact> allContacts = await DatabaseHelper.getContacts();
    setState(() {
      contacts = allContacts;
    });
  }

  void saveContact() async {
    String name = nameController.text.trim();
    String phoneNumber = phoneNumberController.text.trim();

    if (name.isNotEmpty && phoneNumber.isNotEmpty) {
      Contact contact = Contact(id: DateTime.now().millisecondsSinceEpoch, name: name, phoneNumber: phoneNumber);
      await DatabaseHelper.insertContact(contact);
      Fluttertoast.showToast(msg: 'Contact saved successfully!');
      refreshContacts();
      nameController.clear();
      phoneNumberController.clear();
    } else {
      Fluttertoast.showToast(msg: 'Name and Phone Number cannot be empty!');
    }
  }

  void deleteContact(Contact contact) async {
    await DatabaseHelper.deleteContact(contact.id);
    Fluttertoast.showToast(msg: 'Contact deleted successfully!');
    refreshContacts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Contact Vault'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: nameController,
              decoration: InputDecoration(labelText: 'Name'),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: phoneNumberController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(labelText: 'Phone Number'),
            ),
          ),
          ElevatedButton(
            onPressed: saveContact,
            child: Text('Save Contact'),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: contacts.length,
              itemBuilder: (context, index) {
                Contact contact = contacts[index];
                return ListTile(
                  title: Text(contact.name),
                  subtitle: Text(contact.phoneNumber),
                  trailing: IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () => deleteContact(contact),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
