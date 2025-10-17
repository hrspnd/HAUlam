/*
  File: sign_up_page.dart
  Purpose: Provides user registration via email-password and Google Sign-In,
           including form validation, password strength checks, and error handling.
  Developers: Rebusa, Amber Kaia J. [juliankaiaaa]
              Pineda, Mary Alexa Ysabelle V. [hrspnd]
*/

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:haulam/auth-backend/auth_service.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:haulam/screens/signup-login-pages/success_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SignUpPage extends StatefulWidget {
  final VoidCallback showLoginPage;
  const SignUpPage({super.key, required this.showLoginPage});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  // ==================== BACK END ==================== //
  final supabase = Supabase.instance.client;
  final authService = AuthService(); // handles Supabase auth logic

  static const String androidClientId =
      '740089896515-60h4atv846bh2aoqda4hjt9tikf4e5ti.apps.googleusercontent.com';
  static const String webClientId =
      '740089896515-mh79s4bofk11lkdurbp27i91cr68lpbv.apps.googleusercontent.com';

  // --- GOOGLE SIGN-IN HANDLER ---
  Future<void> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        // Web OAuth flow
        await supabase.auth.signInWithOAuth(
          OAuthProvider.google,
          redirectTo:
              'https://oawyynxtwzwwfvomiwcy.supabase.co/auth/v1/callback',
        );
      } else {
        // Mobile (Android/iOS) flow
        final GoogleSignIn signIn = GoogleSignIn.instance;
        await signIn.initialize(
          clientId: androidClientId,
          serverClientId: webClientId,
        );

        final googleUser = await GoogleSignIn.instance.authenticate();
        final googleAuth = await googleUser.authentication;
        final idToken = googleAuth.idToken;

        final response = await supabase.auth.signInWithIdToken(
          provider: OAuthProvider.google,
          idToken: idToken!,
        );

        // Success — redirect to success page
        if (response.user != null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Signed in as ${response.user!.email}')),
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const SuccessPage()),
          );
        }
      }
    } catch (e) {
      // Show error if sign-in fails
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Google Sign-In error: $e')),
      );
    }
  }

  // --- FORM CONTROLLERS ---
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  // Password visibility toggles
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // --- PASSWORD VALIDATION RULES ---
  String? _validatePassword(String pw) {
    if (pw.length < 8) return 'Password must be at least 8 characters long.';
    final missing = <String>[];
    if (!RegExp(r'[a-z]').hasMatch(pw)) missing.add('a lowercase letter');
    if (!RegExp(r'[A-Z]').hasMatch(pw)) missing.add('an uppercase letter');
    if (!RegExp(r'\d').hasMatch(pw)) missing.add('a digit');
    if (missing.isEmpty) return null;

    final last = missing.removeLast();
    final humanList = missing.isEmpty ? last : '${missing.join(', ')}, and $last';
    return 'Password must include $humanList.';
  }

  // --- SIGN-UP HANDLER ---
  Future<void> signUp() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();

    // Password mismatch check
    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Passwords do not match.")),
      );
      return;
    }

    // Custom password rules
    final pwError = _validatePassword(password);
    if (pwError != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(pwError)));
      return;
    }

    try {
      // Attempt sign-up via AuthService
      await authService.signUpWiithEmailPassword(
        email,
        password,
        firstName,
        lastName,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Account created successfully!")),
      );

      // Redirect to success page
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const SuccessPage()),
      );
    } on AuthException catch (e) {
      // --- Supabase-specific errors ---
      String message;
      if (e.message.contains('already registered')) {
        message = "That email is already in use.";
      } else if (e.message.contains('Invalid email')) {
        message = "Please enter a valid email address.";
      } else if (e.message.contains('Password should be at least')) {
        message = "Password is too weak.";
      } else {
        message = "Sign-up failed: ${e.message}";
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (e) {
      // Generic fallback
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Unexpected error: $e")),
      );
    }
  }

  // ================================================== //

  // --- UI HELPERS ---
  InputDecoration _inputDecoration(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
        contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.black54),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xff65000F), width: 2),
        ),
      );

  Widget _buildLabel(String text) => Text(
        text,
        style: const TextStyle(
          color: Color(0xff65000F),
          fontSize: 12,
          fontWeight: FontWeight.normal,
        ),
      );

  // --- UI BUILD ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: EdgeInsets.only(top: 40.0, right: 16.0),
            child: Text(
              'Sign Up',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
        ),
        backgroundColor: const Color(0xff65000F),
        toolbarHeight: 100,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(25)),
        ),
      ),

      // --- MAIN CONTENT ---
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 25),
            const Text(
              "Get Started Here",
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                height: 1.0,
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(left: 2.0),
              child: Text(
                "Create an account.",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 25),

            // --- WHITE CARD CONTAINER ---
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel("First Name"),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _firstNameController,
                      decoration: _inputDecoration("Enter your first name"),
                      validator: (value) =>
                          (value == null || value.isEmpty) ? "First name is required" : null,
                    ),
                    const SizedBox(height: 12),

                    _buildLabel("Last Name"),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _lastNameController,
                      decoration: _inputDecoration("Enter your last name"),
                      validator: (value) =>
                          (value == null || value.isEmpty) ? "Last name is required" : null,
                    ),
                    const SizedBox(height: 12),

                    _buildLabel("Email Address"),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _emailController,
                      decoration: _inputDecoration("Enter your email"),
                      validator: (value) {
                        if (value == null || value.isEmpty) return "Email is required";
                        if (!value.contains("@")) return "Enter a valid email";
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),

                    _buildLabel("Password"),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: !_isPasswordVisible,
                      decoration: _inputDecoration("Enter your password").copyWith(
                        suffixIcon: IconButton(
                          icon: SvgPicture.asset(
                            _isPasswordVisible
                                ? 'assets/icons/unhide-pass-icon.svg'
                                : 'assets/icons/hide-pass-icon.svg',
                            width: 15,
                            height: 15,
                          ),
                          onPressed: () => setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          }),
                        ),
                      ),
                      validator: (value) =>
                          (value == null || value.isEmpty) ? "Password is required" : null,
                    ),
                    const SizedBox(height: 12),

                    _buildLabel("Confirm Password"),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: !_isConfirmPasswordVisible,
                      decoration: _inputDecoration("Confirm your password").copyWith(
                        suffixIcon: IconButton(
                          icon: SvgPicture.asset(
                            _isConfirmPasswordVisible
                                ? 'assets/icons/unhide-pass-icon.svg'
                                : 'assets/icons/hide-pass-icon.svg',
                            width: 15,
                            height: 15,
                          ),
                          onPressed: () => setState(() {
                            _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                          }),
                        ),
                      ),
                      validator: (value) =>
                          (value == null || value.isEmpty) ? "Please confirm your password" : null,
                    ),

                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: signUp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.yellow[700],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          "Register",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 15),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Already have an account? "),
                        GestureDetector(
                          onTap: widget.showLoginPage,
                          child: const Text(
                            "Login here.",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),
                    Row(
                      children: const [
                        Expanded(child: Divider()),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8.0),
                          child: Text("or", style: TextStyle(color: Colors.grey)),
                        ),
                        Expanded(child: Divider()),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // --- GOOGLE SIGN-IN BUTTON ---
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: signInWithGoogle,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                          side: const BorderSide(color: Colors.black26),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Image.asset(
                                'assets/png/google-logo.png',
                                height: 24,
                                width: 24,
                              ),
                            ),
                            const Text(
                              "Sign up with Google",
                              style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.normal,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
