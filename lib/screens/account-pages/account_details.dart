import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AccountDetailsPage extends StatefulWidget {
  const AccountDetailsPage({super.key});

  @override
  State<AccountDetailsPage> createState() => _AccountDetailsPageState();
}

final supabase = Supabase.instance.client;

class _AccountDetailsPageState extends State<AccountDetailsPage> {
  final double horizontalMargin = 32.0;
  final double textMargin = 48.0;
  final user = supabase.auth.currentUser;

  String name =
      supabase.auth.currentUser?.userMetadata?['name'] ??
      ((supabase.auth.currentUser?.userMetadata?['first_name'] ?? '') +
              ' ' +
              (supabase.auth.currentUser?.userMetadata?['last_name'] ?? ''))
          .trim() ??
      "No User";
  String email =
      supabase.auth.currentUser?.userMetadata?['email'] ?? "No User - Email";
  String? photoUrl;

  // Variables to hold name data
  bool isLoading = true;

  @override
  Widget build(BuildContext context) {
    photoUrl = user?.userMetadata?['picture'];
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
                'Account Details',
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

      body: Column(
        children: [
          const SizedBox(height: 50),

          // Profile Picture
          Center(
            child: CircleAvatar(
              radius: 70,
              backgroundColor: Colors.grey[200], // optional
              child: ClipOval(
                child: photoUrl != null
                    ? Image.network(
                        photoUrl!,
                        width: 140, // diameter = radius*2
                        height: 140,
                        fit: BoxFit.cover,
                      )
                    : Image.asset(
                        "assets/png/no-profile.png",
                        width: 140,
                        height: 140,
                        fit: BoxFit.cover,
                      ),
              ),
            ),
          ),
          const SizedBox(height: 30),
          _buildDetailField("Name", name),
          _buildDetailField("Email Address", email, isLast: true),
        ],
      ),
    );
  }

  Widget _buildDetailField(String label, String value, {bool isLast = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalMargin),
          child: const Divider(thickness: 1, color: Color(0xffC5C5C5)),
        ),

        Padding(
          padding: EdgeInsets.symmetric(horizontal: textMargin, vertical: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.normal,
                  color: Color(0xff65000F),
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.normal,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ),
        if (isLast)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalMargin),
            child: const Divider(thickness: 1, color: Color(0xffC5C5C5)),
          ),
      ],
    );
  }
}
