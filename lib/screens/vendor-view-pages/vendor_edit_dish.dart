/*
  File: vendor_edit_dish.dart
  Purpose: Allows vendors or admins to edit an existing dish, including updating
           name, price, description, availability, image, and tags. Supports
           saving changes to Supabase and deleting the dish with confirmation.
  Developers: Magat, Maria Josephine M. [jsphnmgt]
              Pineda, Mary Alexa Ysabelle V. [hrspnd]
*/

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../store_roof.dart';

final supabase = Supabase.instance.client;

class VendorEditDishPage extends StatefulWidget {
  // pass the dish row from Supabase (must include 'id')
  final Map<String, dynamic> dish;

  const VendorEditDishPage({super.key, required this.dish});

  @override
  State<VendorEditDishPage> createState() => _VendorEditDishPageState();
}

class _VendorEditDishPageState extends State<VendorEditDishPage> {
  // ==================== BACK END ==================== //
  bool isAvailable = true;

  final TextEditingController _dishNameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  String? imageUrl;

  // ===== image picker =====
  bool _uploading = false;

  // ===== TAGS =====
  final List<Map<String, dynamic>> allTags = const [
    {"label": "Beef", "color": Color(0xff8B4513)},
    {"label": "Chicken", "color": Color(0xffFFA726)},
    {"label": "Fish", "color": Color(0xff76C7C0)},
    {"label": "Pork", "color": Color(0xffF28B82)},
    {"label": "Salty", "color": Color(0xff90A4AE)},
    {"label": "Savory", "color": Color(0xffA1887F)},
    {"label": "Seafood", "color": Color(0xff0277BD)},
    {"label": "Soup", "color": Color(0xffBDBDBD)},
    {"label": "Sour", "color": Color(0xffFFD966)},
    {"label": "Spicy", "color": Color(0xffE53935)},
    {"label": "Sweet", "color": Color(0xffF48FB1)},
    {"label": "Vegetable", "color": Color(0xff81C784)},
  ];

  /// currently selected tag NAMES 
  List<String> selectedTags = [];

  /// ids of currently-linked tags from DB
  Set<String> _existingLinkedTagIds = {};

  @override
  void initState() {
    super.initState();
    final d = widget.dish;
    _dishNameController.text = (d['dish_name'] ?? '').toString();
    _descriptionController.text = (d['description'] ?? '').toString();
    _priceController.text = (d['price'] ?? '').toString();
    isAvailable = (d['available'] as bool?) ?? true;
    imageUrl = (d['image_url'] as String?) ?? '';

    _loadDishTags();
  }

  // ---------- LOAD existing tags for this dish ----------
  Future<void> _loadDishTags() async {
    final dishId = widget.dish['id'];
    if (dishId == null) return;

    try {
      final rows = await supabase
          .from('DishTags')
          .select('tag_id, Tags(name)')
          .eq('dish_id', dishId);

      final names = <String>[];
      final ids = <String>{};

      for (final r in (rows as List)) {
        final tagName = (r['Tags']?['name'] as String?)?.trim();
        final tagId = r['tag_id']?.toString();
        if (tagName != null && tagName.isNotEmpty) names.add(tagName);
        if (tagId != null) ids.add(tagId);
      }

      if (!mounted) return;
      setState(() {
        selectedTags = names;
        _existingLinkedTagIds = ids;
      });
    } catch (e) {
      // silently ignore 
    }
  }

