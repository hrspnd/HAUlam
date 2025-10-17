/*
  File: main.dart
  Purpose: Initializes the HAUlam Flutter application, sets up Supabase
           for backend services, enforces portrait orientation, and
           configures global app theming and styles.
  Developers: Magat, Maria Josephine M. [jsphnmgt]
              Rebusa, Amber Kaia J. [juliankaiaaa]
              Pineda, Mary Alexa Ysabelle V. [hrspnd]
*/

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:haulam/auth-backend/deep_link_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:haulam/screens/signup-login-pages/splash_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: "https://oawyynxtwzwwfvomiwcy.supabase.co",
    anonKey:
        "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9hd3l5bnh0d3p3d2Z2b21pd2N5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTk1NDYyNDksImV4cCI6MjA3NTEyMjI0OX0.qyBc7-vbxYhgyNoRyGJ8PMIP_k6bHsrrblZxINGqxpA",
  );

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]).then((_) {
    runApp(
    DeepLinkHandler(
      child: MyApp(),
    ),
  );
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // ===== Global Font =====
        fontFamily: 'Onest',
        // =======================
        // ===== Navbar Hover Color =====
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        hoverColor: Colors.transparent,
        // ==============================
        // ===== Circle Progress Color =====
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: Colors.grey,
        ),
        // =================================
        textSelectionTheme: const TextSelectionThemeData(
          cursorColor: Colors.black,
          selectionColor: Color(0x30710E1D), 
          selectionHandleColor: Color(0xff710E1D), 
        ),
        scaffoldBackgroundColor: Colors.white,

        // ===== GLOBAL OUTLINE / FOCUS COLOR =====
        inputDecorationTheme: InputDecorationTheme(
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xff65000F), width: 2),
          ),
        ),

        // ===== SNACKBAR =====
        snackBarTheme: SnackBarThemeData(
      backgroundColor: const Color(0xffE2E2E2),
      contentTextStyle: const TextStyle(
        color: Colors.black,
        fontSize: 14,
      ),
      ), ),

      home: const SplashPage(),
    );
  }
}
