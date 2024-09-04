import 'package:flutter/material.dart';
import 'pages/home_page.dart';
import 'pages/search_page.dart';
import 'pages/notifications_page.dart';
import 'pages/profile_page.dart';
import 'package:flutter_side_menu/flutter_side_menu.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

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
      home: Scaffold(
        appBar: AppBar(
          title: Text('Flutter Side Menu Example'),
        ),
        body: Row(
          children: [
            SideMenu(
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
