import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_page.dart';
import 'search_page.dart';
import 'notifications_page.dart';
import 'profile_page.dart';

class MainPage extends StatefulWidget {
  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0;
  final List<Widget> _pages = [
    HomePage(),
    SearchPage(),
    NotificationsPage(),
    ProfilePage(),
  ];

  Future<void> _logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool("isLoggedIn", false);
    Navigator.pushReplacementNamed(context, '/login'); // 退出后跳转到登录页面
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("App"),
        actions: [
          IconButton(
            icon: Icon(Icons.exit_to_app),
            onPressed: _logout,
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Colors.lightGreen),
              child: Text("App", style: TextStyle(color: Colors.white, fontSize: 24)),
            ),
            _buildDrawerItem(Icons.home, "Home", 0),
            _buildDrawerItem(Icons.search, "Search", 1),
            _buildDrawerItem(Icons.notifications, "Notifications", 2),
            _buildDrawerItem(Icons.person, "Profile", 3),
          ],
        ),
      ),
      body: _pages[_currentIndex],
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
