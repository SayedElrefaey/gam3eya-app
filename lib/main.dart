import 'package:flutter/material.dart';
import 'api_service.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

const _cover = Color(0xFF12332A);
const _cover2 = Color(0xFF0C241D);
const _gold = Color(0xFFC9962C);
const _paper = Color(0xFFFBF7EC);

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
        scaffoldBackgroundColor: _paper,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _cover,
          primary: _cover,
          secondary: _gold,
          surface: _paper,
          brightness: Brightness.light,
        ),
        fontFamily: 'Tahoma',
        appBarTheme: const AppBarTheme(
          backgroundColor: _cover,
          foregroundColor: _gold,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
              color: _gold, fontSize: 19, fontWeight: FontWeight.bold),
          iconTheme: IconThemeData(color: _gold),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Color(0xFFD8CFB0)),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: _cover,
            foregroundColor: _gold,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: _cover,
            side: const BorderSide(color: Color(0xFFD8CFB0)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: _cover,
          foregroundColor: _gold,
        ),
        inputDecorationTheme: const InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: const Color(0xFFF2ECDA),
          labelStyle: const TextStyle(color: _cover, fontWeight: FontWeight.bold),
          side: const BorderSide(color: Color(0xFFD8CFB0)),
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
