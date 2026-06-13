import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'HomePage.dart';
import 'LoginPage.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const MyApp());
}


class AppColors {
  static const bg       = Color(0xFFF7F5F2);
  static const surface  = Color(0xFFFFFFFF);
  static const surface2 = Color(0xFFF0EDE8);

  static const red      = Color(0xFFD72638);
  static const redDark  = Color(0xFFB01E2D);
  static const redLight = Color(0xFFFFF0F1);
  static const redGlow  = Color(0x22D72638);

  static const ink       = Color(0xFF1A1310);
  static const inkMid    = Color(0xFF5C524A);
  static const inkLight  = Color(0xFFA8998E);

  static const border    = Color(0xFFE5DED6);
  static const borderFocus = Color(0xFFD72638);


  static const white     = Color(0xFFFFFFFF);
  static const white70   = Color(0xB3FFFFFF);
  static const white38   = Color(0x61FFFFFF);
  static const white12   = Color(0x1FFFFFFF);
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Galler Nas',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.bg,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.red,
          surface: AppColors.surface,
        ),
        fontFamily: 'SF Pro Display',
      ),
      home: const CheckLogin(),
    );
  }
}

class CheckLogin extends StatefulWidget {
  const CheckLogin({super.key});

  @override
  State<CheckLogin> createState() => _CheckLoginState();
}

class _CheckLoginState extends State<CheckLogin> {
  @override
  void initState() {
    super.initState();
    _resolveRoute();
  }

  Future<void> _resolveRoute() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString("user_id");

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => userId != null
            ? HomePage(userId: userId)
            : const LoginPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.bg,
      body: Center(
        child: CircularProgressIndicator(
          color: AppColors.red,
          strokeWidth: 2,
        ),
      ),
    );
  }
}
