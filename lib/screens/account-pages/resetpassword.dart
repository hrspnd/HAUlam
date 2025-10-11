import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  bool _isNewPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  String? errorMessage;

  @override
  void initState() {
    super.initState();

    newPasswordController.addListener(() {
      setState(() {});
    });

    confirmPasswordController.addListener(() {
      setState(() {});
    });
  }

  bool get passwordsMatch {
    return newPasswordController.text.isNotEmpty &&
        newPasswordController.text == confirmPasswordController.text;
  }

  Widget _passwordChecklist(String password) {
    bool hasMinLength = password.length >= 8;
    bool hasNumber = password.contains(RegExp(r'[0-9]'));
    bool hasSpecialChar = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
    bool hasUpperLower =
        password.contains(RegExp(r'[A-Z]')) &&
        password.contains(RegExp(r'[a-z]'));

    return DefaultTextStyle(
      style: const TextStyle(fontSize: 14, color: Colors.black),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                hasMinLength ? Icons.check_circle : Icons.cancel,
                color: hasMinLength ? Colors.green : const Color(0xff65000F),
                size: 18,
              ),
              const SizedBox(width: 8),
              const Text("At least 8 characters"),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                hasNumber ? Icons.check_circle : Icons.cancel,
                color: hasNumber ? Colors.green : const Color(0xff65000F),
                size: 18,
              ),
              const SizedBox(width: 8),
              const Text("Contains at least one number"),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                hasSpecialChar ? Icons.check_circle : Icons.cancel,
                color: hasSpecialChar ? Colors.green : const Color(0xff65000F),
                size: 18,
              ),
              const SizedBox(width: 8),
              const Text("Contains a special character"),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                hasUpperLower ? Icons.check_circle : Icons.cancel,
                color: hasUpperLower ? Colors.green : const Color(0xff65000F),
                size: 18,
              ),
              const SizedBox(width: 8),
              const Text("Contains uppercase and lowercase letters"),
            ],
          ),
        ],
      ),
    );
  }

  void _changePassword() {
    setState(() {
      if (newPasswordController.text.isEmpty ||
          confirmPasswordController.text.isEmpty) {
        errorMessage = "Please fill out both fields.";
      } else if (!passwordsMatch) {
        errorMessage = "Passwords do not match.";
      } else {
        errorMessage = null;

        showDialog(
          context: context,
          barrierDismissible: true,
          builder: (context) {
            return Dialog(
              backgroundColor:
                  Colors.transparent, 
              child: Container(
                padding: const EdgeInsets.all(20.0),
                decoration: BoxDecoration(
                  color: Colors.white, 
                  borderRadius: BorderRadius.circular(30), 
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      child: const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 70,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "Password Updated!",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      "Your password has been changed successfully. Use your new password to log in.",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            );
          },
        ).then((_) {
          Navigator.of(context).pop();
        });
      }
    });
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 36.0, vertical: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 30),
            const Center(
              child: Text(
                "Reset Password",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // New password field
            TextField(
              controller: newPasswordController,
              obscureText: !_isNewPasswordVisible,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                suffixIcon: IconButton(
                  onPressed: () {
                    setState(() {
                      _isNewPasswordVisible = !_isNewPasswordVisible;
                    });
                  },
                  icon: SvgPicture.asset(
                    _isNewPasswordVisible
                        ? 'assets/icons/unhide-pass-icon.svg'
                        : 'assets/icons/hide-pass-icon.svg',
                    width: 18,
                    height: 18,
                  ),
                ),
                hintText: null,
                hint: Transform.translate(
                  offset: const Offset(0, -1),
                  child: const DefaultTextStyle(
                    style: TextStyle(color: Color(0xFF525252), fontSize: 12),
                    child: Text("Enter new password"),
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 16,
                ),
                filled: true,
                fillColor: Colors.white,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Colors.black, width: 1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                    color: Color(0xFF710E1D),
                    width: 1.3,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 15),

            // Confirm password field
            TextField(
              controller: confirmPasswordController,
              obscureText: !_isConfirmPasswordVisible,
              decoration: InputDecoration(
                suffixIcon: IconButton(
                  onPressed: () {
                    setState(() {
                      _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                    });
                  },
                  icon: SvgPicture.asset(
                    _isConfirmPasswordVisible
                        ? 'assets/icons/unhide-pass-icon.svg'
                        : 'assets/icons/hide-pass-icon.svg',
                    width: 18,
                    height: 18,
                  ),
                ),
                hintText: null,
                hint: Transform.translate(
                  offset: const Offset(0, -1),
                  child: const DefaultTextStyle(
                    style: TextStyle(color: Color(0xFF525252), fontSize: 12),
                    child: Text("Confirm new password"),
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 16,
                ),
                filled: true,
                fillColor: Colors.white,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Colors.black, width: 1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                    color: Color(0xFF710E1D),
                    width: 1.3,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 10),

            if (errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
                child: Text(
                  errorMessage!,
                  style: const TextStyle(
                    color: Color(0xFF710E1D),
                    fontSize: 12,
                  ),
                ),
              ),

            _passwordChecklist(newPasswordController.text),

            const SizedBox(height: 175),

            // Set new password button
            Center(
              child: Container(
                width: 200,
                margin: const EdgeInsets.symmetric(horizontal: 15),
                child: OutlinedButton(
                  style:
                      OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(
                          color: passwordsMatch
                              ? const Color(0xFF710E1D)
                              : Colors.black,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        backgroundColor: passwordsMatch
                            ? const Color(0xFF710E1D)
                            : Colors.white,
                      ).copyWith(
                        overlayColor: WidgetStateProperty.all(
                          Colors.grey.withOpacity(0.2),
                        ),
                      ),
                  onPressed: _changePassword,
                  child: Text(
                    "Set new password",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.normal,
                      color: passwordsMatch ? Colors.white : Colors.black,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
