import 'package:flutter/material.dart';
import 'routes/home_page.dart';
import 'routes/search_page.dart';
import 'routes/notifications_page.dart';
import 'routes/profile_page.dart';
import 'package:flutter_side_menu/flutter_side_menu.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    HomePage(),
    SearchPage(),
    NotificationsPage(),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primaryColor: Colors.lightGreen, // 设置主要颜色为浅绿色
        scaffoldBackgroundColor: Colors.white, // 背景颜色
        appBarTheme: AppBarTheme(
          color: Colors.lightGreen, // AppBar 的背景颜色为浅绿色
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          iconTheme: IconThemeData(color: Colors.white), // AppBar 图标颜色
        ),
        textTheme: TextTheme(
          bodyText1: TextStyle(color: Colors.black87),
          bodyText2: TextStyle(color: Colors.black54),
          headline6: TextStyle(
            color: Colors.lightGreen, // 标题颜色
            fontWeight: FontWeight.bold,
          ),
        ),
        buttonTheme: ButtonThemeData(
          buttonColor: Colors.lightGreen, // 按钮的背景颜色
          textTheme: ButtonTextTheme.primary, // 按钮的文字颜色
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: Colors.lightGreen, // 浮动按钮背景色
        ),
      ),
      home: Scaffold(
        appBar: AppBar(
          title: Text('Flutter Side Menu Example'),
        ),
        body: Row(
          children: [
            SideMenu(
              backgroundColor: Colors.lightGreen, // 设置侧边栏背景色为浅绿色
              builder: (data) {
                return SideMenuData(
                  items: [
                    SideMenuItemDataTile(
                      isSelected: _currentIndex == 0,
                      title: 'Home',
                      onTap: () {
                        setState(() {
                          _currentIndex = 0;
                        });
                      },
                      icon: const Icon(Icons.home),
                      selectedIcon: const Icon(Icons.home, color: Colors.black),
                      titleStyle: TextStyle(color: Colors.blue),
                      selectedTitleStyle: TextStyle(color: Colors.black),
                    ),
                    SideMenuItemDataTile(
                      isSelected: _currentIndex == 1,
                      title: 'Search',
                      onTap: () {
                        setState(() {
                          _currentIndex = 1;
                        });
                      },
                      icon: const Icon(Icons.search),
                      selectedIcon: const Icon(Icons.search, color: Colors.black),
                      titleStyle: TextStyle(color: Colors.blue),
                      selectedTitleStyle: TextStyle(color: Colors.black),
                    ),
                    SideMenuItemDataTile(
                      isSelected: _currentIndex == 2,
                      title: 'Notifications',
                      onTap: () {
                        setState(() {
                          _currentIndex = 2;
                        });
                      },
                      icon: const Icon(Icons.notifications),
                      selectedIcon: const Icon(Icons.notifications, color: Colors.black),
                      titleStyle: TextStyle(color: Colors.blue),
                      selectedTitleStyle: TextStyle(color: Colors.black),
                    ),
                    SideMenuItemDataTile(
                      isSelected: _currentIndex == 3,
                      title: 'Profile',
                      onTap: () {
                        setState(() {
                          _currentIndex = 3;
                        });
                      },
                      icon: const Icon(Icons.person),
                      selectedIcon: const Icon(Icons.person, color: Colors.black),
                      titleStyle: TextStyle(color: Colors.blue),
                      selectedTitleStyle: TextStyle(color: Colors.black),
                    ),
                  ],
                );
              },
            ),
            Expanded(
              child: _pages[_currentIndex], // Displays the current selected page
            ),
          ],
        ),
      ),
    );
  }
}
