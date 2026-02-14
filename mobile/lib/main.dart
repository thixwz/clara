import 'package:clara/app_themes.dart';
import 'package:clara/auth_screen.dart';
import 'package:clara/models/chat_model.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:clara/home_page.dart';
import 'package:clara/splash_screen.dart';
import 'package:clara/onboarding1_screen.dart';
import 'package:clara/sign_up_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(ChatAdapter());
  await Hive.openBox<Chat>('chats');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Clara',
      theme: AppThemes.darkTheme,
      darkTheme: AppThemes.darkTheme,
      themeMode: ThemeMode.dark,
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/onboarding1': (context) => const OnboardingScreen(),
        '/auth': (context) => const AuthScreen(),
        '/signup': (context) => const SignUpScreen(),
        '/home': (context) => const HomePage(),
      },
    );
  }
}
