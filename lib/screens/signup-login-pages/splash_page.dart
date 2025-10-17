/*
  File: splash_page.dart
  Purpose: Displays the splash screen of the HAULAM app, featuring 
           a fading logo animation before navigating to the AuthGate.
  Developers: Magat, Maria Josephine M. [jsphnmgt]
*/

import 'package:flutter/material.dart';
import 'package:haulam/auth-backend/auth_gate.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  double _opacity = 1.0;

  @override
  void initState() {
    super.initState();

    // Start fading after 1.5 seconds
    Future.delayed(const Duration(milliseconds: 1500), () {
      setState(() {
        _opacity = 0.0;
      });
    });

    // Navigate after 1.7 seconds
    Future.delayed(const Duration(milliseconds: 1900), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => AuthGate()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const SizedBox(height: 60), // top spacing
            Center(
              child: AnimatedOpacity(
                opacity: _opacity,
                duration: const Duration(milliseconds: 800), // smooth fade
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      'assets/png/haulam-logo.png',
                      width: 175,
                      height: 175,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 25),
                    const Text(
                      'HAUlam',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 32,
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Saan tayo kakain?',
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.black87,
                        height: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 50.0),
              child: AnimatedOpacity(
                opacity: _opacity,
                duration: const Duration(milliseconds: 800),
                child: const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xff65000F)),
                  strokeWidth: 3,
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        color: const Color(0xff65000F),
        height: 40,
      ),
    );
  }
}
