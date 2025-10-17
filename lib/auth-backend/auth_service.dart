/*
  File: auth_service.dart
  Purpose: Handles all authentication-related operations such as signing in, signing up, 
           signing out, and retrieving user information through Supabase.
  Developers: Pineda, Mary Alexa Ysabelle V. [hrspnd]
*/


import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Sign in with email and password
  Future<AuthResponse> signInWiithEmailPassword(
    String email,
    String password,
  ) async {
    return await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  // Sign up with email and password
  Future<AuthResponse> signUpWiithEmailPassword(
    String email,
    String password,
    String first_name,
    String last_name,
  ) async {
    return await _supabase.auth.signUp(
      email: email,
      password: password,
      data: {
        'first_name': first_name,
        'last_name': last_name,
      },);
  }

  // Sign out
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  // Get user email
  String? getCurrentUserEmail() {
    final session = _supabase.auth.currentSession;
    final user = session?.user;
    return user?.email;
  }
}
