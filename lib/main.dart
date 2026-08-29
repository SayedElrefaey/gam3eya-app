import 'package:flutter/material.dart';
import 'api_service.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiService.init();
  runApp(const Gam3eyaApp());
}

class Gam3eyaApp extends StatelessWidget {
  const Gam3eyaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'دفتر الجمعيات والحسابات',
      debugShowCheckedModeBanner: false,
      locale: const Locale('ar'),
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF12332A),
        fontFamily: 'Tahoma',
        navigationBarTheme: const NavigationBarThemeData(
          indicatorColor: Color(0xFFE6B95C),
        ),
      ),
      builder: (context, child) => Directionality(
        textDirection: TextDirection.rtl,
        child: child!,
      ),
      home: ApiService.isLoggedIn ? const HomeScreen() : const LoginScreen(),
    );
  }
}
