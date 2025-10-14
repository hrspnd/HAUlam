import 'package:flutter/material.dart';
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

  // tags UI stays as-is (not stored in DB table)
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

    // Build payload matching your Dishes table columns
    final payload = {
      'dish_name': _dishNameController.text.trim(),
      'description': _descriptionController.text.trim(),
      'price': double.tryParse(_priceController.text.trim()) ?? 0.0,
      'available': isAvailable,
      'image_url': imageUrl ?? '',
      // NOTE: tags not stored in Dishes table; persist elsewhere if needed
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

  // ===== Your tag selector stays unchanged =====
  void _openTagSelector() { /* ... keep your existing code ... */ }

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

                    // ===== Image Box =====
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
                                icon: const Icon(Icons.add_a_photo, size: 22, color: Color.fromARGB(255, 109, 109, 109)),
                                onPressed: () {
                                  // TODO: upload to Supabase Storage, then setState(() => imageUrl = <publicUrl>);
                                },
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

                    // ===== Tags UI (not persisted in Dishes) =====
                    Align(
                      alignment: Alignment.centerLeft,
                      child: const Text("Tags", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                    ),
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: _openTagSelector,
                      child: _TagsFieldDisplay(text: selectedTags.isEmpty ? '' : selectedTags.join(', ')),
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

// --- Small UI helpers ---
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


// import 'package:flutter/material.dart';
// import '../store_roof.dart';

// class VendorEditDishPage extends StatefulWidget {
//   const VendorEditDishPage({super.key});

//   @override
//   State<VendorEditDishPage> createState() => _VendorEditDishPageState();
// }

// class _VendorEditDishPageState extends State<VendorEditDishPage> {
//   bool isAvailable = true;

//   final TextEditingController _dishNameController = TextEditingController();
//   final TextEditingController _priceController = TextEditingController();
//   final TextEditingController _descriptionController = TextEditingController();
//   String? imageUrl;

//   //===========================================TAGS===========================================
//   // 🏷 Tag Data
//   List<Map<String, dynamic>> allTags = [
//     {"label": "Beef", "color": const Color(0xff8B4513)},
//     {"label": "Chicken", "color": const Color(0xffFFA726)},
//     {"label": "Fish", "color": const Color(0xff76C7C0)},
//     {"label": "Pork", "color": const Color(0xffF28B82)},
//     {"label": "Salty", "color": const Color(0xff90A4AE)},
//     {"label": "Savory", "color": const Color(0xffA1887F)},
//     {"label": "Seafood", "color": const Color(0xff0277BD)},
//     {"label": "Soup", "color": const Color(0xffBDBDBD)},
//     {"label": "Sour", "color": const Color(0xffFFD966)},
//     {"label": "Spicy", "color": const Color(0xffE53935)},
//     {"label": "Sweet", "color": const Color(0xffF48FB1)},
//     {"label": "Vegetable", "color": const Color(0xff81C784)},
//   ];

//   List<String> selectedTags = [];

//   // 🪄 Open Tag Selector
//   void _openTagSelector() {
//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       backgroundColor: Colors.white,
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//       ),
//       builder: (context) => StatefulBuilder(
//         builder: (context, setModalState) {
//           return Padding(
//             padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
//             child: SingleChildScrollView(
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   const Text(
//                     "Select Tags",
//                     style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
//                   ),
//                   const SizedBox(height: 16),

//                   // ==== Selected Tags ====
//                   if (selectedTags.isNotEmpty) ...[
//                     const Align(
//                       alignment: Alignment.centerLeft,
//                       child: Text(
//                         "Selected",
//                         style: TextStyle(
//                           fontWeight: FontWeight.w600,
//                           fontSize: 14,
//                         ),
//                       ),
//                     ),
//                     const SizedBox(height: 8),
//                     Wrap(
//                       spacing: 8,
//                       runSpacing: 8,
//                       children: selectedTags.map((tag) {
//                         final color =
//                             allTags.firstWhere(
//                               (t) => t["label"] == tag,
//                               orElse: () => {"color": Colors.grey},
//                             )["color"] ??
//                             Colors.grey;
//                         return Container(
//                           padding: const EdgeInsets.symmetric(
//                             horizontal: 12,
//                             vertical: 6,
//                           ),
//                           decoration: BoxDecoration(
//                             color: Colors.white,
//                             border: Border.all(
//                               color: const Color(0xff710E1D),
//                               width: 1.5,
//                             ),
//                             borderRadius: BorderRadius.circular(20),
//                           ),
//                           child: Row(
//                             mainAxisSize: MainAxisSize.min,
//                             children: [
//                               CircleAvatar(radius: 6, backgroundColor: color),
//                               const SizedBox(width: 8),
//                               Text(
//                                 tag,
//                                 style: const TextStyle(color: Colors.black),
//                               ),
//                               const SizedBox(width: 4),
//                               GestureDetector(
//                                 onTap: () {
//                                   setModalState(() => selectedTags.remove(tag));
//                                   setState(() {});
//                                 },
//                                 child: const Icon(
//                                   Icons.close,
//                                   size: 16,
//                                   color: Colors.black54,
//                                 ),
//                               ),
//                             ],
//                           ),
//                         );
//                       }).toList(),
//                     ),
//                     const SizedBox(height: 16),
//                   ],

//                   // ==== Unselected Tags ====
//                   const Align(
//                     alignment: Alignment.centerLeft,
//                     child: Text(
//                       "Select more",
//                       style: TextStyle(
//                         fontWeight: FontWeight.w600,
//                         fontSize: 14,
//                       ),
//                     ),
//                   ),
//                   const SizedBox(height: 8),
//                   Wrap(
//                     spacing: 8,
//                     runSpacing: 8,
//                     children: allTags
//                         .where((tag) => !selectedTags.contains(tag["label"]))
//                         .map((tag) {
//                           final color = tag["color"] as Color;
//                           return GestureDetector(
//                             onTap: () {
//                               setModalState(
//                                 () => selectedTags.add(tag["label"]),
//                               );
//                               setState(() {});
//                             },
//                             child: Container(
//                               padding: const EdgeInsets.symmetric(
//                                 horizontal: 12,
//                                 vertical: 6,
//                               ),
//                               decoration: BoxDecoration(
//                                 color: Colors.white,
//                                 border: Border.all(
//                                   color: const Color(0xff710E1D),
//                                   width: 1.5,
//                                 ),
//                                 borderRadius: BorderRadius.circular(20),
//                               ),
//                               child: Row(
//                                 mainAxisSize: MainAxisSize.min,
//                                 children: [
//                                   CircleAvatar(
//                                     radius: 6,
//                                     backgroundColor: color,
//                                   ),
//                                   const SizedBox(width: 8),
//                                   Text(
//                                     tag["label"],
//                                     style: const TextStyle(
//                                       color: Colors.black,
//                                       fontSize: 14,
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           );
//                         })
//                         .toList(),
//                   ),
//                   const SizedBox(height: 24),

//                   // ==== Done Button ====
//                   SizedBox(
//                     width: double.infinity,
//                     child: ElevatedButton(
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: const Color(0xff710E1D),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                         padding: const EdgeInsets.symmetric(vertical: 12),
//                       ),
//                       onPressed: () => Navigator.pop(context),
//                       child: const Text(
//                         "Done",
//                         style: TextStyle(color: Colors.white, fontSize: 16),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           );
//         },
//       ),
//     );
//   }
//   //===========================================TAGS===========================================

//   void _saveDish() {
//     final dishData = {
//       "isAvailable": isAvailable,
//       "dishName": _dishNameController.text,
//       "price": _priceController.text,
//       "description": _descriptionController.text,
//       "tags": selectedTags,
//       "imageUrl": imageUrl ?? "",
//     };

//     // 👇 BACKEND CODE HERE
//     // TODO: Use Supabase to insert/update dish data
//     print("Dish Data to Save: $dishData");
//   }

//   @override
//   Widget build(BuildContext context) {
//     final screenWidth = MediaQuery.of(context).size.width;
//     final roofHeight = screenWidth * 0.48;

//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: Stack(
//         children: [
//           Positioned.fill(
//             child: SingleChildScrollView(
//               padding: EdgeInsets.only(top: roofHeight - 40),
//               child: Padding(
//                 padding: const EdgeInsets.fromLTRB(20, 30, 20, 60),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.center,
//                   children: [
//                     const Text(
//                       "KIRSTENJOY",
//                       style: TextStyle(
//                         fontSize: 30,
//                         fontWeight: FontWeight.w700,
//                       ),
//                     ),
//                     Transform.translate(
//                       offset: Offset(0, -8),
//                       child: Text(
//                         "Admin View",
//                         style: TextStyle(
//                           fontSize: 20,
//                           fontWeight: FontWeight.w500,
//                         ),
//                       ),
//                     ),
//                     const SizedBox(height: 20),

//                     // ===== Image Upload Box =====
//                     Transform.translate(
//                       offset: Offset(0, -20),
//                       child: Stack(
//                         clipBehavior: Clip.none,
//                         alignment: Alignment.center,
//                         children: [
//                           Container(
//                             width: 280,
//                             height: 220,
//                             decoration: BoxDecoration(
//                               border: Border.all(
//                                 color: const Color(0xff710E1D),
//                                 width: 4,
//                               ),
//                               borderRadius: BorderRadius.circular(12),
//                             ),
//                             child: ClipRRect(
//                               borderRadius: BorderRadius.circular(12),
//                               child: imageUrl == null || imageUrl!.isEmpty
//                                   ? Image.asset(
//                                       "assets/png/image-rectangle.png",
//                                       fit: BoxFit.cover,
//                                     )
//                                   : Image.network(imageUrl!, fit: BoxFit.cover),
//                             ),
//                           ),
//                           Positioned(
//                             bottom: -8,
//                             right: -8,
//                             child: Container(
//                               width: 50,
//                               height: 50,
//                               decoration: BoxDecoration(
//                                 shape: BoxShape.circle,
//                                 border: Border.all(
//                                   color: const Color(0xff710E1D),
//                                   width: 4,
//                                 ),
//                                 color: const Color(0xffE2E2E2),
//                               ),
//                               child: IconButton(
//                                 icon: const Icon(
//                                   Icons.add_a_photo,
//                                   size: 22,
//                                   color: Color.fromARGB(255, 109, 109, 109),
//                                 ),
//                                 onPressed: () {
//                                   // TODO: Upload image to Supabase storage
//                                 },
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                     const SizedBox(height: 12),

//                     // ===== Availability Toggle =====
//                     Container(
//                       width: 314,
//                       height: 44,
//                       decoration: BoxDecoration(
//                         color: const Color(0xffE2E2E2),
//                         borderRadius: BorderRadius.circular(40),
//                         boxShadow: [
//                           BoxShadow(
//                             color: Color(0x40000000),
//                             blurRadius: 4,
//                             offset: Offset(0, 4),
//                           ),
//                         ],
//                       ),
//                       child: Stack(
//                         children: [
//                           AnimatedAlign(
//                             alignment: isAvailable
//                                 ? Alignment.centerLeft
//                                 : Alignment.centerRight,
//                             duration: const Duration(milliseconds: 250),
//                             curve: Curves.easeInOut,
//                             child: Container(
//                               width: 157,
//                               height: 44,
//                               decoration: BoxDecoration(
//                                 color: const Color(0xff710E1D),
//                                 borderRadius: BorderRadius.circular(40),
//                               ),
//                             ),
//                           ),
//                           Row(
//                             children: [
//                               Expanded(
//                                 child: GestureDetector(
//                                   onTap: () =>
//                                       setState(() => isAvailable = true),
//                                   child: Center(
//                                     child: Text(
//                                       "Available",
//                                       style: TextStyle(
//                                         color: isAvailable
//                                             ? Colors.white
//                                             : Colors.black,
//                                         fontSize: 14,
//                                         fontWeight: FontWeight.w600,
//                                       ),
//                                     ),
//                                   ),
//                                 ),
//                               ),
//                               Expanded(
//                                 child: GestureDetector(
//                                   onTap: () =>
//                                       setState(() => isAvailable = false),
//                                   child: Center(
//                                     child: Text(
//                                       "Not available",
//                                       style: TextStyle(
//                                         color: !isAvailable
//                                             ? Colors.white
//                                             : Colors.black,
//                                         fontSize: 14,
//                                         fontWeight: FontWeight.w600,
//                                       ),
//                                     ),
//                                   ),
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ],
//                       ),
//                     ),
//                     const SizedBox(height: 25),

//                     // ===== Dish Name =====
//                     Align(
//                       alignment: Alignment.centerLeft,
//                       child: const Text(
//                         "Dish Name",
//                         style: TextStyle(
//                           fontSize: 14,
//                           fontWeight: FontWeight.w500,
//                         ),
//                       ),
//                     ),
//                     const SizedBox(height: 6),
//                     Container(
//                       height: 44,
//                       width: 314,
//                       decoration: BoxDecoration(
//                         color: Colors.white,
//                         borderRadius: BorderRadius.circular(12),
//                         boxShadow: [
//                           BoxShadow(
//                             color: Color(0x20000000),
//                             blurRadius: 4,
//                             offset: Offset(0, 4),
//                           ),
//                         ],
//                       ),
//                       child: TextField(
//                         controller: _dishNameController,
//                         style: const TextStyle(
//                           color: Colors.black,
//                           fontSize: 14,
//                         ),
//                         decoration: const InputDecoration(
//                           hintText: "Enter dish name",
//                           hintStyle: TextStyle(
//                             color: Color(0x40000000),
//                             fontSize: 14,
//                           ),
//                           border: OutlineInputBorder(
//                             borderRadius: BorderRadius.all(Radius.circular(12)),
//                           ),
//                           focusedBorder: OutlineInputBorder(
//                             borderRadius: BorderRadius.all(Radius.circular(12)),
//                             borderSide: BorderSide(
//                               color: Colors.black,
//                               width: 1,
//                             ),
//                           ),
//                           contentPadding: EdgeInsets.symmetric(
//                             vertical: 12,
//                             horizontal: 16,
//                           ),
//                         ),
//                       ),
//                     ),
//                     const SizedBox(height: 16),

//                     // ===== Price =====
//                     Align(
//                       alignment: Alignment.centerLeft,
//                       child: const Text(
//                         "Price",
//                         style: TextStyle(
//                           fontSize: 14,
//                           fontWeight: FontWeight.w500,
//                         ),
//                       ),
//                     ),
//                     const SizedBox(height: 6),
//                     Container(
//                       height: 44,
//                       width: 314,
//                       decoration: BoxDecoration(
//                         color: Colors.white,
//                         borderRadius: BorderRadius.circular(12),
//                         boxShadow: const [
//                           BoxShadow(
//                             color: Color(0x20000000),
//                             blurRadius: 4,
//                             offset: Offset(0, 4),
//                           ),
//                         ],
//                       ),
//                       child: TextField(
//                         controller: _priceController,
//                         keyboardType: TextInputType.number,
//                         style: const TextStyle(
//                           color: Colors.black,
//                           fontSize: 14,
//                         ),
//                         decoration: InputDecoration(
//                           prefixIcon: Padding(
//                             padding: const EdgeInsets.fromLTRB(20, 0, 0, 2),
//                             child: Text(
//                               "₱ ",
//                               style: const TextStyle(
//                                 color: Colors.black,
//                                 fontSize: 16,
//                                 fontFamily: 'Arial',
//                               ),
//                             ),
//                           ),
//                           prefixIconConstraints: const BoxConstraints(
//                             minWidth: 0,
//                             minHeight: 0,
//                           ),
//                           hintText: "Enter price",
//                           hintStyle: const TextStyle(
//                             color: Color(0x40000000),
//                             fontSize: 14,
//                           ),
//                           border: const OutlineInputBorder(
//                             borderRadius: BorderRadius.all(Radius.circular(12)),
//                           ),
//                           focusedBorder: const OutlineInputBorder(
//                             borderRadius: BorderRadius.all(Radius.circular(12)),
//                             borderSide: BorderSide(
//                               color: Colors.black,
//                               width: 1,
//                             ),
//                           ),
//                           contentPadding: const EdgeInsets.symmetric(
//                             vertical: 12,
//                             horizontal: 16,
//                           ),
//                         ),
//                       ),
//                     ),
//                     const SizedBox(height: 16),

//                     // ===== Description =====
//                     Align(
//                       alignment: Alignment.centerLeft,
//                       child: const Text(
//                         "Description",
//                         style: TextStyle(
//                           fontSize: 14,
//                           fontWeight: FontWeight.w500,
//                         ),
//                       ),
//                     ),
//                     const SizedBox(height: 6),
//                     Container(
//                       width: 314,
//                       decoration: BoxDecoration(
//                         color: Colors.white,
//                         borderRadius: BorderRadius.circular(12),
//                         boxShadow: [
//                           BoxShadow(
//                             color: Color(0x20000000),
//                             blurRadius: 4,
//                             offset: Offset(0, 4),
//                           ),
//                         ],
//                       ),
//                       child: TextField(
//                         controller: _descriptionController,
//                         style: const TextStyle(
//                           color: Colors.black,
//                           fontSize: 14,
//                         ),
//                         maxLines: 3,
//                         decoration: const InputDecoration(
//                           hintText: "Add description",
//                           hintStyle: TextStyle(
//                             color: Color(0x40000000),
//                             fontSize: 14,
//                           ),
//                           border: OutlineInputBorder(
//                             borderRadius: BorderRadius.all(Radius.circular(12)),
//                           ),
//                           focusedBorder: OutlineInputBorder(
//                             borderRadius: BorderRadius.all(Radius.circular(12)),
//                             borderSide: BorderSide(
//                               color: Colors.black,
//                               width: 1,
//                             ),
//                           ),
//                           contentPadding: EdgeInsets.symmetric(
//                             vertical: 12,
//                             horizontal: 16,
//                           ),
//                         ),
//                       ),
//                     ),
//                     const SizedBox(height: 16),

//                     //=================================TAGS=========================
//                     Align(
//                       alignment: Alignment.centerLeft,
//                       child: const Text(
//                         "Tags",
//                         style: TextStyle(
//                           fontSize: 14,
//                           fontWeight: FontWeight.w500,
//                         ),
//                       ),
//                     ),
//                     const SizedBox(height: 6),
//                     Container(
//                       width: 314,
//                       decoration: BoxDecoration(
//                         color: Colors.white,
//                         borderRadius: BorderRadius.circular(12),
//                         boxShadow: [
//                           BoxShadow(
//                             color: const Color(0x20000000),
//                             blurRadius: 4,
//                             offset: const Offset(0, 4),
//                           ),
//                         ],
//                       ),
//                       child: TextField(
//                         readOnly: true,
//                         onTap: _openTagSelector,
//                         controller: TextEditingController(
//                           text: selectedTags.isEmpty
//                               ? ""
//                               : selectedTags.join(", "),
//                         ),
//                         style: const TextStyle(
//                           color: Colors.black,
//                           fontSize: 14,
//                         ),
//                         decoration: InputDecoration(
//                           hintText: "Select tags",
//                           hintStyle: const TextStyle(
//                             color: Color(0x40000000),
//                             fontSize: 14,
//                           ),
//                           border: const OutlineInputBorder(
//                             borderRadius: BorderRadius.all(Radius.circular(12)),
//                           ),
//                           focusedBorder: const OutlineInputBorder(
//                             borderRadius: BorderRadius.all(Radius.circular(12)),
//                             borderSide: BorderSide(
//                               color: Colors.black,
//                               width: 1,
//                             ),
//                           ),
//                           contentPadding: const EdgeInsets.symmetric(
//                             vertical: 12,
//                             horizontal: 16,
//                           ),

//                           suffixIcon: const Icon(
//                             Icons.arrow_drop_down,
//                             color: Colors.black,
//                             size: 28,
//                           ),
//                         ),
//                       ),
//                     ),

//                     //=================================TAGS=========================
//                     const SizedBox(height: 30),

//                     // ===== Save Button =====
//                     GestureDetector(
//                       onTap: () {
//                         _saveDish();
//                       },
//                       child: Container(
//                         width: 318,
//                         height: 46,
//                         decoration: BoxDecoration(
//                           color: const Color(0xff710E1D),
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                         child: const Center(
//                           child: Text(
//                             "Create",
//                             style: TextStyle(
//                               color: Colors.white,
//                               fontSize: 16,
//                               fontWeight: FontWeight.w600,
//                             ),
//                           ),
//                         ),
//                       ),
//                     ),
//                     const SizedBox(height: 15),

//                     GestureDetector(
//                       onTap: () {
//                         showDialog(
//                           context: context,
//                           barrierDismissible: true, // allow tapping outside
//                           builder: (context) => Dialog(
//                             shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(25),
//                             ),
//                             backgroundColor: Colors.white,
//                             child: Padding(
//                               padding: const EdgeInsets.all(20),
//                               child: Column(
//                                 mainAxisSize: MainAxisSize.min,
//                                 crossAxisAlignment: CrossAxisAlignment.start,
//                                 children: [
//                                   const Text(
//                                     "Delete Stall?",
//                                     style: TextStyle(
//                                       fontSize: 18,
//                                       fontWeight: FontWeight.w600,
//                                       color: Colors.black,
//                                     ),
//                                   ),
//                                   const SizedBox(height: 10),
//                                   const Text(
//                                     "Are you sure you want to delete this stall? This action cannot be undone.",
//                                     style: TextStyle(
//                                       fontSize: 11,
//                                       color: Colors.black,
//                                     ),
//                                   ),
//                                   const SizedBox(height: 6),

//                                   // Divider
//                                   const Divider(
//                                     color: Colors.grey,
//                                     thickness: 1,
//                                   ),

//                                   const SizedBox(height: 6),
//                                   Row(
//                                     mainAxisAlignment: MainAxisAlignment.end,
//                                     children: [
//                                       // Cancel button
//                                       TextButton(
//                                         onPressed: () {
//                                           Navigator.pop(context);
//                                         },
//                                         child: const Text(
//                                           "Cancel",
//                                           style: TextStyle(
//                                             fontSize: 14,
//                                             fontWeight: FontWeight.normal,
//                                             color: Colors.black,
//                                           ),
//                                         ),
//                                       ),
//                                       const SizedBox(width: 10),

//                                       ElevatedButton(
//                                         onPressed: () {
//                                           Navigator.pop(context);
//                                         },
//                                         style: ElevatedButton.styleFrom(
//                                           backgroundColor: const Color(
//                                             0xff65000F,
//                                           ),
//                                           shape: RoundedRectangleBorder(
//                                             borderRadius: BorderRadius.circular(
//                                               12,
//                                             ),
//                                           ),
//                                           padding: const EdgeInsets.symmetric(
//                                             horizontal: 20,
//                                             vertical: 10,
//                                           ),
//                                         ),
//                                         child: const Text(
//                                           "Confirm",
//                                           style: TextStyle(
//                                             fontSize: 14,
//                                             color: Colors.white,
//                                             fontWeight: FontWeight.bold,
//                                           ),
//                                         ),
//                                       ),
//                                     ],
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           ),
//                         );
//                       },
//                       child: const Text(
//                         "Tap here to delete.",
//                         style: TextStyle(
//                           color: Color(0xff710E1D),
//                           fontSize: 12,
//                           fontWeight: FontWeight.w500,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//           const Positioned(top: 0, left: 0, right: 0, child: StoreRoof()),
//           Positioned(
//             top: 45,
//             left: 12,
//             child: Container(
//               width: 30,
//               height: 30,
//               decoration: const BoxDecoration(
//                 color: Colors.white,
//                 shape: BoxShape.circle,
//               ),
//               child: IconButton(
//                 icon: const Icon(
//                   Icons.arrow_back,
//                   color: Colors.black,
//                   size: 22,
//                 ),
//                 padding: EdgeInsets.zero,
//                 constraints: const BoxConstraints(),
//                 onPressed: () => Navigator.pop(context),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
