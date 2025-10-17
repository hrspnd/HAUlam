/*
  File: auth_gate.dart
  Purpose: Determines whether a user is logged in and routes them to the correct page 
           based on their role (customer or vendor). Vendors without a stall are directed 
           to the Create Stall page.
  Developers: Pineda, Mary Alexa Ysabelle V. [hrspnd]
*/

import 'package:flutter/material.dart';
import 'package:haulam/auth-backend/auth_page.dart';
import 'package:haulam/screens/customer_navbar.dart';
import 'package:haulam/screens/vendor_navbar.dart';
import 'package:haulam/screens/vendor-view-pages/vendor_create_stall.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  Future<Map<String, dynamic>?> _getUserInfo() async {
    final user = supabase.auth.currentUser;
    if (user == null) return null;

    // Get role from Profiles
    final profileResponse = await supabase
        .from('Profiles')
        .select('role')
        .eq('id', user.id)
        .single();

    final role = profileResponse['role'] as String?;

    if (role == 'vendor') {
      // Check if stall exists for this vendor
      final stallResponse = await supabase
          .from('Stalls')
          .select('id') // only need the stall id
          .eq('owner_id', user.id)
          .maybeSingle(); // returns null if no row found

      return {'role': role, 'stallId': stallResponse?['id']};
    }

    return {'role': role};
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: supabase.auth.onAuthStateChange,
      builder: (context, snapshot) {
        // LOADING STATE
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final session = snapshot.hasData ? snapshot.data!.session : null;

        // LOGGED OUT
        if (session == null) {
          return const AuthPage();
        }

        // LOGGED IN -> FETCH ROLE + STALL INFO
        return FutureBuilder<Map<String, dynamic>?>(
          future: _getUserInfo(),
          builder: (context, infoSnapshot) {
            if (infoSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final info = infoSnapshot.data;
            final role = info?['role'];

            if (role == 'vendor') {
              final stallId = info?['stallId'];

              if (stallId != null) {
                // Vendor already has a stall -> redirect to stall page
                return VendorNavBar();
              } else {
                // Vendor has no stall -> redirect to Create Stall page
                return const CreateStallPage();
              }
            } else {
              // Customer flow
              return const CustomerNavBar();
            }
          },
        );
      },
    );
  }
}
