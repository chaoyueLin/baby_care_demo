import 'package:flutter/material.dart';

class ImagePreview extends StatefulWidget {
  final List<String> images;
  final int initialIndex;

  const ImagePreview({
    super.key,
    required this.images,
    this.initialIndex = 0,
  });

  @override
  State<ImagePreview> createState() => _AssetImagePreviewState();
}

class _AssetImagePreviewState extends State<ImagePreview> {
  late PageController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 支持 GrowPage 主题颜色和暗色模式
    final appBarBg = Theme.of(context).appBarTheme.backgroundColor;
    final appBarFg = Theme.of(context).appBarTheme.foregroundColor;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: Text(
          'Baby Growth Chart', // 你可以换成 S.of(context)?.addBabyInformation
        ),
        backgroundColor: appBarBg,
        foregroundColor: appBarFg,
        elevation: 2,
      ),
      body: PageView.builder(
        controller: _controller,
        itemCount: widget.images.length,
        itemBuilder: (context, index) {
          return InteractiveViewer(
            minScale: 0.8,
            maxScale: 5.0,
            child: Center(
              child: Image.asset(
                widget.images[index],
                fit: BoxFit.contain,
              ),
            ),
          );
        },
      ),
    );
  }
}
