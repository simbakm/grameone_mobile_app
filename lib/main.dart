import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'application/app_provider.dart';
import 'presentation/screens/splash_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const GrameOneApp());
}

class GrameOneApp extends StatelessWidget {
  const GrameOneApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppProvider(),
      child: Consumer<AppProvider>(
        builder: (context, provider, child) {
          final isDarkMode = provider.settings?.darkMode ?? false;
          return MaterialApp(
            title: 'GrameOne Homework Pack',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}
