import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class CustomTabButton extends StatelessWidget {
  final String label;
  final String iconPath;
  final VoidCallback onTap;

  const CustomTabButton({
    required this.label,
    required this.iconPath,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            iconPath,
            width: 30,
            height: 30,
            fit: BoxFit.cover,
          ),
          SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(fontSize: 10),
          ),
        ],
      ),
    );
  }
}

// 1. 切换状态的选项卡按钮（点击后保持背景色）
class ToggleTabButton extends StatelessWidget {
  final String label;
  final String iconPath;
  final VoidCallback onTap;
  final bool isSelected;
  final Color? selectedColor;
  final Color? unselectedColor;
  final double? iconSize;
  final TextStyle? labelStyle;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;

  const ToggleTabButton({
    Key? key,
    required this.label,
    required this.iconPath,
    required this.onTap,
    required this.isSelected,
    this.selectedColor,
    this.unselectedColor,
    this.iconSize = 30,
    this.labelStyle,
    this.padding,
    this.borderRadius,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = selectedColor ?? Colors.lightGreen;
    final Color inactiveColor = unselectedColor ?? CupertinoColors.inactiveGray;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : Colors.transparent,
          borderRadius: borderRadius ?? BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              iconPath,
              width: iconSize,
              height: iconSize,
              fit: BoxFit.cover,
              color: isSelected ? CupertinoColors.white : inactiveColor,
              colorBlendMode: BlendMode.srcIn,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: labelStyle ?? TextStyle(
                fontSize: 10,
                color: isSelected ? CupertinoColors.white : inactiveColor,
                fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 2. 触摸反馈的按钮（只在触摸时显示背景色）
class TouchFeedbackTabButton extends StatefulWidget {
  final String label;
  final String iconPath;
  final VoidCallback onTap;
  final Color? pressedColor;
  final Color? normalColor;
  final double? iconSize;
  final TextStyle? labelStyle;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;

  const TouchFeedbackTabButton({
    Key? key,
    required this.label,
    required this.iconPath,
    required this.onTap,
    this.pressedColor,
    this.normalColor,
    this.iconSize = 30,
    this.labelStyle,
    this.padding,
    this.borderRadius,
  }) : super(key: key);

  @override
  State<TouchFeedbackTabButton> createState() => _TouchFeedbackTabButtonState();
}

class _TouchFeedbackTabButtonState extends State<TouchFeedbackTabButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = widget.pressedColor ?? Colors.lightGreen;
    final Color normalColor = widget.normalColor ?? CupertinoColors.inactiveGray;

    return GestureDetector(
      onTapDown: (_) {
        setState(() {
          _isPressed = true;
        });
      },
      onTapUp: (_) {
        setState(() {
          _isPressed = false;
        });
        widget.onTap();
      },
      onTapCancel: () {
        setState(() {
          _isPressed = false;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeInOut,
        padding: widget.padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: _isPressed ? primaryColor : Colors.transparent,
          borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              widget.iconPath,
              width: widget.iconSize,
              height: widget.iconSize,
              fit: BoxFit.cover,
              color: _isPressed ? CupertinoColors.white : normalColor,
              colorBlendMode: BlendMode.srcIn,
            ),
            const SizedBox(height: 8),
            Text(
              widget.label,
              style: widget.labelStyle ?? TextStyle(
                fontSize: 10,
                color: _isPressed ? CupertinoColors.white : normalColor,
                fontWeight: _isPressed ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
