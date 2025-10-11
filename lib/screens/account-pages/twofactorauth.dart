import 'package:flutter/material.dart';

class TwoFactorAuthenticationPage extends StatelessWidget {
  const TwoFactorAuthenticationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Padding(
          padding: const EdgeInsets.only(top: 40.0, right: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              const Text(
                'Password & Security',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
        backgroundColor: const Color(0xff65000F),
        toolbarHeight: 100,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0), 
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Space above title
            const SizedBox(height: 30),

            // Title
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.0),
              child: Text(
                "Two-Factor Authentication",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                textAlign: TextAlign.left,
              ),
            ),
            const SizedBox(height: 10),

            // Description
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.0),
              child: Text(
                "Two-Factor Authentication (2FA) strengthens your account security "
                "by requiring two steps before access is granted. Even if someone "
                "obtains your password, your account remains protected by a second "
                "verification method.\n\n"
                "When you sign in, you will first enter your password, then a unique "
                "code will be sent to your registered device or email. By combining "
                "something you know (your password) with something you have (your "
                "device or email), 2FA provides stronger protection against "
                "unauthorized access and keeps your personal information safe.",
                style: TextStyle(
                  fontSize: 14,
                  height: 1.3,
                  color: Colors.black,
                ),
                textAlign: TextAlign.justify,
              ),
            ),
            const SizedBox(height: 30),

            // Button
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 12.0),
              width: double.infinity,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 15),
                  side: const BorderSide(color: Colors.black),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  backgroundColor: Colors.white,
                ),
                onPressed: () {
                  // Add your change password logic here
                },
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Change Password",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios, size: 18, color: Color(0xFFBCC2C4)),
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
