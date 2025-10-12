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
  // =========================== BACK - END [SUPABASE] ===========================
  File? _selectedImage;
  String? _imageUrl;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  /*
  Future<String?> _uploadProfilePicture(File file) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) throw Exception("User not logged in");

    final fileName =
        "${user.id}_${DateTime.now().millisecondsSinceEpoch}${path.extension(file.path)}";

    // Upload to Supabase Storage
    await Supabase.instance.client.storage
        .from('profilepictures')
        .upload(fileName, file);

    // Get public URL
    final publicUrl = Supabase.instance.client.storage
        .from('profilepictures')
        .getPublicUrl(fileName);

    return publicUrl;
  }

*/

  Future<String?> _uploadProfilePicture(File file) async {
    final user = supabase.auth.currentUser;
    if (user == null) throw Exception("User not logged in");

    // ✅ Unique file name based on user id and timestamp
    final fileName =
        "${user.id}_${DateTime.now().millisecondsSinceEpoch}${path.extension(file.path)}";

    // ✅ Upload to "profilepictures" bucket
    await supabase.storage.from('profilepictures').upload(fileName, file);

    // ✅ Get public URL
    final publicUrl = supabase.storage
        .from('profilepictures')
        .getPublicUrl(fileName);

    return publicUrl;
  }

  Future<void> _updateUserPicture(String imageUrl) async {
    await supabase.auth.updateUser(UserAttributes(data: {'picture': imageUrl}));
  }

  Future<void> _saveProfile() async {
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception("User not logged in");

      final fullName =
          "${_firstNameController.text.trim()} ${_lastNameController.text.trim()}";
      final newEmail = _emailController.text.trim();

      String? imageUrl;
      if (_selectedImage != null) {
        imageUrl = await _uploadProfilePicture(_selectedImage!);
      }

      // 1. Update Auth email
      await supabase.auth.updateUser(UserAttributes(email: newEmail));

      // 2. Update Profiles table
      final updateData = {
        'name': fullName,
        'email': newEmail,
        if (imageUrl != null) 'profile_picture_url': imageUrl,
      };

      await supabase.from('Profiles').update(updateData).eq('id', user.id);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully!')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  // =============================================================================

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
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
    _emailController.dispose();
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

                  // EMAIL FIELD
                  _buildLabel("Email"),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _emailController,
                    decoration: _inputDecoration("Enter your email"),
                  ),
                  const SizedBox(height: 100),

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
                                              // ✅ 1. Upload profile picture if selected
                                              String? uploadedUrl;
                                              if (_selectedImage != null) {
                                                uploadedUrl =
                                                    await _uploadProfilePicture(
                                                      _selectedImage!,
                                                    );
                                              }

                                              // ✅ 2. Get input values
                                              final firstName =
                                                  _firstNameController.text
                                                      .trim();
                                              final lastName =
                                                  _lastNameController.text
                                                      .trim();
                                              final newEmail = _emailController
                                                  .text
                                                  .trim();
                                              final fullName =
                                                  '$firstName $lastName'.trim();

                                              // ✅ 3. Upload image (if new)
                                              if (_selectedImage != null) {
                                                uploadedUrl =
                                                    await _uploadProfilePicture(
                                                      _selectedImage!,
                                                    );
                                              }

                                              // ✅ 4. Build update map
                                              final updateData =
                                                  <String, dynamic>{};

                                              if (firstName.isNotEmpty)
                                                updateData['first_name'] =
                                                    firstName;
                                              if (lastName.isNotEmpty)
                                                updateData['last_name'] =
                                                    lastName;
                                              if (uploadedUrl != null)
                                                updateData['profile_picture_url'] =
                                                    uploadedUrl;

                                              // ✅ 5. Update Profiles table
                                              await supabase
                                                  .from('Profiles')
                                                  .update({
                                                    'name':
                                                        '$firstName $lastName',
                                                    'email': newEmail.isNotEmpty
                                                        ? newEmail
                                                        : user.email,
                                                    if (uploadedUrl != null)
                                                      'profile_picture_url':
                                                          uploadedUrl,
                                                  })
                                                  .eq('id', user.id);

                                              // ✅ 6. Navigate back to Account Page
                                              if (context.mounted) {
                                                Navigator.pop(context);
                                                Navigator.pop(context);
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
                                                    backgroundColor: Colors.red,
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
