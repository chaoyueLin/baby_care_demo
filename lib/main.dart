import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/S.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

import 'common/db_provider.dart';
import 'models/baby.dart';
import 'routes/login_page.dart';
import 'routes/main_page.dart';

Future<void> main() async {
  // 保留 Splash 屏幕
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // 异步初始化
  bool isLoggedIn = await _checkLoginStatus();

  // 移除 Splash 屏幕
  FlutterNativeSplash.remove();

  runApp(MyApp(isLoggedIn: isLoggedIn));
}

/// 检查是否已登录
Future<bool> _checkLoginStatus() async {
  List<Baby>? visibleBabies = await DBProvider().getVisiblePersons();
  return visibleBabies != null && visibleBabies.isNotEmpty;
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;

  const MyApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My App',
      theme: ThemeData(
        primaryColor: Colors.lightGreen,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          color: Colors.lightGreen,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          iconTheme: IconThemeData(color: Colors.white),
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.black87),
          bodyMedium: TextStyle(color: Colors.black54),
          bodySmall: TextStyle(
            color: Colors.lightGreen,
            fontWeight: FontWeight.bold,
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Colors.lightGreen,
        ),
      ),
      // 默认语言
      localizationsDelegates: S.localizationsDelegates,
      supportedLocales: S.supportedLocales,
      initialRoute: isLoggedIn ? '/main' : '/login',
      routes: {
        '/login': (context) =>  LoginPage(),
        '/main': (context) =>  MainPage(),
      },
    );
  }
}