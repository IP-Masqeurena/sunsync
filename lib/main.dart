// lib/main.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'services/theme_notifier.dart';
import 'supabase_constant.dart';
import 'widgets/bottom_nav.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeNotifier(),
      child: const AlumniApp(),
    ),
  );
}

class AlumniApp extends StatelessWidget {
  const AlumniApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeNotifier>(
      builder: (ctx, theme, _) {
        final seed = theme.primaryColor;
        return MaterialApp(
          title: 'Alumni App',
          themeMode: theme.themeMode,
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(seedColor: seed).copyWith(
              background: Colors.white,
            ),
            bottomNavigationBarTheme: BottomNavigationBarThemeData(
              backgroundColor: Colors.white,
              selectedItemColor: seed,
              unselectedItemColor: seed.withOpacity(0.4),
            ),
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: seed,
              brightness: Brightness.dark,
            ).copyWith(
              background: Colors.black,
              surface: Colors.grey[900],
            ),
            scaffoldBackgroundColor: Colors.black,  // force Scaffold’s bg to pure black
            canvasColor: Colors.black,              // e.g. bottom sheets, drawers
            dialogBackgroundColor: Colors.black,    // dialogs
            bottomNavigationBarTheme: BottomNavigationBarThemeData(
              backgroundColor: Colors.black,
              selectedItemColor: seed,
              unselectedItemColor: seed.withOpacity(0.4),
            ),
          ),
          home: const BottomNav(),
        );
      },
    );
  }
}
