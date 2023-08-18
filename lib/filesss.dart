import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path;

class FileStorageApp extends StatefulWidget {
  @override
  _FileStorageAppState createState() => _FileStorageAppState();
}

class _FileStorageAppState extends State<FileStorageApp> {
  List<File> _selectedFiles = [];
  late Database _database;

  @override
  void initState() {
    super.initState();
    initDatabase();
  }

  Future<void> initDatabase() async {
    final appDocumentDir = await getApplicationDocumentsDirectory();
    final dbPath = path.join(appDocumentDir.path, 'file_storage.db');

    // Open the database and create the table if it doesn't exist
    _database = await openDatabase(
      dbPath,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE files (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            filePath TEXT
          )
        ''');
      },
    );

    // Load files from the database when the app starts
    List<Map<String, dynamic>> filesData = await _database.query('files');
    List<File> files = filesData.map((fileData) => File(fileData['filePath'])).toList();
    setState(() {
      _selectedFiles = files;
    });
  }

  Future<void> pickFiles() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      allowMultiple: true,
    );

    if (result != null) {
      List<File> files = result.paths.map((path) => File(path!)).toList();

      // Save the selected files to the database
      for (var file in files) {
        await _database.insert(
          'files',
          {'filePath': file.path},
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      setState(() {
        _selectedFiles.addAll(files);
      });
    }
  }

  Future<void> removeFile(int index) async {
    final file = _selectedFiles[index];

    // Remove the file from the app storage
    await file.delete();

    // Remove the file path from the database
    await _database.delete(
      'files',
      where: 'filePath = ?',
      whereArgs: [file.path],
    );

    setState(() {
      _selectedFiles.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('File Storage App'),
      ),
      body: _selectedFiles.isEmpty
          ? Center(child: Text('No files selected.'))
          : ListView.builder(
        itemCount: _selectedFiles.length,
        itemBuilder: (context, index) {
          final file = _selectedFiles[index];
          return ListTile(
            title: Text(file.path.split('/').last),
            trailing: IconButton(
              icon: Icon(Icons.delete),
              onPressed: () => removeFile(index),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          pickFiles();
        },
        child: Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
