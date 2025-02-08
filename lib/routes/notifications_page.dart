import 'package:flutter/material.dart';
import 'package:image_pickers/image_pickers.dart';
import 'dart:io';

class NotificationsPage extends StatefulWidget {
  @override
  _NotificationsPageState createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  List<File> _images = []; // 存储选择的图片列表

  // 异步函数用于选择多张图片
  Future<void> selectImages() async {
    // 使用 ImagePickers.pickerPaths 来选择多张图片
    List<Media> selectedImages = await ImagePickers.pickerPaths(
      galleryMode: GalleryMode.image, // 选择图库中的图片
      selectCount: 2, // 限制选择数量为2
      showGif: false, // 不显示GIF
      showCamera: true, // 显示相机按钮
      compressSize: 500, // 图片压缩到500KB以内
      uiConfig: UIConfig(uiThemeColor: Color(0xffff0f50)), // 自定义UI主题颜色
      cropConfig: CropConfig(enableCrop: false, width: 2, height: 1), // 不启用裁剪
    );

    // 如果用户选择了图片
    if (selectedImages.isNotEmpty) {
      setState(() {
        // 将选中的图片路径转换为 File 对象并存储
        _images = selectedImages.map((media) => File(media.path??"" )).toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('通知页面'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 如果没有选择图片，显示提示文本
            _images.isEmpty
                ? Text('未选择图片', style: TextStyle(fontSize: 18))
                : Column(
              children: _images.map((image) {
                // 显示选中的每张图片
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Image.file(image, height: 100, width: 100, fit: BoxFit.cover),
                );
              }).toList(),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: selectImages, // 点击按钮选择多张图片
              child: Text('从图库选择图片'),
            ),
          ],
        ),
      ),
    );
  }
}
