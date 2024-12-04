import 'package:flutter/material.dart';
import 'dart:async';
import 'routes/home_page.dart';
import 'routes/search_page.dart';
import 'routes/notifications_page.dart';
import 'routes/profile_page.dart';
import 'package:flutter_side_menu/flutter_side_menu.dart';
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
          msg: S.of(context)?.exitPrompt ?? "",
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
          bodyText1: TextStyle(color: Colors.black87),
          bodyText2: TextStyle(color: Colors.black54),
          headline6: TextStyle(
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
      locale: const Locale('zh'),
      // 默认语言
      localizationsDelegates: S.localizationsDelegates,
      supportedLocales: S.supportedLocales,
      home: WillPopScope(
        onWillPop: _onWillPop,
        child: Scaffold(
          appBar: AppBar(
            title: Text(S.of(context)?.appTitle ?? ""),
          ),
          body: Row(
            children: [
              SideMenu(
                backgroundColor: Colors.lightGreen,
                builder: (data) {
                  return SideMenuData(
                    items: [
                      SideMenuItemDataTile(
                        isSelected: _currentIndex == 0,
                        title: S.of(context)?.home ?? "",
                        onTap: () {
                          setState(() {
                            _currentIndex = 0;
                          });
                        },
                        icon: const Icon(Icons.home),
                        selectedIcon:
                            const Icon(Icons.home, color: Colors.black),
                        titleStyle: TextStyle(color: Colors.blue),
                        selectedTitleStyle: TextStyle(color: Colors.black),
                      ),
                      SideMenuItemDataTile(
                        isSelected: _currentIndex == 1,
                        title: S.of(context)?.search ?? "",
                        onTap: () {
                          setState(() {
                            _currentIndex = 1;
                          });
                        },
                        icon: const Icon(Icons.search),
                        selectedIcon:
                            const Icon(Icons.search, color: Colors.black),
                        titleStyle: TextStyle(color: Colors.blue),
                        selectedTitleStyle: TextStyle(color: Colors.black),
                      ),
                      SideMenuItemDataTile(
                        isSelected: _currentIndex == 2,
                        title: S.of(context)?.notifications ?? "",
                        onTap: () {
                          setState(() {
                            _currentIndex = 2;
                          });
                        },
                        icon: const Icon(Icons.notifications),
                        selectedIcon: const Icon(Icons.notifications,
                            color: Colors.black),
                        titleStyle: TextStyle(color: Colors.blue),
                        selectedTitleStyle: TextStyle(color: Colors.black),
                      ),
                      SideMenuItemDataTile(
                        isSelected: _currentIndex == 3,
                        title: S.of(context)?.profile ?? "",
                        onTap: () {
                          setState(() {
                            _currentIndex = 3;
                          });
                        },
                        icon: const Icon(Icons.person),
                        selectedIcon:
                            const Icon(Icons.person, color: Colors.black),
                        titleStyle: TextStyle(color: Colors.blue),
                        selectedTitleStyle: TextStyle(color: Colors.black),
                      ),
                    ],
                  );
                },
              ),
              Expanded(
                child: _pages[_currentIndex],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
