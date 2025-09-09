

import 'package:flutter/material.dart';

class DialogUtil {
  /// 核心封装：带统一样式的 AlertDialog
  static Future<T?> showStyledDialog<T>({
    required BuildContext context,
    required String title,
    required Widget content,
    List<Widget>? actions,
    EdgeInsetsGeometry? contentPadding,
  }) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return showDialog<T>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          titleTextStyle: tt.titleMedium?.copyWith(color: Colors.white),
          contentTextStyle: tt.bodyMedium?.copyWith(color: cs.onSurface),
          backgroundColor: cs.surface,
          title: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12.0),
                topRight: Radius.circular(12.0),
              ),
            ),
            child: Text(title, style: const TextStyle(color: Colors.white)),
          ),
          titlePadding: EdgeInsets.zero,
          contentPadding: contentPadding ?? const EdgeInsets.all(16.0),
          content: content,
          actions: actions,
        );
      },
    );
  }

  /// 二次封装：确认对话框（自动生成按钮）
  static Future<bool?> showConfirmDialog(
      BuildContext context, {
        required String title,
        required String content,
        String cancelText = "取消",
        String confirmText = "确定",
      }) {
    final cs = Theme.of(context).colorScheme;

    return showStyledDialog<bool>(
      context: context,
      title: title,
      content: Text(content),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(cancelText, style: TextStyle(color: cs.primary)),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(confirmText, style: TextStyle(color: cs.primary)),
        ),
      ],
    );
  }
}
