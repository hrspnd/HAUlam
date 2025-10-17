/*
  File: vendor_create_stall.dart
  Purpose: Enables vendors to create and register new stalls with name, location,
           operating hours, and image upload. Integrates with Supabase for
           database and storage operations.
  Developers: Magat, Maria Josephine M. [jsphnmgt]
              Pineda, Mary Alexa Ysabelle V. [hrspnd]
*/

import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:haulam/screens/vendor_navbar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../store_roof.dart';

// ==================== BACK END ==================== //

final supabase = Supabase.instance.client;
final ImagePicker _picker = ImagePicker();

Future<void> createStall({
  required String stallName,
  required String location,
  required String openTime,
  required String closeTime,
  String? imageUrl,
}) async {
  final user = supabase.auth.currentUser;
  if (user == null) throw Exception('User not logged in');

  try {
    final response = await supabase.from('Stalls').insert({
      'owner_id': user.id,
      'stall_name': stallName,
      'location': location,
      'open_time': openTime,
      'close_time': closeTime,
      'image_url': imageUrl ?? "",
    }).select();

    if (response.isEmpty) {
      throw Exception('Failed to insert stall');
    }
  } catch (e) {
    throw Exception('Error creating stall: $e');
  }
}

Future<String> uploadStallImage(File file) async {
  final user = supabase.auth.currentUser;
  if (user == null) throw Exception("User not logged in");

  final fileName =
      "${DateTime.now().millisecondsSinceEpoch}${path.extension(file.path)}";
  final filePath = "${user.id}/$fileName";

  try {
    await supabase.storage
        .from('stalls')
        .upload(filePath, file, fileOptions: const FileOptions(upsert: true));

    return supabase.storage.from('stalls').getPublicUrl(filePath);
  } catch (e) {
    throw Exception("Image upload failed: $e");
  }
}

// ================================================== //

class CreateStallPage extends StatefulWidget {
  const CreateStallPage({super.key});

  @override
  State<CreateStallPage> createState() => _CreateStallPageState();
}

class _CreateStallPageState extends State<CreateStallPage> {
  final TextEditingController _stallNameController = TextEditingController();
  final _stallNameFocus = FocusNode();

  String? selectedLocation;
  String? imageUrl;

  TimeOfDay? openTime;
  TimeOfDay? closeTime;

  String formatTime(TimeOfDay? time) {
    if (time == null) return "--:--";
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final period = time.period == DayPeriod.am ? "AM" : "PM";
    return "$hour:${time.minute.toString().padLeft(2, '0')} $period";
  }

  /// ===== Cupertino Time Picker =====
  Future<void> _pickTime(bool isOpenTime) async {
    _stallNameFocus.unfocus();
    _stallNameFocus.canRequestFocus = false;

    TimeOfDay initialTime = isOpenTime
        ? (openTime ?? TimeOfDay.now())
        : (closeTime ?? TimeOfDay.now());

    DateTime now = DateTime.now();
    DateTime initialDateTime = DateTime(
      now.year,
      now.month,
      now.day,
      initialTime.hour,
      initialTime.minute,
    );

    DateTime tempSelectedTime = initialDateTime;

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext builder) {
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
                  onPressed: () {
                    setState(() {
                      final newTimeOfDay = TimeOfDay(
                        hour: tempSelectedTime.hour,
                        minute: tempSelectedTime.minute,
                      );
                      if (isOpenTime) {
                        openTime = newTimeOfDay;
                      } else {
                        closeTime = newTimeOfDay;
                      }
                    });
                    Navigator.pop(context);
                  },
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
                    tempSelectedTime = newTime;
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

    final locations = [
      "APS Canteen",
      "GGN Canteen",
      "PGN Basement",
      "St. Martha Hall",
      "Yellow Canteen",
    ];

    int selectedIndex = locations.indexOf(selectedLocation ?? "APS Canteen");
    if (selectedIndex < 0) selectedIndex = 0;

    if (selectedLocation == null) {
      setState(() => selectedLocation = locations[selectedIndex]);
    }

    final controller = FixedExtentScrollController(initialItem: selectedIndex);
    int tempIndex = selectedIndex;

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return SizedBox(
          height: 260,
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
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
                  itemExtent: 40,
                  scrollController: controller,
                  onSelectedItemChanged: (i) =>
                      tempIndex = i, 
                  children: locations
                      .map((loc) => Center(child: Text(loc)))
                      .toList(),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (!mounted) return;
    setState(() => selectedLocation = locations[tempIndex]);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final roofHeight = screenWidth * 0.48;

    return Scaffold(
      backgroundColor: Colors.white,
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusScope.of(context).unfocus(),
        child: Stack(
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
                        "Create Stall",
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
                              child: imageUrl == null || imageUrl!.isEmpty
                                  ? Image.asset(
                                      "assets/png/image-square.png",
                                      fit: BoxFit.cover,
                                    )
                                  : Image.network(imageUrl!, fit: BoxFit.cover),
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
                                onPressed: () async {
                                  try {
                                    final XFile? pickedFile = await _picker
                                        .pickImage(source: ImageSource.gallery);
                                    if (pickedFile == null) return;

                                    final File file = File(pickedFile.path);
                                    final uploadedUrl = await uploadStallImage(
                                      file,
                                    );

                                    setState(() {
                                      imageUrl =
                                          uploadedUrl; 
                                    });
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Image upload failed: $e',
                                        ),
                                      ),
                                    );
                                  }
                                },
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
                          focusNode: _stallNameFocus,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => FocusScope.of(context).unfocus(),
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
                        onTap: () {
                          FocusScope.of(context).unfocus();
                          _pickLocation();
                        },
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
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
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
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
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
                        onTap: () async {
                          final stallName = _stallNameController.text.trim();
                          final location = selectedLocation ?? "";
                          final open = formatTime(openTime);
                          final close = formatTime(closeTime);

                          if (stallName.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Please enter the stall name."),
                              ),
                            );
                            return;
                          }

                          if (location.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Please select a location."),
                              ),
                            );
                            return;
                          }

                          if (openTime == null || closeTime == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  "Please select opening and closing times.",
                                ),
                              ),
                            );
                            return;
                          }

                          try {
                            await createStall(
                              stallName: stallName,
                              location: location,
                              openTime: open,
                              closeTime: close,
                              imageUrl: imageUrl,
                            );

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Stall created successfully!"),
                              ),
                            );

                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const VendorNavBar(),
                              ),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Error: $e")),
                            );
                          }
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
                              "Create",
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
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _stallNameFocus.dispose();
    _stallNameController.dispose();
    super.dispose();
  }
}
