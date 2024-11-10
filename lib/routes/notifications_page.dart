import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class NotificationsPage extends StatefulWidget {
  @override
  NotificationPage createState() => NotificationPage();
}

class NotificationPage extends State<NotificationsPage> {
  File? _image;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _image == null
            ? Text('No image selected.', style: TextStyle(fontSize: 18))
            : Image.file(_image!, height: 200, width: 200, fit: BoxFit.cover),
        SizedBox(height: 20),
        ElevatedButton(
          onPressed: _pickImage,
          child: Text('Pick Image from Gallery'),
        ),
      ],
    );
  }
}
