import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../store_roof.dart';

final supabase = Supabase.instance.client;

class VendorEditDishPage extends StatefulWidget {
  // pass the dish row from Supabase
  final Map<String, dynamic> dish;

  const VendorEditDishPage({super.key, required this.dish});

  @override
  State<VendorEditDishPage> createState() => _VendorEditDishPageState();
}

class _VendorEditDishPageState extends State<VendorEditDishPage> {
  bool isAvailable = true;

  final TextEditingController _dishNameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  String? imageUrl;

  // ====== NEW: image picker ======
  final ImagePicker _picker = ImagePicker();
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    // ✅ Prefill from the dish row
    final d = widget.dish;
    _dishNameController.text = (d['dish_name'] ?? '').toString();
    _descriptionController.text = (d['description'] ?? '').toString();
    _priceController.text = (d['price'] ?? '').toString();
    isAvailable = (d['available'] as bool?) ?? true;
    imageUrl = (d['image_url'] as String?) ?? '';
  }

  // ---- SAVE (UPDATE) ----
  Future<void> _saveDish() async {
    final id = widget.dish['id'];
    if (id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Missing dish id')),
      );
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
      await supabase.from('Dishes').update(payload).eq('id', id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dish updated')),
      );
      Navigator.pop(context, true); // return to list and refresh
    } on PostgrestException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Supabase error: ${e.message}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unexpected error: $e')),
      );
    }
  }

  // ====== NEW: same image logic as Create Dish ======
  Future<void> _pickAndUploadImage() async {
    try {
      final file = await _picker.pickImage(source: ImageSource.gallery);
      if (file == null) return;

      setState(() => _uploading = true);

      final bytes = await file.readAsBytes();
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';

      // upload to the same bucket you used in Create Dish
      await supabase.storage.from('dishimages').uploadBinary(fileName, bytes);

      final url =
          supabase.storage.from('dishimages').getPublicUrl(fileName);

      setState(() {
        imageUrl = url;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload error: $e')),
      );
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  // ====== Your tag selector stays unchanged ======
  void _openTagSelector() {/* your existing code if you add tags later */ }

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
                      style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700),
                    ),
                    Transform.translate(
                      offset: const Offset(0, -8),
                      child: const Text(
                        "Admin View",
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ===== Image Box (same behavior as Create Dish) =====
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
                              border: Border.all(color: const Color(0xff710E1D), width: 4),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: (imageUrl == null || imageUrl!.isEmpty)
                                  ? Image.asset("assets/png/image-rectangle.png", fit: BoxFit.cover)
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
                                border: Border.all(color: const Color(0xff710E1D), width: 4),
                                color: const Color(0xffE2E2E2),
                              ),
                              child: IconButton(
                                icon: _uploading
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : const Icon(
                                        Icons.add_a_photo,
                                        size: 22,
                                        color: Color.fromARGB(255, 109, 109, 109),
                                      ),
                                onPressed: _uploading ? null : _pickAndUploadImage,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // ===== Availability Toggle =====
                    _AvailabilitySwitch(
                      value: isAvailable,
                      onChanged: (v) => setState(() => isAvailable = v),
                    ),
                    const SizedBox(height: 25),

                    // ===== Dish Name =====
                    _LabeledField(
                      label: 'Dish Name',
                      controller: _dishNameController,
                      hint: 'Enter dish name',
                    ),
                    const SizedBox(height: 16),

                    // ===== Price =====
                    _LabeledField(
                      label: 'Price',
                      controller: _priceController,
                      hint: 'Enter price',
                      isPrice: true,
                    ),
                    const SizedBox(height: 16),

                    // ===== Description =====
                    _LabeledField(
                      label: 'Description',
                      controller: _descriptionController,
                      hint: 'Add description',
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),

                    // ===== Tags UI placeholder (not persisted here) =====
                    Align(
                      alignment: Alignment.centerLeft,
                      child: const Text("Tags", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                    ),
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: _openTagSelector,
                      child: const _TagsFieldDisplay(text: ''),
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
                            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
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
              width: 30, height: 30, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black, size: 22),
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
        boxShadow: const [BoxShadow(color: Color(0x40000000), blurRadius: 4, offset: Offset(0, 4))],
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            alignment: value ? Alignment.centerLeft : Alignment.centerRight,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            child: Container(width: 157, height: 44, decoration: BoxDecoration(color: const Color(0xff710E1D), borderRadius: BorderRadius.circular(40))),
          ),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => onChanged(true),
                  child: Center(
                    child: Text(
                      "Available",
                      style: TextStyle(color: value ? Colors.white : Colors.black, fontSize: 14, fontWeight: FontWeight.w600),
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
                      style: TextStyle(color: !value ? Colors.white : Colors.black, fontSize: 14, fontWeight: FontWeight.w600),
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
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        Container(
          width: 314,
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: const [BoxShadow(color: Color(0x20000000), blurRadius: 4, offset: Offset(0, 4))]),
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            keyboardType: isPrice ? TextInputType.number : TextInputType.text,
            decoration: InputDecoration(
              prefixIcon: isPrice
                  ? const Padding(
                      padding: EdgeInsets.fromLTRB(20, 0, 0, 2),
                      child: Text("₱ ", style: TextStyle(color: Colors.black, fontSize: 16, fontFamily: 'Arial')),
                    )
                  : null,
              prefixIconConstraints: isPrice ? const BoxConstraints(minWidth: 0, minHeight: 0) : null,
              hintText: hint,
              hintStyle: const TextStyle(color: Color(0x40000000), fontSize: 14),
              border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
              focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)), borderSide: BorderSide(color: Colors.black, width: 1)),
              contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            ),
          ),
        ),
      ],
    );
  }
}

class _TagsFieldDisplay extends StatelessWidget {
  final String text;
  const _TagsFieldDisplay({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 314,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: const [BoxShadow(color: Color(0x20000000), blurRadius: 4, offset: Offset(0, 4))]),
      child: TextField(
        readOnly: true,
        controller: TextEditingController(text: text),
        decoration: const InputDecoration(
          hintText: "Select tags",
          hintStyle: TextStyle(color: Color(0x40000000), fontSize: 14),
          border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)), borderSide: BorderSide(color: Colors.black, width: 1)),
          contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          suffixIcon: Icon(Icons.arrow_drop_down, color: Colors.black, size: 28),
        ),
      ),
    );
  }
}
