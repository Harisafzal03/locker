import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photo_view/photo_view.dart';

class Images extends StatefulWidget {
  @override
  _ImagesState createState() => _ImagesState();
}

class _ImagesState extends State<Images> {
  List<File> _selectedImages = [];
  List<bool> _isSelected = [];
  bool _isImageDeleteMode = false;

  Future<void> saveImageToLocalDirectory(File imageFile) async {
    final appDocumentDir = await getApplicationDocumentsDirectory();
    final imagePath = '${appDocumentDir.path}/${imageFile.path.split('/').last}';
    await imageFile.copy(imagePath);
  }

  Future<void> removeImageFromAppStorage(File imageFile) async {
    try {
      await imageFile.delete();
    } catch (e) {
      print('Error removing image: $e');
    }
  }

  Future<List<File>> loadImagesFromLocalDirectory() async {
    final appDocumentDir = await getApplicationDocumentsDirectory();
    final dir = Directory(appDocumentDir.path);
    List<File> images = [];

    final files = await dir.list().toList();
    for (var file in files) {
      if (file is File) {
        images.add(file);
      }
    }

    return images;
  }

  @override
  void initState() {
    super.initState();
    // Load images from local directory when the app starts
    loadImagesFromLocalDirectory().then((images) {
      setState(() {
        _selectedImages = images;
        _isSelected = List.generate(images.length, (_) => false); // Initialize _isSelected list
      });
    });
  }

  Future<void> pickImage(ImageSource source) async {
    final pickedFile = await ImagePicker().pickImage(source: source);

    if (pickedFile != null) {
      final imageFile = File(pickedFile.path);

      setState(() {
        _selectedImages.add(imageFile);
        _isSelected.add(false);
      });

      // Save the selected image to the local directory
      await saveImageToLocalDirectory(imageFile);
    } else {
      print('No image selected.');
    }
  }

  Future<void> removeImage(int index) async {
    final imageFile = _selectedImages[index];

    // Remove the image from the app storage
    await removeImageFromAppStorage(imageFile);

    // Remove the image from the cache to release the occupied space
    await DefaultCacheManager().removeFile(imageFile.path);

    setState(() {
      _selectedImages.removeAt(index);
      _isSelected.removeAt(index);
    });
  }

  void toggleSelection(int index) {
    setState(() {
      _isSelected[index] = !_isSelected[index];
    });
  }

  void _showDeleteConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Selected Images'),
          content: Text('Are you sure you want to delete the selected images?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                deleteSelectedImages();
                Navigator.pop(context);
              },
              child: Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  Future<void> deleteSelectedImages() async {
    List<int> selectedIndices = [];
    for (var i = 0; i < _isSelected.length; i++) {
      if (_isSelected[i]) {
        selectedIndices.add(i);
      }
    }

    // Remove the images in reverse order to avoid index issues
    selectedIndices.sort((a, b) => b.compareTo(a));
    for (var index in selectedIndices) {
      final imageFile = _selectedImages[index];

      // Remove the image from app storage
      await removeImageFromAppStorage(imageFile);

      // Remove the image from the cache to release the occupied space
      await DefaultCacheManager().removeFile(imageFile.path);

      setState(() {
        _selectedImages.removeAt(index);
        _isSelected.removeAt(index);
      });
    }

    // After deletion, disable the delete mode
    setState(() {
      _isImageDeleteMode = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Image Storage"),
      ),
      body: _selectedImages.isEmpty
          ? Center(child: Text('No images selected.'))
          : GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: _selectedImages.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onLongPress: () {
              // Enable image selection mode on long press
              setState(() {
                _isImageDeleteMode = true;
              });
              toggleSelection(index);
            },
            onTap: () {
              if (_isImageDeleteMode) {
                // Toggle selection on tap when in delete mode
                toggleSelection(index);
              } else {
                // View the image on single-tap
                openImageInApp(_selectedImages[index]);
              }
            },
            child: Stack(
              children: [
                Image.file(_selectedImages[index]),
                if (_isImageDeleteMode)
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
            onPressed: () => pickImage(ImageSource.camera),
            tooltip: 'Pick Image from Camera',
            child: Icon(Icons.camera),
          ),
          SizedBox(height: 10),
          FloatingActionButton(
            onPressed: () => pickImage(ImageSource.gallery),
            tooltip: 'Pick Image from Gallery',
            child: Icon(Icons.image),
          ),
          if (_isImageDeleteMode) SizedBox(height: 10),
          if (_isImageDeleteMode)
            FloatingActionButton(
              onPressed: () {
                setState(() {
                  _isImageDeleteMode = false; // Disable delete mode
                  _isSelected.fillRange(0, _isSelected.length, false); // Unselect all images
                });
              },
              tooltip: 'Cancel Delete',
              child: Icon(Icons.close),
              backgroundColor: Colors.red,
            ),
          if (!_isImageDeleteMode)
            FloatingActionButton(
              onPressed: () {
                setState(() {
                  _isImageDeleteMode = true; // Enable delete mode
                });
              },
              tooltip: 'Delete Images',
              child: Icon(Icons.delete),
            ),
          if (_isImageDeleteMode)
            FloatingActionButton(
              onPressed: () {
                // Show delete confirmation dialog only if any images are selected
                if (_isSelected.contains(true)) {
                  _showDeleteConfirmationDialog();
                }
              },
              tooltip: 'Delete Selected Images',
              child: Icon(Icons.delete_forever),
              backgroundColor: Colors.red,
            ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButtonAnimator: FloatingActionButtonAnimator.scaling,
    );
  }

  void openImageInApp(File imageFile) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PhotoView(
          imageProvider: FileImage(imageFile),
        ),
      ),
    );
  }
}
