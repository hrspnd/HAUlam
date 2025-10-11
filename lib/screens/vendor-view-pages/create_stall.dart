import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:haulam/screens/maintwo.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../store_roof.dart';

// ============================= BACK - END THINGS =============================

final supabase = Supabase.instance.client;

Future<void> createStall({
  required String stallName,
  required String location,
  required String openTime,
  required String closeTime,
}) async {
  final user = supabase.auth.currentUser;
  if (user == null) throw Exception('User not logged in');

  final response = await supabase.from('Stalls').insert({
    'owner_id': user.id,
    'stall_name': stallName,
    'location': location,
    'open_time': openTime,
    'close_time': closeTime,
  }).select();

  if (response.isEmpty) {
    throw Exception('Failed to insert stall');
  }
}

Future<String> uploadStallImage(File file) async {
  final user = supabase.auth.currentUser;
  if (user == null) throw Exception("User not logged in");

  final fileName = "${DateTime.now().millisecondsSinceEpoch}${path.extension(file.path)}";
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


// =============================================================================

class CreateStallPage extends StatefulWidget {
  const CreateStallPage({super.key});

  @override
  State<CreateStallPage> createState() => _CreateStallPageState();
}

class _CreateStallPageState extends State<CreateStallPage> {
  final TextEditingController _stallNameController = TextEditingController();

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
    );
  }

  /// ===== Cupertino Location Picker =====
  Future<void> _pickLocation() async {
    final List<String> locations = [
      "APS Canteen",
      "GGN Canteen",
      "PGN Basement",
      "St. Martha Hall",
      "Yellow Canteen",
    ];

    int selectedIndex = locations.indexOf(
      selectedLocation ?? "St. Martha Hall",
    );

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white, // 👈 Ensures white background
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
  }

  /// ===== Save Profile to Supabase =====
  void _saveProfile() async {
    final stallData = {
      "stallName": _stallNameController.text,
      "location": selectedLocation,
      "openTime": formatTime(openTime),
      "closeTime": formatTime(closeTime),
      "imageUrl": imageUrl ?? "",
    };

    // 👇 BACKEND CODE HERE
    // TODO: Use Supabase to insert/update stall data
    // Example:
    // final response = await Supabase.instance.client
    //   .from('stalls')
    //   .upsert(stallData)
    //   .select();
    //
    // Handle success/error

    print("Stall Data to Save: $stallData");
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
                            borderRadius: BorderRadius.circular(12),
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
                                // 👇 BACKEND CODE HERE
                                // TODO: Open Image Picker
                                // - Upload image to Supabase Storage
                                // - Get public URL
                                // - setState(() => imageUrl = uploadedUrl);
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
                      onTap: () async {
                        final stallName = _stallNameController.text.trim();
                        final location = selectedLocation ?? "";
                        final open = formatTime(openTime);
                        final close = formatTime(closeTime);

                        if ((stallName?.isEmpty ?? true)) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Please enter the stall name."),
                            ),
                          );
                          return;
                        }

                        if ((location?.isEmpty ?? true)) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Please select a location."),
                            ),
                          );
                          return;
                        }

                        if (openTime == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Please select an opening time."),
                            ),
                          );
                          return;
                        }

                        if (closeTime == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Please select a closing time."),
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
                          );

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Stall created successfully!"),
                            ),
                          );

                          // Redirect to My Stall page
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const MainTwoScaffold(),
                            ),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text("Error: $e")));
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
    );
  }
}
