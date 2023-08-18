import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photo_view/photo_view.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path;
import 'package:video_player/video_player.dart';

class Videos extends StatefulWidget {
  @override
  _VideosState createState() => _VideosState();
}

class _VideosState extends State<Videos> {
  List<File> _selectedVideos = [];
  List<bool> _isSelected = [];
  bool _isVideoDeleteMode = false;

  Future<void> pickVideo(ImageSource source) async {
    final pickedFile = await ImagePicker().pickVideo(source: source);

    if (pickedFile != null) {
      final videoFile = File(pickedFile.path);

      setState(() {
        _selectedVideos.add(videoFile);
        _isSelected.add(false);
      });

      // Save the selected video to the database
      await saveVideoToDatabase(videoFile);
    } else {
      print('No video selected.');
    }
  }

  Future<void> removeVideo(int index) async {
    final videoFile = _selectedVideos[index];

    // Remove the video from the app storage
    await removeVideoFromAppStorage(videoFile);

    setState(() {
      _selectedVideos.removeAt(index);
      _isSelected.removeAt(index);
    });

    // Remove the video from the database
    await removeVideoFromDatabase(videoFile);
  }

  Future<void> removeVideoFromAppStorage(File videoFile) async {
    try {
      await videoFile.delete();
    } catch (e) {
      print('Error removing video: $e');
    }
  }

  List<int> _selectedVideoIndices = [];

  void toggleSelection(int index) {
    setState(() {
      _isSelected[index] = !_isSelected[index];
    });
  }

  Future<void> deleteSelectedVideos() async {
    List<int> selectedIndices = [];
    for (var i = 0; i < _isSelected.length; i++) {
      if (_isSelected[i]) {
        selectedIndices.add(i);
      }
    }

    // Remove the videos in reverse order to avoid index issues
    selectedIndices.sort((a, b) => b.compareTo(a));
    for (var index in selectedIndices) {
      final videoFile = _selectedVideos[index];

      // Remove the video from app storage
      await removeVideoFromAppStorage(videoFile);

      setState(() {
        _selectedVideos.removeAt(index);
        _isSelected.removeAt(index);
      });
    }

    // After deletion, disable the delete mode
    setState(() {
      _isVideoDeleteMode = false;
    });
  }

  void _showDeleteConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Selected Videos'),
          content: Text('Are you sure you want to delete the selected videos?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                deleteSelectedVideos();
                Navigator.pop(context);
              },
              child: Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  Future<void> saveVideoToDatabase(File videoFile) async {
    final database = await initDatabase();
    final videoBytes = await videoFile.readAsBytes();
    await database.insert(
      'videos',
      {
        'name': videoFile.path.split('/').last,
        'data': videoBytes,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> removeVideoFromDatabase(File videoFile) async {
    final database = await initDatabase();
    await database.delete(
      'videos',
      where: 'name = ?',
      whereArgs: [videoFile.path.split('/').last],
    );
  }

  Future<Database> initDatabase() async {
    final appDocumentDir = await getApplicationDocumentsDirectory();
    final dbPath = path.join(appDocumentDir.path, 'videos.db');
    return openDatabase(
      dbPath,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE videos (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            data BLOB
          )
        ''');
      },
    );
  }

  Future<List<File>> loadVideosFromDatabase() async {
    final database = await initDatabase();
    final videosData = await database.query('videos');
    return videosData.map<File>((videoData) {
      final videoBytes = videoData['data'] as List<int>;
      final videoFile = File.fromRawPath(Uint8List.fromList(videoBytes));
      return videoFile;
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    // Load videos from the database when the app starts
    loadVideosFromDatabase().then((videos) {
      setState(() {
        _selectedVideos = videos;
        _isSelected = List.generate(videos.length, (_) => false);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Video Storage"),
      ),
      body: _selectedVideos.isEmpty
          ? Center(child: Text('No videos selected.'))
          : GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: _selectedVideos.length,
        itemBuilder: (context, index) {
          final videoFile = _selectedVideos[index];
          return GestureDetector(
            onLongPress: () {
              // Enable video selection mode on long press
              setState(() {
                _isVideoDeleteMode = true;
              });
              toggleSelection(index);
            },
            onTap: () {
              if (_isVideoDeleteMode) {
                // Toggle selection on tap when in delete mode
                toggleSelection(index);
              } else {
                // Play the video on single-tap
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => Scaffold(
                      appBar: AppBar(
                        title: Text('Video Player'),
                      ),
                      body: Center(
                        child: VideoPlayerWidget(videoFile: videoFile),
                      ),
                    ),
                  ),
                );
              }
            },
            child: Stack(
              children: [
                VideoPlayerWidget(videoFile: videoFile),
                if (_isVideoDeleteMode)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      padding: EdgeInsets.all(5),
                      color: _isSelected[index] ? Colors.red : Colors.transparent,
                      child: Icon(
                        Icons.check_circle,
                        color: _isSelected[index] ? Colors.white : Colors.transparent,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: () => pickVideo(ImageSource.camera),
            tooltip: 'Pick Video from Camera',
            child: Icon(Icons.videocam),
          ),
          SizedBox(height: 10),
          FloatingActionButton(
            onPressed: () => pickVideo(ImageSource.gallery),
            tooltip: 'Pick Video from Gallery',
            child: Icon(Icons.video_library),
          ),
          if (_isVideoDeleteMode) SizedBox(height: 10),
          if (_isVideoDeleteMode)
            FloatingActionButton(
              onPressed: () {
                setState(() {
                  _isVideoDeleteMode = false; // Disable delete mode
                  _isSelected.fillRange(0, _isSelected.length, false); // Unselect all videos
                });
              },
              tooltip: 'Cancel Delete',
              child: Icon(Icons.close),
              backgroundColor: Colors.red,
            ),
          if (!_isVideoDeleteMode)
            FloatingActionButton(
              onPressed: () {
                setState(() {
                  _isVideoDeleteMode = true; // Enable delete mode
                });
              },
              tooltip: 'Delete Videos',
              child: Icon(Icons.delete),
            ),
          if (_isVideoDeleteMode)
            FloatingActionButton(
              onPressed: () {
                // Show delete confirmation dialog only if any videos are selected
                if (_isSelected.contains(true)) {
                  _showDeleteConfirmationDialog();
                }
              },
              tooltip: 'Delete Selected Videos',
              child: Icon(Icons.delete_forever),
              backgroundColor: Colors.red,
            ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButtonAnimator: FloatingActionButtonAnimator.scaling,
    );
  }

  void playVideoInApp(File videoFile) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VideoPlayerWidget(videoFile: videoFile),
      ),
    );
  }
}

class VideoPlayerWidget extends StatefulWidget {
  final File videoFile;

  VideoPlayerWidget({required this.videoFile});

  @override
  _VideoPlayerWidgetState createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(widget.videoFile)
      ..initialize().then((_) {
        setState(() {
          _isInitialized = true;
          _controller.play(); // Start playing the video after initialization
        });
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitialized) {
      return AspectRatio(
        aspectRatio: _controller.value.aspectRatio,
        child: VideoPlayer(_controller),
      );
    } else {
      return Center(child: CircularProgressIndicator());
    }
  }
}

