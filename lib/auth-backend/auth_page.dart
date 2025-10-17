/*
  File: auth_page.dart
  Purpose: Toggles screen from login page to sign up page and vice versa.
  Developers: Pineda, Mary Alexa Ysabelle V. [hrspnd]
*/

import 'package:flutter/material.dart';
import 'package:haulam/screens/signup-login-pages/login_page.dart';
import 'package:haulam/screens/signup-login-pages/sign_up_page.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  // Initially start in the login page.
  bool showLoginPage = true;

  void toggleScreens() {
    setState(() {
      showLoginPage = !showLoginPage;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (showLoginPage) {
      return LoginPage(showSignupPage: toggleScreens);
    } else {
      return SignUpPage(showLoginPage: toggleScreens);
    }
  }
}
