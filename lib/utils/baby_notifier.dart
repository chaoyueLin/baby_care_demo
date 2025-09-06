// baby_notifier.dart
import 'package:flutter/material.dart';
import '../models/baby.dart';

/// Baby选择状态通知器
/// 用于在不同页面间共享当前选择的宝宝信息
class BabyNotifier extends ChangeNotifier {
  Baby? _currentBaby;

  Baby? get currentBaby => _currentBaby;

  /// 设置当前宝宝
  /// 当宝宝发生变化时会通知所有监听者
  void setBaby(Baby? baby) {
    if (_currentBaby?.id != baby?.id) {
      _currentBaby = baby;
      notifyListeners();
    }
  }

  /// 清空当前宝宝
  void clearBaby() {
    if (_currentBaby != null) {
      _currentBaby = null;
      notifyListeners();
    }
  }
}