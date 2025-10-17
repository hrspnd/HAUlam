/*
  File: vendor_edit_profile.dart
  Purpose: Enables vendors to edit their stall's profile, including updating
           stall name, location, operating hours, and profile image. Integrates
           with Supabase for database and storage operations.
  Developers: Magat, Maria Josephine M. [jsphnmgt]
              Pineda, Mary Alexa Ysabelle V. [hrspnd]
*/

import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../store_roof.dart';

class VendorEditProfilePage extends StatefulWidget {
  final String stallId;
  const VendorEditProfilePage({super.key, required this.stallId});

  @override
  State<VendorEditProfilePage> createState() => _VendorEditProfilePageState();
}

class _VendorEditProfilePageState extends State<VendorEditProfilePage> {
  final supabase = Supabase.instance.client;

  final TextEditingController _stallNameController = TextEditingController();
  final _stallNameFocus = FocusNode();
  String? selectedLocation;
  String? imageUrl;

  TimeOfDay? openTime;
  TimeOfDay? closeTime;

  @override
  void initState() {
    super.initState();
    _loadStallFromDb();
  }

  @override
  void dispose() {
    _stallNameFocus.dispose();
    _stallNameController.dispose();
    super.dispose();
  }

  String formatTime(TimeOfDay? time) {
    if (time == null) return "--:--";
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final period = time.period == DayPeriod.am ? "AM" : "PM";
    return "$hour:${time.minute.toString().padLeft(2, '0')} $period";
  }

  TimeOfDay? _parseTimeString(String? s) {
    if (s == null || s.trim().isEmpty) return null;
    try {
      final parts = s.trim().split(' ');
      final hm = parts[0].split(':');
      var hour = int.parse(hm[0]);
      final minute = int.parse(hm[1]);
      final isPM = parts.length > 1 && parts[1].toUpperCase() == 'PM';
      if (isPM && hour < 12) hour += 12;
      if (!isPM && hour == 12) hour = 0;
      return TimeOfDay(hour: hour, minute: minute);
    } catch (_) {
      return null;
    }
  }

