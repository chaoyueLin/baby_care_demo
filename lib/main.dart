import 'package:baby_care_demo/routes/login_page.dart';
import 'package:baby_care_demo/routes/main_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/S.dart';

import 'common/db_provider.dart';
import 'models/baby.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  bool isLoggedIn = false;
  List<Baby>? visibleBabies = await DBProvider().getVisiblePersons();
  if (visibleBabies != null) {
    isLoggedIn = true;

  } else {
    isLoggedIn = false;

  }

  runApp(MyApp(isLoggedIn: isLoggedIn));
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
        buttonTheme: const ButtonThemeData(
          buttonColor: Colors.lightGreen,
          textTheme: ButtonTextTheme.primary,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Colors.lightGreen,
        ),
      ),
      locale: const Locale('en'),
      // 默认语言
      localizationsDelegates: S.localizationsDelegates,
      supportedLocales: S.supportedLocales,
      initialRoute: isLoggedIn ? '/main' : '/login',
      routes: {
        '/login': (context) => LoginPage(),
        '/main': (context) => MainPage(),
      },
    );
  }
}
