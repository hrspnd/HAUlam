/*
  File: vendor_create_dish.dart
  Purpose: Allows vendors to create and upload new dishes, including image upload,
           tag selection, and Supabase integration for storing dish data.
  Developers: Magat, Maria Josephine M. [jsphnmgt]
              Pineda, Mary Alexa Ysabelle V. [hrspnd]
*/

import 'package:flutter/material.dart';
import '../store_roof.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

// ==================== BACK END ==================== //

Future<String?> _getStallId() async {
  final user = supabase.auth.currentUser;
  if (user == null) return null;

  final stall = await supabase
      .from("Stalls")
      .select("id")
      .eq("owner_id", user.id) 
      .maybeSingle();

  return stall?['id'] as String?;
}

// ================================================== //

class VendorCreateDishPage extends StatefulWidget {
  const VendorCreateDishPage({super.key});

  @override
  State<VendorCreateDishPage> createState() => _VendorCreateDishPageState();
}

class _VendorCreateDishPageState extends State<VendorCreateDishPage> {
  // ==================== BACK END ==================== //
  bool isAvailable = true;

  final TextEditingController _dishNameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  String? imageUrl;

  Future<void> _saveDish() async {
    // basic validation
    final dishName = _dishNameController.text.trim();
    final price = double.tryParse(_priceController.text.trim()) ?? 0;
    final description = _descriptionController.text.trim();

    if (dishName.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter a dish name')));
      return;
    }
    if (price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid price')),
      );
      return;
    }

    setState(() {
    });

    try {
      final stallId = await _getStallId();
      if (stallId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No stall found for this user')),
        );
        return;
      }

      // Insert dish and get the inserted record (id)
      final dishInsert = {
        "stall_id": stallId,
        "dish_name": dishName,
        "price": price,
        "description": description.isNotEmpty ? description : null,
        "image_url": imageUrl ?? "",
        "available": isAvailable,
      };

      // return the inserted row(s)
      final insertedDishRes = await supabase
          .from('Dishes')
          .insert(dishInsert)
          .select()
          .maybeSingle();

      final dishId = insertedDishRes?['id'] as String?;
      if (dishId == null) {
        throw Exception('Failed to insert dish or missing id');
      }

      // Handle tags 
      // selectedTags is List<String> defined in the state
      if (selectedTags.isNotEmpty) {
        // Fetch existing tags that match selectedTags
        final existingTagsRes = await supabase
            .from('Tags')
            .select('id, name')
            .inFilter('name', selectedTags);

        // convert to Map name -> id for easy lookup
        final Map<String, String> existingNameToId = {};
        if (existingTagsRes.isNotEmpty) {
          for (final row in (existingTagsRes as List)) {
            existingNameToId[row['name'] as String] = row['id'] as String;
          }
        }

        // Determine which tags are missing and insert them
        final missingTagNames = selectedTags
            .where((t) => !existingNameToId.containsKey(t))
            .toList();

        if (missingTagNames.isNotEmpty) {
          // insert missing tags and return rows
          final insertMissing = missingTagNames
              .map((name) => {"name": name})
              .toList();

          final insertedTagsRes = await supabase
              .from('Tags')
              .insert(insertMissing)
              .select();

          if (insertedTagsRes.isNotEmpty) {
            for (final r in (insertedTagsRes as List)) {
              existingNameToId[r['name'] as String] = r['id'] as String;
            }
          }
        }

        // Build mapping rows for DishTags
        final List<Map<String, dynamic>> mappings = [];
        for (final tagName in selectedTags) {
          final tagId = existingNameToId[tagName];
          if (tagId != null) {
            mappings.add({'dish_id': dishId, 'tag_id': tagId});
          }
        }

        if (mappings.isNotEmpty) {
          await supabase.from('DishTags').insert(mappings);
        }
      }