  Future<void> _loadStallFromDb() async {
    try {
      final row = await supabase
          .from('Stalls')
          .select('stall_name, location, image_url, open_time, close_time')
          .eq('id', widget.stallId)
          .maybeSingle();

      if (!mounted) return;

      if (row != null) {
        _stallNameController.text = (row['stall_name'] ?? '') as String;
        selectedLocation = (row['location'] ?? '') as String?;
        imageUrl = (row['image_url'] ?? '') as String?;

        openTime = _parseTimeString(row['open_time'] as String?);
        closeTime = _parseTimeString(row['close_time'] as String?);
      }
    } on PostgrestException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Supabase error: ${e.message}')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unexpected error: $e')));
    }
  }

  Future<void> _saveProfile() async {
    try {
      final update = {
        'stall_name': _stallNameController.text.trim(),
        'location': selectedLocation,
        'image_url': imageUrl,
        'open_time': openTime == null ? null : formatTime(openTime),
        'close_time': closeTime == null ? null : formatTime(closeTime),
      };

      await supabase.from('Stalls').update(update).eq('id', widget.stallId);

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Stall updated')));
      Navigator.pop(context);
    } on PostgrestException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Supabase error: ${e.message}')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unexpected error: $e')));
    }
  }

  /// ===== Cupertino Time Picker =====
  Future<void> _pickTime(bool isOpenTime) async {
    _stallNameFocus.unfocus();
    _stallNameFocus.canRequestFocus = false;

    TimeOfDay initialTime = isOpenTime
        ? (openTime ?? TimeOfDay.now())
        : (closeTime ?? TimeOfDay.now());

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext builder) {
        DateTime now = DateTime.now();
        DateTime initialDateTime = DateTime(
          now.year,
          now.month,
          now.day,
          initialTime.hour,
          initialTime.minute,
        );

        return SizedBox(
          height: 260,
          child: Column(
            children: [
              // ===== Top Done Button =====
              Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    "Done",
                    style: TextStyle(
                      color: Color(0xff710E1D),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.time,
                  initialDateTime: initialDateTime,
                  use24hFormat: false,
                  onDateTimeChanged: (DateTime newTime) {
                    setState(() {
                      final newTimeOfDay = TimeOfDay(
                        hour: newTime.hour,
                        minute: newTime.minute,
                      );
                      if (isOpenTime) {
                        openTime = newTimeOfDay;
                      } else {
                        closeTime = newTimeOfDay;
                      }
                    });
                  },
                ),
              ),
            ],
          ),
        );
      },
    ).whenComplete(() {
      if (!mounted) return;
      FocusScope.of(context).requestFocus(FocusNode());
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _stallNameFocus.canRequestFocus = true;
      });
    });
  }

  /// ===== Cupertino Location Picker =====
  Future<void> _pickLocation() async {
    FocusScope.of(context).unfocus();

    final List<String> locations = [
      "APS Canteen",
      "GGN Canteen",
      "PGN Basement",
      "St. Martha Hall",
      "Yellow Canteen",
    ];

    int selectedIndex = locations.indexOf(selectedLocation ?? "APS Canteen");
    if (selectedIndex < 0) selectedIndex = 0;

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return SizedBox(
          height: 260,
          child: Column(
            children: [
              // ===== Top Done Button =====
              Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    "Done",
                    style: TextStyle(
                      color: Color(0xff710E1D),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: CupertinoPicker(
                  backgroundColor: Colors.white,
                  itemExtent: 40,
                  scrollController: FixedExtentScrollController(
                    initialItem: selectedIndex,
                  ),
                  onSelectedItemChanged: (int index) {
                    setState(() {
                      selectedLocation = locations[index];
                    });
                  },
                  children: locations
                      .map(
                        (loc) => Center(
                          child: Text(
                            loc,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
    if (mounted) {
      FocusScope.of(context).requestFocus(FocusNode());
    }
  }

  File? _selectedImage;
  Future<void> _pickImage() async {
    try {
      // Let user choose camera or gallery
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
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take a photo'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo),
                title: const Text('Choose from gallery'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        ),
      );

      if (source == null) return;

      // Pick image
      final picker = ImagePicker();
      final file = await picker.pickImage(source: source);
      if (file == null) return;

      final bytes = await file.readAsBytes();
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';

      // Upload to Supabase
      await supabase.storage
          .from('dishimages') // or 'profilepictures' for user profiles
          .uploadBinary(fileName, bytes);

      // Get the public URL
      final url = supabase.storage.from('dishimages').getPublicUrl(fileName);

      // Update local state so the UI shows the new image
      setState(() {
        _selectedImage = File(file.path);
        imageUrl = url; // make sure you have imageUrl defined in your class
      });

      print("Image uploaded successfully: $url");
    } catch (e) {
      print("Upload error: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final roofHeight = screenWidth * 0.48;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned.fill(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(top: roofHeight - 40),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 30, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      "Stall Information",
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // ===== Image Upload Box =====
                    Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 180,
                          height: 180,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Color(0xff710E1D),
                              width: 4,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: _selectedImage != null
                                ? Image.file(_selectedImage!, fit: BoxFit.cover)
                                : (imageUrl != null && imageUrl!.isNotEmpty)
                                ? Image.network(imageUrl!, fit: BoxFit.cover)
                                : Image.asset(
                                    "assets/png/image-square.png",
                                    fit: BoxFit.cover,
                                  ),
                          ),
                        ),
                        Positioned(
                          bottom: -6,
                          right: -10,
                          child: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Color(0xff710E1D),
                                width: 4,
                              ),
                              color: const Color(0xffE2E2E2),
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
                    const SizedBox(height: 20),

                    // ===== Stall Name =====
                    Align(
                      alignment: Alignment.centerLeft,
                      child: const Text(
                        "Stall Name",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: 44,
                      width: 314,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0x20000000),
                            blurRadius: 4,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _stallNameController,
                        style: const TextStyle(
                          color: Color(0xff000000),
                          fontSize: 14,
                        ),
                        decoration: const InputDecoration(
                          hintText: "Enter a stall name",
                          hintStyle: TextStyle(
                            color: Color(0x50000000),
                            fontSize: 14,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ===== Location =====
                    Align(
                      alignment: Alignment.centerLeft,
                      child: const Text(
                        "Location",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: _pickLocation,
                      child: AbsorbPointer(
                        child: Container(
                          height: 44,
                          width: 314,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Color(0x20000000),
                                blurRadius: 4,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: DropdownButtonFormField<String>(
                            value: selectedLocation,
                            hint: const Text(
                              "Select location",
                              style: TextStyle(
                                color: Color(0x50000000),
                                fontSize: 14,
                                fontFamily: "Onest",
                                letterSpacing: 0.5,
                              ),
                            ),
                            style: const TextStyle(
                              color: Color(0xff000000),
                              fontSize: 14,
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: "APS Canteen",
                                child: Text("APS Canteen"),
                              ),
                              DropdownMenuItem(
                                value: "GGN Canteen",
                                child: Text("GGN Canteen"),
                              ),
                              DropdownMenuItem(
                                value: "PGN Basement",
                                child: Text("PGN Basement"),
                              ),
                              DropdownMenuItem(
                                value: "St. Martha Hall",
                                child: Text("St. Martha Hall"),
                              ),
                              DropdownMenuItem(
                                value: "Yellow Canteen",
                                child: Text("Yellow Canteen"),
                              ),
                            ],
                            onChanged: (_) {},
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(12),
                                ),
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 16,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ===== Operating Hours =====
                    Align(
                      alignment: Alignment.centerLeft,
                      child: const Text(
                        "Operating Hours",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // ===== Open Time button =====
                        Container(
                          width: 136,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Color(0x20000000),
                                blurRadius: 4,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: OutlinedButton(
                            onPressed: () => _pickTime(true),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.access_time,
                                    color: openTime == null
                                        ? const Color(0x40000000)
                                        : Colors.black,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    openTime == null
                                        ? "Open Time"
                                        : formatTime(openTime),
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: openTime == null
                                          ? const Color(0x40000000)
                                          : Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 16),
                        const Text(
                          "to",
                          style: TextStyle(fontSize: 14, color: Colors.black),
                        ),
                        const SizedBox(width: 16),

                        // ===== Close Time button =====
                        Container(
                          width: 136,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Color(0x20000000),
                                blurRadius: 4,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: OutlinedButton(
                            onPressed: () => _pickTime(false),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.access_time,
                                    color: closeTime == null
                                        ? const Color(0x40000000)
                                        : Colors.black,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 6),
                                  Transform.translate(
                                    offset: const Offset(0, -1),
                                    child: Text(
                                      closeTime == null
                                          ? "Close Time"
                                          : formatTime(closeTime),
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: closeTime == null
                                            ? const Color(0x40000000)
                                            : Colors.black,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),

                    GestureDetector(
                      onTap: () {
                        _saveProfile();
                      },
                      child: Container(
                        width: 318,
                        height: 46,
                        decoration: BoxDecoration(
                          color: const Color(0xff710E1D),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Text(
                            "Save",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const Positioned(top: 0, left: 0, right: 0, child: StoreRoof()),

          Positioned(
            top: 45,
            left: 12,
            child: Container(
              width: 30,
              height: 30,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.arrow_back,
                  color: Colors.black,
                  size: 22,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