  // ---------- SAVE dish + tags ----------
  Future<void> _saveDish() async {
    final id = widget.dish['id'];
    if (id == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Missing dish id')));
      return;
    }

    final payload = {
      'dish_name': _dishNameController.text.trim(),
      'description': _descriptionController.text.trim(),
      'price': double.tryParse(_priceController.text.trim()) ?? 0.0,
      'available': isAvailable,
      'image_url': imageUrl ?? '',
    };

    try {
      // update dish row
      await supabase.from('Dishes').update(payload).eq('id', id);

      // sync tags
      await _saveTagsForDish(id);

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Dish updated')));
      Navigator.pop(context, true);
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

  /// Creates missing tag names in `Tags`, then diffs & updates `DishTags`
  Future<void> _saveTagsForDish(String dishId) async {
    // normalize names (trim)
    final names = selectedTags
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    if (names.isEmpty) {
      // if user removed all tags, delete all mappings
      if (_existingLinkedTagIds.isNotEmpty) {
        await supabase.from('DishTags').delete().eq('dish_id', dishId);
        _existingLinkedTagIds.clear();
      }
      return;
    }

    // fetch existing tags by name
    final existing = await supabase
        .from('Tags')
        .select('id, name')
        .inFilter('name', names);

    final Map<String, String> nameToId = {};
    for (final row in (existing as List)) {
      nameToId[(row['name'] as String)] = row['id'] as String;
    }

    // determine missing names & insert them
    final missing = names.where((n) => !nameToId.containsKey(n)).toList();
    if (missing.isNotEmpty) {
      final inserted = await supabase
          .from('Tags')
          .insert(missing.map((n) => {'name': n}).toList())
          .select();

      for (final row in (inserted as List)) {
        nameToId[(row['name'] as String)] = row['id'] as String;
      }
    }

    // build desired tag id set
    final desiredTagIds = names
        .map((n) => nameToId[n])
        .where((id) => id != null)
        .cast<String>()
        .toSet();

    // figure out which to add/remove
    final toAdd = desiredTagIds.difference(_existingLinkedTagIds);
    final toRemove = _existingLinkedTagIds.difference(desiredTagIds);

    if (toAdd.isNotEmpty) {
      final rows = toAdd
          .map((tagId) => {'dish_id': dishId, 'tag_id': tagId})
          .toList();
      await supabase.from('DishTags').insert(rows);
    }
    if (toRemove.isNotEmpty) {
      for (final tagId in toRemove) {
        await supabase
            .from('DishTags')
            .delete()
            .eq('dish_id', dishId)
            .eq('tag_id', tagId);
      }
    }

    _existingLinkedTagIds = desiredTagIds;
  }

  // ====== same tag selector UI from Create Dish ======
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
                        final color =
                            (allTags.firstWhere(
                                  (t) => t["label"] == tag,
                                  orElse: () => {"color": Colors.grey},
                                )["color"]
                                as Color);
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
                                  setState(() {}); // update field text
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
                                () => selectedTags.add(tag["label"] as String),
                              );
                              setState(() {}); // update field text
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
                                    tag["label"] as String,
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
          .from('dishimages') 
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
 
  Future<void> _confirmAndDelete() async {
    // Show confirm dialog
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Delete Dish",
              style: TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Are you sure you want to delete this dish? "
              "This action is permanent and cannot be undone.",
              style: TextStyle(color: Colors.black, fontSize: 14, height: 1.4),
            ),
            const SizedBox(height: 16),
            const Divider(color: Color(0xFFBDBDBD), thickness: 1, height: 1),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text(
                    "Cancel",
                    style: TextStyle(
                      color: Color(0xFF747474),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF710E1D),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 10,
                    ),
                  ),
                  child: const Text(
                    "Confirm",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    if (confirmed != true) return;

    // Backend delete
    final id = widget.dish['id'];
    if (id == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Missing dish id')));
      return;
    }

    try {
      final imageUrl = widget.dish['image_url'] as String?;
      if (imageUrl != null && imageUrl.isNotEmpty) {
      }

      // Remove tag links first (FK safety if not cascade)
      await supabase.from('DishTags').delete().eq('dish_id', id);

      // Remove the dish
      await supabase.from('Dishes').delete().eq('id', id);

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Dish deleted')));
      Navigator.pop(context, true); // close Edit page and signal success
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

  // ================================================== //
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
                      "Edit Dish",
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Transform.translate(
                      offset: const Offset(0, -8),
                      child: const Text(
                        "Admin View",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ===== image box =====
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
                              child: (imageUrl == null || imageUrl!.isEmpty)
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
                                icon: _uploading
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.add_a_photo,
                                        size: 22,
                                        color: Color.fromARGB(
                                          255,
                                          109,
                                          109,
                                          109,
                                        ),
                                      ),
                                onPressed: _uploading ? null : _pickImage,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // ===== Availability =====
                    _AvailabilitySwitch(
                      value: isAvailable,
                      onChanged: (v) => setState(() => isAvailable = v),
                    ),
                    const SizedBox(height: 25),

                    _LabeledField(
                      label: 'Dish Name',
                      controller: _dishNameController,
                      hint: 'Enter dish name',
                    ),
                    const SizedBox(height: 16),

                    _LabeledField(
                      label: 'Price',
                      controller: _priceController,
                      hint: 'Enter price',
                      isPrice: true,
                    ),
                    const SizedBox(height: 16),

                    _LabeledField(
                      label: 'Description',
                      controller: _descriptionController,
                      hint: 'Add description',
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),

                    // ===== TAGS field =====
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

                    // ===== Save Button =====
                    GestureDetector(
                      onTap: _saveDish,
                      child: Container(
                        width: 318,
                        height: 46,
                        decoration: BoxDecoration(
                          color: const Color(0xff710E1D),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Text(
                            "Save changes",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: _confirmAndDelete,
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 6.0),
                        child: Text(
                          "Tap here to delete.",
                          style: TextStyle(
                            color: Color(0xff710E1D),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.none,
                          ),
                          textAlign: TextAlign.center,
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

// --- Small UI helpers (unchanged) ---
class _AvailabilitySwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _AvailabilitySwitch({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 314,
      height: 44,
      decoration: BoxDecoration(
        color: const Color(0xffE2E2E2),
        borderRadius: BorderRadius.circular(40),
        boxShadow: const [
          BoxShadow(
            color: Color(0x40000000),
            blurRadius: 4,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            alignment: value ? Alignment.centerLeft : Alignment.centerRight,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            child: Container(
              width: 157,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xff710E1D),
                borderRadius: BorderRadius.circular(40),
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => onChanged(true),
                  child: Center(
                    child: Text(
                      "Available",
                      style: TextStyle(
                        color: value ? Colors.white : Colors.black,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => onChanged(false),
                  child: Center(
                    child: Text(
                      "Not available",
                      style: TextStyle(
                        color: !value ? Colors.white : Colors.black,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LabeledField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String hint;
  final bool isPrice;
  final int maxLines;

  const _LabeledField({
    required this.label,
    required this.controller,
    required this.hint,
    this.isPrice = false,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
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
            controller: controller,
            maxLines: maxLines,
            keyboardType: isPrice ? TextInputType.number : TextInputType.text,
            decoration: InputDecoration(
              prefixIcon: isPrice
                  ? const Padding(
                      padding: EdgeInsets.fromLTRB(20, 0, 0, 2),
                      child: Text(
                        "₱ ",
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 16,
                          fontFamily: 'Arial',
                        ),
                      ),
                    )
                  : null,
              prefixIconConstraints: isPrice
                  ? const BoxConstraints(minWidth: 0, minHeight: 0)
                  : null,
              hintText: hint,
              hintStyle: const TextStyle(
                color: Color(0x40000000),
                fontSize: 14,
              ),
              border: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
              focusedBorder: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
                borderSide: BorderSide(color: Colors.black, width: 1),
              ),
              contentPadding: const EdgeInsets.symmetric(
                vertical: 12,
                horizontal: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
