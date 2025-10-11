import 'package:flutter/material.dart';
import '../store_roof.dart';
import '../models/stalls_model.dart';
import '../models/menu_item.dart';

class StallDishViewPage extends StatefulWidget {
  final Stall stall;
  final MenuItem dish;

  const StallDishViewPage({super.key, required this.stall, required this.dish});

  @override
  State<StallDishViewPage> createState() => _StallDishViewPageState();
}

// === Tag Widget ===
Widget _buildTag(String label, Color dotColor) {
  return Center(
    child: Container(
      width: 266, // full width tag
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Color(0xff710E1D), width: 1.4),
        color: const Color(0xFFF9F9F9), // light background, no outline
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    ),
  );
}

class _StallDishViewPageState extends State<StallDishViewPage> {
  late bool isFavorited;

  @override
  void initState() {
    super.initState();
    isFavorited = widget.stall.isFavorited;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final roofHeight = screenWidth * 0.48;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Scrollable content
          Positioned.fill(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(top: roofHeight - 10),
              child: Column(
                children: [
                  // Stall Info Section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Column(
                      children: [
                        Text(
                          widget.stall.title,
                          style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Transform.translate(
                          offset: Offset(0, -10),
                          child: Text(
                            widget.stall.location,
                            style: const TextStyle(
                              fontSize: 20,
                              color: Colors.black,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),

                  // details section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // === Image ===
                        Transform.translate(
                          offset: const Offset(0, -16),
                          child: Container(
                            width: 290,
                            height: 225,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: const Color(0xFF710E1D),
                                width: 5,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x30313131),
                                  blurRadius: 6,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.asset(
                                widget.dish.imagePath,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // === Dish Name and Price ===
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Transform.translate(
                              offset: Offset(30, -26),
                              child: Text(
                                widget.dish.name,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Transform.translate(
                                  offset: Offset(-30, -20),
                                  child: Text(
                                    "₱${widget.dish.price.toStringAsFixed(0)}",
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontFamily: 'Arial',
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ),
                                Transform.translate(
                                  offset: Offset(-30, -26),
                                  child: const Text(
                                    "Base Price",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Color(0xffB5B5B5),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // === Description ===
                        Transform.translate(
                          offset: Offset(0, -28),
                          child: SizedBox(
                            width: 260,
                            child: Text(
                              widget.dish.description,
                              textAlign: TextAlign.justify,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),

                        // === Food Tags Section ===
                        Transform.translate(
                          offset: const Offset(0, -30),
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // 🔹 Line above "Food Tags"
                                Container(
                                  width: 300,
                                  height: 1,
                                  color: const Color(0xFFC5C5C5),
                                  margin: const EdgeInsets.only(bottom: 8),
                                ),

                                // 🔹 Title
                                Transform.translate(
                                  offset: Offset(18, 0),
                                  child: const Text(
                                    "Food Tags",
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),

                                // 🔹 Tag list (one per line)
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildTag("Pork", const Color(0xffF28B82)),
                                    const SizedBox(height: 10),
                                    _buildTag("Spicy", const Color(0xffE53935)),
                                    const SizedBox(height: 10),
                                    _buildTag("Sour", const Color(0xffFFD966)),
                                  ],
                                ),

                                // ============================================================
                                // BACKEND NOTE (for later when connected to Supabase)
                                // Replace the static Column above with a FutureBuilder that:
                                //   1. Fetches tags from your 'food_tags' table
                                //      Example: final response = await supabase.from('food_tags').select();
                                //   2. Maps through the results and builds each tag using _buildTag(label, color).
                                // ============================================================
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),

          // Roof Header (Top)
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
