import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bap_pulse/auth/auth_service.dart';
import 'package:bap_pulse/auth/presentation/login_screen.dart';
import 'package:bap_pulse/home/presentation/home_screen.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    const colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xFF28F39B),
      onPrimary: Color(0xFF052216),
      secondary: Color(0xFF1AD07B),
      onSecondary: Color(0xFF052216),
      tertiary: Color(0xFF7DEFC1),
      onTertiary: Color(0xFF052216),
      error: Color(0xFFFF6B6B),
      onError: Color(0xFF2A0000),
      surface: Color(0xFF0E1915),
      onSurface: Color(0xFFE7F6EE),
      surfaceVariant: Color(0xFF1B2A22),
      onSurfaceVariant: Color(0xFFB7C8BE),
      outline: Color(0xFF2D4339),
      shadow: Colors.black,
      inverseSurface: Color(0xFFE7F6EE),
      onInverseSurface: Color(0xFF0E1915),
      inversePrimary: Color(0xFF0A2A1B),
      scrim: Colors.black,
    );

    return MaterialApp(
      title: 'BAP Pulse',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: colorScheme,
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF0E1915),
        textTheme: GoogleFonts.spaceGroteskTextTheme().apply(
          bodyColor: colorScheme.onSurface,
          displayColor: colorScheme.onSurface,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFFB7C8BE)),
        cardTheme: CardThemeData(
          color: const Color(0xFF18261F),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color(0xFF0F1D18),
          selectedItemColor: Color(0xFF28F39B),
          unselectedItemColor: Color(0xFF6C8177),
          type: BottomNavigationBarType.fixed,
          showUnselectedLabels: true,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF15231C),
          hintStyle: const TextStyle(color: Color(0xFF7F9289)),
          labelStyle: const TextStyle(color: Color(0xFF9FB3A8)),
          prefixIconColor: const Color(0xFF9FB3A8),
          suffixIconColor: const Color(0xFF9FB3A8),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFF24372F)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFF24372F)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFF28F39B), width: 1.5),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF28F39B),
            foregroundColor: const Color(0xFF072215),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFFE7F6EE),
            side: const BorderSide(color: Color(0xFF24372F)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
        snackBarTheme: const SnackBarThemeData(
          backgroundColor: Color(0xFF203229),
          contentTextStyle: TextStyle(color: Color(0xFFE7F6EE)),
        ),
      ),
      home: StreamBuilder(
        stream: AuthService().authStateChanges,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasData && snapshot.data != null) {
            return const HomeScreen();
          }
          return const LoginScreen();
        },
      ),
    );
  }
}
