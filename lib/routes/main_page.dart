import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'care_page.dart';
import 'data_page.dart';
import 'setting_page.dart';
import 'grow_page.dart';
import 'package:flutter_gen/gen_l10n/S.dart';

class MainPage extends StatefulWidget {
  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0;
  DateTime? _lastPressedAt; // 记录上次按返回键的时间

  final List<Widget> _pages = [
    CarePage(),
    DataPage(),
    GrowPage(),
    SettingsPage(),
  ];


  Future<bool> _onWillPop() async {
    if (_currentIndex != 0) {
      setState(() => _currentIndex = 0);
      return false; // 不退出，先回到首页
    } else {
      final DateTime now = DateTime.now();
      if (_lastPressedAt == null || now.difference(_lastPressedAt!) > Duration(seconds: 2)) {
        _lastPressedAt = now;

        Fluttertoast.showToast(
          msg: S.of(context)?.exitPrompt ?? "Press again to exit",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.black54,
          textColor: Colors.white,
          fontSize: 16.0,
        );

        return false; // 第一次按返回键，不退出
      }
      return true; // 两秒内再次按返回键，退出应用
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop, // 监听返回键
      child: Scaffold(
        appBar: AppBar(
          title: Text("App")
        ),
        drawer: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              const DrawerHeader(
                decoration: BoxDecoration(color: Colors.lightGreen),
                child: Text("App", style: TextStyle(color: Colors.white, fontSize: 24)),
              ),
              _buildDrawerItem(Icons.home, "Care", 0),
              _buildDrawerItem(Icons.search, "Data", 1),
              _buildDrawerItem(Icons.person, "Grow", 2),
              _buildDrawerItem(Icons.notifications, "Setting", 3),
            ],
          ),
        ),
        body: _pages[_currentIndex],
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String text, int index) {
    return ListTile(
      leading: Icon(icon),
      title: Text(text),
      onTap: () {
        setState(() => _currentIndex = index);
        Navigator.pop(context);
      },
    );
  }
}
