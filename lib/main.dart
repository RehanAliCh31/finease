import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'pages/auth/login_page.dart';
import 'pages/main_scaffold.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FinEase',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        useMaterial3: true,
        fontFamily: 'Inter',
        scaffoldBackgroundColor: const Color(0xFFF8F9FF),
        colorScheme: const ColorScheme(
          brightness: Brightness.light,
          primary: Color(0xFF2E3192),
          onPrimary: Colors.white,
          primaryContainer: Color(0xFF2E3192),
          onPrimaryContainer: Color(0xFF9DA1FF),
          secondary: Color(0xFF00F2EA),
          onSecondary: Colors.black,
          secondaryContainer: Color(0xFF29FCF3),
          onSecondaryContainer: Color(0xFF00716D),
          error: Color(0xFFBA1A1A),
          onError: Colors.white,
          surface: Colors.white,
          onSurface: Color(0xFF0B1C30),
          surfaceContainerHighest: Color(0xFFD3E4FE),
          onSurfaceVariant: Color(0xFF464652),
          outline: Color(0xFF777683),
        ),
        textTheme: const TextTheme(
          displayLarge: TextStyle(fontFamily: 'Plus Jakarta Sans', fontWeight: FontWeight.w700),
          displayMedium: TextStyle(fontFamily: 'Plus Jakarta Sans', fontWeight: FontWeight.w700),
          displaySmall: TextStyle(fontFamily: 'Plus Jakarta Sans', fontWeight: FontWeight.w700),
          headlineLarge: TextStyle(fontFamily: 'Plus Jakarta Sans', fontWeight: FontWeight.w600),
          headlineMedium: TextStyle(fontFamily: 'Plus Jakarta Sans', fontWeight: FontWeight.w600),
          headlineSmall: TextStyle(fontFamily: 'Plus Jakarta Sans', fontWeight: FontWeight.w600),
          titleLarge: TextStyle(fontFamily: 'Plus Jakarta Sans', fontWeight: FontWeight.w600),
          titleMedium: TextStyle(fontFamily: 'Plus Jakarta Sans', fontWeight: FontWeight.w600),
          titleSmall: TextStyle(fontFamily: 'Plus Jakarta Sans', fontWeight: FontWeight.w600),
          bodyLarge: TextStyle(fontFamily: 'Inter'),
          bodyMedium: TextStyle(fontFamily: 'Inter'),
          bodySmall: TextStyle(fontFamily: 'Inter'),
          labelLarge: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w500),
          labelMedium: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w500),
          labelSmall: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w500),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF8F9FF),
          foregroundColor: Color(0xFF0B1C30),
          elevation: 0,
        ),
        cardTheme: const CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
            side: BorderSide(color: Color(0xFFE2E8F0), width: 1),
          ),
          margin: EdgeInsets.symmetric(vertical: 8),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2E3192),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: Colors.white,
          indicatorColor: const Color(0xFF2E3192).withOpacity(0.1),
          labelTextStyle: WidgetStateProperty.all(
            const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF0B1C30)),
          ),
        ),
      ),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    
    if (authService.user == null) {
      return const LoginPage();
    } else {
      return const MainScaffold();
    }
  }
}
