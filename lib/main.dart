import 'package:flutter/material.dart';

import 'screens/main_menu_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const AnimalTcgApp());
}

class AnimalTcgApp extends StatelessWidget {
  const AnimalTcgApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Animal TCG',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const MainMenuScreen(),
    );
  }
}
