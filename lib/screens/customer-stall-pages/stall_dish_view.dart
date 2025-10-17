/*
  File: stall_dish_view.dart
  Purpose: Displays detailed information about a selected dish, including its 
           image, price, description, and food tags fetched from Supabase.
  Developers: Magat, Maria Josephine M. [jsphnmgt]
              Pineda, Mary Alexa Ysabelle V. [hrspnd]
*/

import 'package:flutter/material.dart';
import '../store_roof.dart';
import '../../models/stalls_model.dart';
import '../../models/menu_item.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  final _supabase = Supabase.instance.client;

  // ==================== BACK END ==================== //
  bool _tagsLoading = true;
  List<Map<String, dynamic>> _dishTags =
      []; // each: {'label': String, 'color': Color?}

  // Fallback colors
  final Map<String, Color> _TAG_COLORS = {
    'Beef': Color(0xff8B4513),
    'Chicken': Color(0xffFFA726),
    'Fish': Color(0xff76C7C0),
    'Pork': Color(0xffF28B82),
    'Salty': Color(0xff90A4AE),
    'Savory': Color(0xffA1887F),
    'Seafood': Color(0xff0277BD),
    'Soup': Color(0xffBDBDBD),
    'Sour': Color(0xffFFD966),
    'Spicy': Color(0xffE53935),
    'Sweet': Color(0xffF48FB1),
    'Vegetable': Color(0xff81C784),
  };

  Future<void> _loadDishTags() async {
    setState(() => _tagsLoading = true);
    try {
      final dishId = widget.dish.id;
      final rows = await _supabase
          .from('DishTags')
          .select('tag_id, Tags(name)')
          .eq('dish_id', dishId);

      final list = (rows as List).map<Map<String, dynamic>>((r) {
        final t = r['Tags'] as Map<String, dynamic>?;
        final label = (t?['name'] as String?)?.trim() ?? '';
        final color = _TAG_COLORS[label] ?? const Color(0xff710E1D);
        return {'label': label, 'color': color};
      }).toList();

      setState(() {
        _dishTags = list;
        _tagsLoading = false;
      });
    } catch (e) {
      // If it fails, just show nothing instead of crashing
      setState(() {
        _dishTags = [];
        _tagsLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    isFavorited = widget.stall.isFavorited;
    _loadDishTags();
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
          // Scrollable content
          Positioned.fill(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(top: roofHeight - 10),
              child: Column(
                children: [
                  // Stall Info Section
                  SizedBox(
                    width: 280,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Center(
                        child: Column(
                          children: [
                            AutoSizeText(
                              widget.stall.stallName,
                              style: const TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              minFontSize: 22,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Transform.translate(
                              offset: Offset(0, -6),
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
                              child:
                                  (widget.dish.imageUrl != null &&
                                      widget.dish.imageUrl!.isNotEmpty)
                                  ? Image.network(
                                      widget.dish.imageUrl!,
                                      fit: BoxFit.cover,
                                    )
                                  : Image.asset(
                                      'assets/png/image-square.png',
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
                              child: SizedBox(
                                width: 180,
                                child: AutoSizeText(
                                  widget.dish.dishName,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w400,
                                  ),
                                  maxLines: 1,
                                  minFontSize: 20,
                                  overflow: TextOverflow.ellipsis,
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
                              widget.dish.description ?? '',
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
                                // Line above "Food Tags"
                                Container(
                                  width: 300,
                                  height: 1,
                                  color: const Color(0xFFC5C5C5),
                                  margin: const EdgeInsets.only(bottom: 8),
                                ),

                                // Title
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

                                // Tag list (one per line)
                                Builder(
                                  builder: (_) {
                                    if (_tagsLoading) {
                                      return const Padding(
                                        padding: EdgeInsets.symmetric(
                                          vertical: 8,
                                        ),
                                        child: Center(
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        ),
                                      );
                                    }
                                    if (_dishTags.isEmpty) {
                                      return const Padding(
                                        padding: EdgeInsets.symmetric(
                                          vertical: 20,
                                        ),
                                        child: Center(
                                          child: Text(
                                            'No listed tags.',
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.black54,
                                              fontWeight: FontWeight.w500,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      );
                                    }

                                    return Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        for (
                                          int i = 0;
                                          i < _dishTags.length;
                                          i++
                                        ) ...[
                                          _buildTag(
                                            _dishTags[i]['label'] as String,
                                            (_dishTags[i]['color'] as Color?) ??
                                                const Color(0xff710E1D),
                                          ),
                                          if (i != _dishTags.length - 1)
                                            const SizedBox(height: 10),
                                        ],
                                      ],
                                    );
                                  },
                                ),
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
