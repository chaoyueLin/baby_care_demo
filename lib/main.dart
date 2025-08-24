import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/S.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:provider/provider.dart';

import 'common/db_provider.dart';
import 'models/baby.dart';
import 'routes/login_page.dart';
import 'routes/main_page.dart';
import 'utils/theme_mode_notifier.dart';   // 新增

Future<void> main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // 异步初始化
  final isLoggedIn = await _checkLoginStatus();
  final savedThemeMode = await ThemeModeNotifier.loadSavedMode();

  FlutterNativeSplash.remove();

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeModeNotifier(savedThemeMode),
      child: MyApp(isLoggedIn: isLoggedIn),
    ),
  );
}

/// 检查是否已登录
Future<bool> _checkLoginStatus() async {
  try {
    List<Baby>? visibleBabies = await DBProvider().getVisiblePersons();
    return visibleBabies != null && visibleBabies.isNotEmpty;
  } catch (_) {
    return false;
  }
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;

  const MyApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    final themeMode = context.watch<ThemeModeNotifier>().themeMode;

    // 你的浅色主题（保留原有样式）
    final lightTheme = ThemeData(
      brightness: Brightness.light,
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
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.lightGreen),
      useMaterial3: true,
    );

    // 新增：暗色主题（与浅色主题风格对齐）
    final darkTheme = ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF121212),
      appBarTheme: const AppBarTheme(
        color: Color(0xFF1F1F1F),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: Colors.white),
        bodyMedium: TextStyle(color: Colors.white70),
        bodySmall: TextStyle(
          color: Colors.lightGreenAccent,
          fontWeight: FontWeight.bold,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: Colors.lightGreen,
        foregroundColor: Colors.black,
      ),
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.lightGreen,
        brightness: Brightness.dark,
      ),
      useMaterial3: true,
    );

    return MaterialApp(
      title: 'My App',
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: themeMode, // 关键：跟随状态切换
      // 默认语言
      localizationsDelegates: S.localizationsDelegates,
      supportedLocales: S.supportedLocales,
      home: isLoggedIn ?  MainPage() :  LoginPage(),
      routes: {
        '/login': (context) =>  LoginPage(),
        '/main': (context) =>  MainPage(),
      },
    );
  }
}