      // success UI
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dish created successfully')),
      );

      _dishNameController.clear();
      _priceController.clear();
      _descriptionController.clear();
      setState(() {
        selectedTags = [];
        imageUrl = null;
        isAvailable = true;
      });

      Navigator.pop(context);
    } catch (e) {
      debugPrint('Error in _saveDish: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error creating dish: $e')));
      }
    } finally {
      setState(() {
      });
    }
  }

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
        imageUrl = url; 
      });

      print("Image uploaded successfully: $url");
    } catch (e) {
      print("Upload error: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
    }
  }

  //===========================================TAGS===========================================
  List<Map<String, dynamic>> allTags = [
    {"label": "Beef", "color": const Color(0xff8B4513)},
    {"label": "Chicken", "color": const Color(0xffFFA726)},
    {"label": "Fish", "color": const Color(0xff76C7C0)},
    {"label": "Pork", "color": const Color(0xffF28B82)},
    {"label": "Salty", "color": const Color(0xff90A4AE)},
    {"label": "Savory", "color": const Color(0xffA1887F)},
    {"label": "Seafood", "color": const Color(0xff0277BD)},
    {"label": "Soup", "color": const Color(0xffBDBDBD)},
    {"label": "Sour", "color": const Color(0xffFFD966)},
    {"label": "Spicy", "color": const Color(0xffE53935)},
    {"label": "Sweet", "color": const Color(0xffF48FB1)},
    {"label": "Vegetable", "color": const Color(0xff81C784)},
  ];

  List<String> selectedTags = [];

  // ================================================== //

  void _openTagSelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Select Tags",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 16),
                  if (selectedTags.isNotEmpty) ...[
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Selected",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: selectedTags.map((tag) {
                        final color = allTags.firstWhere(
                          (t) => t["label"] == tag,
                          orElse: () => {"color": Colors.grey},
                        )["color"];
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(
                              color: const Color(0xff710E1D),
                              width: 1.5,
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircleAvatar(radius: 6, backgroundColor: color),
                              const SizedBox(width: 8),
                              Text(
                                tag,
                                style: const TextStyle(color: Colors.black),
                              ),
                              const SizedBox(width: 4),
                              GestureDetector(
                                onTap: () {
                                  setModalState(() => selectedTags.remove(tag));
                                  setState(() {});
                                },
                                child: const Icon(
                                  Icons.close,
                                  size: 16,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                  ],
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Select more",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: allTags
                        .where((tag) => !selectedTags.contains(tag["label"]))
                        .map((tag) {
                          final color = tag["color"] as Color;
                          return GestureDetector(
                            onTap: () {
                              setModalState(
                                () => selectedTags.add(tag["label"]),
                              );
                              setState(() {});
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(
                                  color: const Color(0xff710E1D),
                                  width: 1.5,
                                ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CircleAvatar(
                                    radius: 6,
                                    backgroundColor: color,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    tag["label"],
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        })
                        .toList(),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xff710E1D),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        "Done",
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
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
                padding: const EdgeInsets.fromLTRB(20, 30, 20, 60),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      "KIRSTENJOY",
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Transform.translate(
                      offset: const Offset(0, -8),
                      child: const Text(
                        "Create Dish",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ===== Image Upload Box =====
                    Transform.translate(
                      offset: const Offset(0, -20),
                      child: Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 280,
                            height: 220,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: const Color(0xff710E1D),
                                width: 4,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: imageUrl == null || imageUrl!.isEmpty
                                  ? Image.asset(
                                      "assets/png/image-rectangle.png",
                                      fit: BoxFit.cover,
                                    )
                                  : Image.network(imageUrl!, fit: BoxFit.cover),
                            ),
                          ),
                          Positioned(
                            bottom: -8,
                            right: -8,
                            child: Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xff710E1D),
                                  width: 4,
                                ),
                                color: const Color(0xffE2E2E2),
                              ),
                              child: IconButton(
                                icon: const Icon(
                                  Icons.add_a_photo,
                                  size: 22,
                                  color: Color.fromARGB(255, 109, 109, 109),
                                ),
                                onPressed: _pickImage,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 5),

                    // ===== Dish Name =====
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Dish Name",
                        style: TextStyle(
                          fontSize: 14,
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
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x20000000),
                            blurRadius: 4,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _dishNameController,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 14,
                        ),
                        decoration: const InputDecoration(
                          hintText: "Enter dish name",
                          hintStyle: TextStyle(
                            color: Color(0x40000000),
                            fontSize: 14,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                            borderSide: BorderSide(
                              color: Colors.black,
                              width: 1,
                            ),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ===== Price =====
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Price",
                        style: TextStyle(
                          fontSize: 14,
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
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x20000000),
                            blurRadius: 4,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _priceController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 14,
                        ),
                        decoration: InputDecoration(
                          prefixIcon: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 0, 0, 2),
                            child: Text(
                              "₱ ",
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 16,
                                fontFamily: 'Arial',
                              ),
                            ),
                          ),
                          prefixIconConstraints: const BoxConstraints(
                            minWidth: 0,
                            minHeight: 0,
                          ),
                          hintText: "Enter price",
                          hintStyle: const TextStyle(
                            color: Color(0x40000000),
                            fontSize: 14,
                          ),
                          border: const OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                          ),
                          focusedBorder: const OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                            borderSide: BorderSide(
                              color: Colors.black,
                              width: 1,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ===== Description =====
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Description",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: 314,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x20000000),
                            blurRadius: 4,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _descriptionController,
                        maxLines: 3,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 14,
                        ),
                        decoration: const InputDecoration(
                          hintText: "Add description",
                          hintStyle: TextStyle(
                            color: Color(0x40000000),
                            fontSize: 14,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                            borderSide: BorderSide(
                              color: Colors.black,
                              width: 1,
                            ),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ===== Tags =====
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Tags",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: 314,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x20000000),
                            blurRadius: 4,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: TextField(
                        readOnly: true,
                        onTap: _openTagSelector,
                        controller: TextEditingController(
                          text: selectedTags.isEmpty
                              ? ""
                              : selectedTags.join(", "),
                        ),
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 14,
                        ),
                        decoration: const InputDecoration(
                          hintText: "Select tags",
                          hintStyle: TextStyle(
                            color: Color(0x40000000),
                            fontSize: 14,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                            borderSide: BorderSide(
                              color: Colors.black,
                              width: 1,
                            ),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 16,
                          ),
                          suffixIcon: Icon(
                            Icons.arrow_drop_down,
                            color: Colors.black,
                            size: 28,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),

                    // ===== Create Button =====
                    GestureDetector(
                      onTap: () {
                        _saveDish();
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
