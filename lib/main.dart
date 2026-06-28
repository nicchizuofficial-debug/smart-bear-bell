import 'package:flutter/material.dart';
import 'main_screen.dart';

void main() {
  runApp(const SmartBearBellApp());
}

class SmartBearBellApp extends StatelessWidget {
  const SmartBearBellApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Bear Bell',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0D0D0D),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFFFD700),
          secondary: Color(0xFFCC0000),
        ),
      ),
      home: const MainScreen(),
    );
  }
}
