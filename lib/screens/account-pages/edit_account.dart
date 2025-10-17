/*
  File: edit_account.dart
  Purpose: Allows users to update their account information and upload a new profile picture. 
           Integrates with Supabase for profile data and storage management.
  Developers: Rebusa, Amber Kaia J. [juliankaiaaa]
              Pineda, Mary Alexa Ysabelle V. [hrspnd]
*/

import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:supabase_flutter/supabase_flutter.dart';

class EditAccountPage extends StatefulWidget {
  const EditAccountPage({super.key});

  @override
  State<EditAccountPage> createState() => _EditAccountPageState();
}

final supabase = Supabase.instance.client;

class _EditAccountPageState extends State<EditAccountPage> {
  // ==================== BACK END ==================== //
  File? _selectedImage;

  // Lets user choose camera or gallery
  Future<void> _pickImage() async {
    final picker = ImagePicker();

    // Ask user: Camera or Gallery
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Color(0xff65000F)),
              title: const Text(
                'Take a Photo',
                style: TextStyle(color: Color(0xff65000F)),
              ),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(
                Icons.photo_library,
                color: Color(0xff65000F),
              ),
              title: const Text(
                'Choose from Gallery',
                style: TextStyle(color: Color(0xff65000F)),
              ),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<String?> _uploadProfilePicture(File file) async {
    final user = supabase.auth.currentUser;
    if (user == null) throw Exception("User not logged in");

    final fileName =
        "${user.id}_${DateTime.now().millisecondsSinceEpoch}${path.extension(file.path)}";

    // Upload to "profilepictures" bucket
    await supabase.storage.from('profilepictures').upload(fileName, file);

    // Get public URL
    final publicUrl = supabase.storage
        .from('profilepictures')
        .getPublicUrl(fileName);

    return publicUrl;
  }

  // ================================================== //

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _numberController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
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
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xff65000F),
        fontSize: 12,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _numberController.dispose();
    super.dispose();
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
                'Edit Account',
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
        padding: const EdgeInsets.symmetric(horizontal: 35.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 40),

            // PHOTO SECTION
            Center(
              child: Stack(
                children: [
                  Container(
                    width: 130,
                    height: 130,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Color(0xff65000F), width: 4),
                    ),
                    child: CircleAvatar(
                      backgroundColor: const Color(0xffE0E0E0),
                      backgroundImage: _selectedImage != null
                          ? FileImage(_selectedImage!)
                          : const AssetImage("assets/png/no-profile.png")
                                as ImageProvider,
                    ),
                  ),

                  // Add photo button (bottom-right corner)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 45,
                      height: 45,
                      decoration: BoxDecoration(
                        color: const Color(0xffE2E2E2),
                        shape: BoxShape.circle,
                        border: Border.all(color: Color(0xff65000F), width: 3),
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.add_a_photo,
                          size: 20,
                          color: Color.fromARGB(255, 109, 109, 109),
                        ),
                        onPressed: _pickImage,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            // FORM SECTION
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // FIRST NAME FIELD
                  _buildLabel("First Name"),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _firstNameController,
                    decoration: _inputDecoration("Enter your first name"),
                  ),
                  const SizedBox(height: 12),

                  // LAST NAME FIELD
                  _buildLabel("Last Name"),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _lastNameController,
                    decoration: _inputDecoration("Enter your last name"),
                  ),
                  const SizedBox(height: 12),

                  const SizedBox(height: 120),

                  // SAVE BUTTON
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          barrierDismissible: true, // allow tapping outside
                          builder: (BuildContext context) {
                            return Dialog(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                              backgroundColor: Colors.white,
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      "Save changes?",
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    const Text(
                                      "Do you want to save your recent changes?",
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.black,
                                      ),
                                    ),
                                    const SizedBox(height: 6),

                                    // divider
                                    const Divider(
                                      color: Colors.grey,
                                      thickness: 1,
                                    ),

                                    const SizedBox(height: 6),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        // Cancel button
                                        TextButton(
                                          onPressed: () {
                                            Navigator.pop(context);
                                          },
                                          child: const Text(
                                            "Cancel",
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.normal,
                                              color: Colors.black,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),

                                        // Save Changes button
                                        ElevatedButton(
                                          onPressed: () async {
                                            final user =
                                                supabase.auth.currentUser;
                                            if (user == null) return;

                                            try {
                                              // 1Read current profile (to preserve values the user leaves blank)
                                              final current = await supabase
                                                  .from('Profiles')
                                                  .select(
                                                    'name, profile_picture_url',
                                                  )
                                                  .eq('id', user.id)
                                                  .maybeSingle();

                                              final existingName =
                                                  (current?['name'] as String?)
                                                      ?.trim() ??
                                                  '';

                                              // Split existing name to try to preserve first/last when only one is edited
                                              final parts = existingName
                                                  .split(RegExp(r'\s+'))
                                                  .where((p) => p.isNotEmpty)
                                                  .toList();
                                              final existingFirst =
                                                  parts.isNotEmpty
                                                  ? parts.first
                                                  : '';
                                              final existingLast =
                                                  parts.length > 1
                                                  ? parts.sublist(1).join(' ')
                                                  : '';

                                              // Upload photo once if selected
                                              String? uploadedUrl;
                                              if (_selectedImage != null) {
                                                uploadedUrl =
                                                    await _uploadProfilePicture(
                                                      _selectedImage!,
                                                    );
                                              }

                                              // Read inputs
                                              final firstName =
                                                  _firstNameController.text
                                                      .trim();
                                              final lastName =
                                                  _lastNameController.text
                                                      .trim();

                                              // Build the minimal update map (do NOT include empty fields)
                                              final updateData =
                                                  <String, dynamic>{};

                                              // Name: only set if either field was provided. Merge with existing.
                                              if (firstName.isNotEmpty ||
                                                  lastName.isNotEmpty) {
                                                final finalFirst =
                                                    firstName.isNotEmpty
                                                    ? firstName
                                                    : existingFirst;
                                                final finalLast =
                                                    lastName.isNotEmpty
                                                    ? lastName
                                                    : existingLast;
                                                final mergedName =
                                                    ('$finalFirst $finalLast')
                                                        .trim();
                                                if (mergedName.isNotEmpty) {
                                                  updateData['name'] =
                                                      mergedName;
                                                }
                                              }

                                              // Photo: only set if a new image was uploaded
                                              if (uploadedUrl != null &&
                                                  uploadedUrl.isNotEmpty) {
                                                updateData['profile_picture_url'] =
                                                    uploadedUrl;
                                              }

                                              // 5) Only hit the database if there’s something to update
                                              if (updateData.isNotEmpty) {
                                                await supabase
                                                    .from('Profiles')
                                                    .update(updateData)
                                                    .eq('id', user.id);
                                              }

                                              if (context.mounted) {
                                                Navigator.pop(
                                                  context,
                                                ); // close dialog
                                                Navigator.pop(
                                                  context,
                                                ); // go back to Account page
                                              }
                                            } catch (e) {
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      'Error updating profile: $e',
                                                    ),
                                                  ),
                                                );
                                              }
                                            }
                                          },

                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(
                                              0xff65000F,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 20,
                                              vertical: 10,
                                            ),
                                          ),
                                          child: const Text(
                                            "Save",
                                            style: TextStyle(
                                              fontSize: 14,
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
                            );
                          },
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xff65000F),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "Save Changes",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
