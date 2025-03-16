import 'package:flutter/material.dart';
import 'dart:async';
import 'routes/home_page.dart';
import 'routes/search_page.dart';
import 'routes/notifications_page.dart';
import 'routes/profile_page.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter_gen/gen_l10n/S.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  int _currentIndex = 0;
  DateTime? _lastPressedAt;

  final List<Widget> _pages = [
    HomePage(),
    SearchPage(),
    NotificationsPage(),
    ProfilePage(),
  ];

  /// 监听返回键
  Future<bool> _onWillPop() async {
    if (_currentIndex != 0) {
      setState(() {
        _currentIndex = 0;
      });
      return false;
    } else {
      final DateTime now = DateTime.now();
      if (_lastPressedAt == null ||
          now.difference(_lastPressedAt!) > Duration(seconds: 2)) {
        _lastPressedAt = now;

        Fluttertoast.showToast(
          msg: S.of(context)?.exitPrompt ?? "Press again to exit",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.black,
          textColor: Colors.white,
          fontSize: 16.0,
        );

        return false;
      }
      return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primaryColor: Colors.lightGreen,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: AppBarTheme(
          color: Colors.lightGreen,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          iconTheme: IconThemeData(color: Colors.white),
        ),
        textTheme: TextTheme(
          bodyLarge: TextStyle(color: Colors.black87),
          bodyMedium: TextStyle(color: Colors.black54),
          bodySmall: TextStyle(
            color: Colors.lightGreen,
            fontWeight: FontWeight.bold,
          ),
        ),
        buttonTheme: ButtonThemeData(
          buttonColor: Colors.lightGreen,
          textTheme: ButtonTextTheme.primary,
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: Colors.lightGreen,
        ),
      ),
      locale: const Locale('en'),
      // 默认语言
      localizationsDelegates: S.localizationsDelegates,
      supportedLocales: S.supportedLocales,
      home: Builder(
        builder: (context) => WillPopScope(
          onWillPop: _onWillPop,
          child: Scaffold(
            appBar: AppBar(
              title: Text(S.of(context)?.appTitle ?? "App"),
            ),
            drawer: _buildDrawer(context),
            body: _pages[_currentIndex],
          ),
        ),
      ),
    );
  }

  /// **封装 Drawer 以避免 Navigator 相关错误**
  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.lightGreen,
            ),
            child: Text(
              S.of(context)?.appTitle ?? "App",
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
              ),
            ),
          ),
          _buildDrawerItem(
            icon: Icons.home,
            text: S.of(context)?.home ?? "Home",
            index: 0,
            context: context,
          ),
          _buildDrawerItem(
            icon: Icons.search,
            text: S.of(context)?.search ?? "Search",
            index: 1,
            context: context,
          ),
          _buildDrawerItem(
            icon: Icons.notifications,
            text: S.of(context)?.notifications ?? "Notifications",
            index: 2,
            context: context,
          ),
          _buildDrawerItem(
            icon: Icons.person,
            text: S.of(context)?.profile ?? "Profile",
            index: 3,
            context: context,
          ),
        ],
      ),
    );
  }

  /// **封装 Drawer Item**
  Widget _buildDrawerItem({
    required IconData icon,
    required String text,
    required int index,
    required BuildContext context,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(text),
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
        Navigator.of(context, rootNavigator: true).pop(); // 关闭 Drawer
      },
    );
  }
}
