import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:haulam/auth-backend/auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'account_details.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'editaccount.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

final supabase = Supabase.instance.client;

class _AccountPageState extends State<AccountPage> {
  // Get AuthService
  final authService = AuthService();
  bool isLoading = false;

  String firstName = "User";
  String email = "No Email";
  String? photoUrl;

  void _loadUser() {
    final user = supabase.auth.currentUser;
    if (user != null) {
      setState(() {
        firstName =
            user.userMetadata?['name'] ??
            ((supabase.auth.currentUser?.userMetadata?['first_name'] ?? '') +
                    ' ' +
                    (supabase.auth.currentUser?.userMetadata?['last_name'] ??
                        ''))
                .trim() ??
            'User';
        // firstName = user.userMetadata?['name'] ?? 'didnt work';
        email = user.email ?? 'No Email';
        photoUrl = user.userMetadata?['picture'];
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  void logout() async {
    await authService.signOut();
  }

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
        title: const Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: EdgeInsets.only(top: 40.0, right: 16.0),
            child: Text(
              'Account',
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

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),

                  // Profile Card
                  Center(
                    child: Container(
                      width: 300,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.25),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundImage: photoUrl != null
                                ? NetworkImage(photoUrl!)
                                : const AssetImage("assets/png/no-profile.png")
                                      as ImageProvider,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AutoSizeText(
                                  firstName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 20,
                                    color: Colors.black,
                                    height: 1.1,
                                  ),
                                  maxLines: 1,
                                  minFontSize: 15,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Transform.translate(
                                  offset: const Offset(0, -1),
                                  child: AutoSizeText(
                                    email,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.black54,
                                    ),
                                    maxLines: 1,
                                    minFontSize: 8,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const EditAccountPage(),
                                ),
                              );
                            },
                            icon: Image.asset(
                              "assets/png/edit-icon.png",
                              width: 30,
                              height: 30,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 25),

                  // Menu Options
                  const Divider(
                    height: 4,
                    thickness: 1,
                    color: Color(0xffC5C5C5),
                    indent: 24,
                    endIndent: 24,
                  ),
                  NarrowListTile(
                    leading: Image.asset(
                      "assets/png/account-details-icon.png",
                      width: 26,
                      height: 26,
                    ),
                    title: const Text(
                      "Account Details",
                      style: TextStyle(fontSize: 14),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AccountDetailsPage(),
                        ),
                      );
                    },
                  ),
                  const Divider(
                    height: 4,
                    thickness: 1,
                    color: Color(0xffC5C5C5),
                    indent: 24,
                    endIndent: 24,
                  ),
                  NarrowListTile(
                    leading: Image.asset(
                      "assets/png/pass-and-sec-icon.png",
                      width: 26,
                      height: 26,
                    ),
                    title: const Text(
                      "Password & Security",
                      style: TextStyle(fontSize: 14),
                    ),
                    onTap: () {},
                  ),
                  const Divider(
                    height: 4,
                    thickness: 1,
                    color: Color(0xffC5C5C5),
                    indent: 24,
                    endIndent: 24,
                  ),
                  NarrowListTile(
                    leading: Image.asset(
                      "assets/png/delete-account-icon.png",
                      width: 26,
                      height: 26,
                    ),
                    title: const Text(
                      "Delete Account",
                      style: TextStyle(fontSize: 14),
                    ),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          final TextEditingController passwordController =
                              TextEditingController();

                          return Dialog(
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            insetPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                            ),
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(
                                maxWidth: 320,
                                maxHeight: 270,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  26,
                                  26,
                                  26,
                                  18,
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Title
                                    const Text(
                                      "Delete Account",
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 5),

                                    // Description
                                    const Text(
                                      "Deleting your account will permanently remove all your data, including search history and preferences. This action cannot be undone.",
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 12,
                                        height: 1.3,
                                      ),
                                    ),
                                    const SizedBox(height: 10),

                                    // Password Input
                                    Container(
                                      decoration: BoxDecoration(
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(
                                              0.15,
                                            ),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: TextField(
                                        controller: passwordController,
                                        textAlignVertical:
                                            TextAlignVertical.center,
                                        obscureText: true,
                                        decoration: InputDecoration(
                                          hintText: null,
                                          hint: Transform.translate(
                                            offset: const Offset(0, -1),
                                            child: const DefaultTextStyle(
                                              style: TextStyle(
                                                color: Color(0xFF525252),
                                                fontSize: 12,
                                              ),
                                              child: Text(
                                                "Enter current password",
                                              ),
                                            ),
                                          ),
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                vertical: 10,
                                                horizontal: 16,
                                              ),
                                          filled: true,
                                          fillColor: Colors.white,
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                            borderSide: const BorderSide(
                                              color: Colors.black,
                                              width: 1,
                                            ),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                            borderSide: const BorderSide(
                                              color: Color(0xFF710E1D),
                                              width: 1.3,
                                            ),
                                          ),
                                        ),
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
                                        TextButton(
                                          onPressed: () {
                                            Navigator.pop(context);
                                          },
                                          child: const Text(
                                            "Cancel",
                                            style: TextStyle(
                                              color: Color(0xFF747474),
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        ElevatedButton(
                                          onPressed: () {
                                            final password =
                                                passwordController.text;
                                            if (password.isNotEmpty) {
                                              // deleteAccount(password);
                                              Navigator.pop(context);
                                            }
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(
                                              0xFF710E1D,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 20,
                                              vertical: 10,
                                            ),
                                          ),
                                          child: const Text(
                                            "Confirm",
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
                    },
                  ),

                  const Divider(
                    height: 4,
                    thickness: 1,
                    color: Color(0xffC5C5C5),
                    indent: 24,
                    endIndent: 24,
                  ),

                  NarrowListTile(
                    leading: Transform.translate(
                      offset: const Offset(3, 0),
                      child: Image.asset(
                        "assets/png/log-out-icon.png",
                        width: 26,
                        height: 26,
                      ),
                    ),
                    title: const Text(
                      "Log Out",
                      style: TextStyle(fontSize: 14),
                    ),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            contentPadding: const EdgeInsets.fromLTRB(
                              20,
                              20,
                              20,
                              1,
                            ),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const Text(
                                  "Log out of your account?",
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                const Divider(
                                  height: 1,
                                  color: Color(0xFFC5C5C5),
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pop(context);
                                      },
                                      child: const Text(
                                        "Cancel",
                                        style: TextStyle(
                                          color: Color(0x50000000),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    TextButton(
                                      onPressed: () {
                                        logout();
                                        Navigator.pop(context);
                                      },
                                      child: const Text(
                                        "Confirm",
                                        style: TextStyle(
                                          color: Color(0xff710E1D),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                  const Divider(
                    height: 4,
                    thickness: 1,
                    color: Color(0xffC5C5C5),
                    indent: 24,
                    endIndent: 24,
                  ),
                ],
              ),
            ),
    );
  }
}

/// Custom narrower ListTile
class NarrowListTile extends StatelessWidget {
  final Widget leading;
  final Widget title;
  final Widget? trailing;
  final VoidCallback? onTap;

  const NarrowListTile({
    super.key,
    required this.leading,
    required this.title,
    this.trailing = const Icon(Icons.chevron_right, color: Color(0xffBCC2C4)),
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 290,
        child: ListTile(
          leading: leading,
          title: title,
          trailing: trailing,
          onTap: onTap,
        ),
      ),
    );
  }
}
