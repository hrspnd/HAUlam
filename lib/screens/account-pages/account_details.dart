/*
  File: account_details.dart
  Purpose: Displays the user's account information, including name, email, and profile picture. 
           Also provides an option to request vendor privileges.
  Developers: Rebusa, Amber Kaia J. [juliankaiaaa]
              Pineda, Mary Alexa Ysabelle V. [hrspnd]
*/

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

  // ==================== BACK END ==================== //

  String name = "No User";
  String email = "No User - Email";
  String? photoUrl;

  bool isLoading = true;

  Future<void> _loadUser() async {
    setState(() => isLoading = true);

    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        setState(() => isLoading = false);
        return;
      }

      final profileRes = await supabase
          .from('Profiles')
          .select('name, email, profile_picture_url')
          .eq('id', user.id)
          .maybeSingle();

      final profile = profileRes;

      setState(() {
        // Check from Profiles table first
        final dbName = (profile?['name'] as String?)?.trim();

        // Fallback to userMetadata if dbName is empty or null
        final metaName =
            user.userMetadata?['name'] ??
            ((user.userMetadata?['first_name'] ?? '') +
                    ' ' +
                    (user.userMetadata?['last_name'] ?? ''))
                .trim();

        // Final value
        name = (dbName != null && dbName.isNotEmpty)
            ? dbName
            : (metaName != null && metaName.isNotEmpty ? metaName : 'User');

        email = (profile?['email'] as String?) ?? user.email ?? 'No Email';
        photoUrl = (profile?['profile_picture_url'] as String?)?.trim();

        isLoading = false;
      });
    } catch (e) {
      debugPrint('Failed to load profile: $e');
      setState(() => isLoading = false);
    }
  }

  void _showVendorRequestDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          insetPadding: const EdgeInsets.symmetric(horizontal: 20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 320, maxHeight: 270),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(26, 26, 26, 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  const Text(
                    "Request Vendor Privilege",
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),

                  // Description
                  const Text(
                    "To request vendor access, please contact the administrators for assistance. "
                    "Our team will help you with the process and confirm your request.\n\n"
                    "📧 Email: haulam2126@gmail.com",
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 12,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 15),

                  const Divider(
                    color: Color(0xFFBDBDBD),
                    thickness: 1,
                    height: 1,
                  ),
                  const SizedBox(height: 10),

                  // Action Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF710E1D),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                        ),
                        child: const Text(
                          "Okay",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ================================================== //

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

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

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                const SizedBox(height: 50),

                // Profile Picture
                Center(
                  child: CircleAvatar(
                    radius: 70,
                    backgroundColor: Colors.grey[200],
                    child: ClipOval(
                      child: photoUrl != null && photoUrl!.isNotEmpty
                          ? Image.network(
                              photoUrl!,
                              width: 140,
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
                const SizedBox(height: 12),

                GestureDetector(
                  onTap: _showVendorRequestDialog,
                  child: const Text(
                    "Request vendor privilege",
                    style: TextStyle(
                      color: Color(0xFF710E1D),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      decorationColor: Color(0xFF710E1D),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
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
