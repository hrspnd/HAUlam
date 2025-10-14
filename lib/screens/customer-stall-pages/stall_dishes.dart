/*

LATEST COMMIT October 14


*/

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:haulam/screens/customer-stall-pages/stall_dish_view.dart';
import '../store_roof.dart';
import '../../models/stalls_model.dart';
import '../../models/menu_item.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

class StallDishesPage extends StatefulWidget {
  final Stall stall;

  const StallDishesPage({super.key, required this.stall});

  @override
  State<StallDishesPage> createState() => _StallDishesPageState();
}

class _StallDishesPageState extends State<StallDishesPage> {
  bool _bookmarkBusy = false;

  late bool isFavorited;
  bool isFilterOpen = false;
  static const List<String> _defaultFixed = ["Beef", "Chicken"];

  List<String> _getVisibleTagLabels() {
    if (selectedFilters.isEmpty) {
      return _defaultFixed;
    }

    final int len = selectedFilters.length;
    final List<String> lastTwo = len >= 2
        ? selectedFilters.sublist(len - 2)
        : [selectedFilters.last];

    if (lastTwo.length == 2) return lastTwo;

    final String only = lastTwo.first;
    final String fallback = _defaultFixed.firstWhere(
      (d) => d != only,
      orElse: () => _defaultFixed.first,
    );
    return [only, fallback];
  }

  List<Widget> _buildVisibleTags() {
    final labels = _getVisibleTagLabels();
    return labels.map((l) => _buildFixedChoiceTag(l)).toList();
  }

  List<String> selectedFilters = [];

  final List<Map<String, dynamic>> filters = [
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

  List<MenuItem> menuItems = [];
  bool loading = true;

  Future<void> _loadDishes() async {
    try {
      final rows = await supabase
          .from('Dishes')
          .select()
          .eq('stall_id', widget.stall.id);

      setState(() {
        menuItems = (rows as List)
            .map((e) => MenuItem.fromMap(e as Map<String, dynamic>))
            .toList();
        loading = false;
      });
    } catch (e) {
      // optional: handle errors
      setState(() => loading = false);
    }
  }
Future<void> _loadIsBookmarked() async {
  try {
    final user = supabase.auth.currentUser;
    if (user == null) return; // leave default

    final row = await supabase
        .from('Bookmarks')
        .select('id')
        .eq('user_id', user.id)
        .eq('stall_id', widget.stall.id)
        .maybeSingle();

    if (!mounted) return;
    setState(() {
      isFavorited = row != null;
    });
  } catch (_) {
    // ignore silently or show a lightweight toast/snackbar if you prefer
  }
}
Future<void> _toggleFavorite() async {
  if (_bookmarkBusy) return;

  final user = supabase.auth.currentUser;
  if (user == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please sign in to use bookmarks')),
    );
    return;
  }

  final newValue = !isFavorited;

  setState(() {
    _bookmarkBusy = true;
    isFavorited = newValue; // optimistic
  });

  try {
    if (newValue) {
      await supabase.from('Bookmarks').insert({
        'user_id': user.id,
        'stall_id': widget.stall.id,
      });
    } else {
      await supabase
          .from('Bookmarks')
          .delete()
          .eq('user_id', user.id)
          .eq('stall_id', widget.stall.id);
    }
  } catch (e) {
    // revert on failure
    if (!mounted) return;
    setState(() => isFavorited = !newValue);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Could not update bookmark: $e')),
    );
  } finally {
    if (!mounted) return;
    setState(() => _bookmarkBusy = false);
  }
}


  @override
  void initState() {
    super.initState();
    isFavorited = widget.stall.isFavorited;
    _loadIsBookmarked();

    _loadDishes();
  }

  void _toggleOverlay() {
    setState(() => isFilterOpen = !isFilterOpen);
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final roofHeight = screenWidth * 0.48;

    return Scaffold(
      backgroundColor: Colors.white,
      body: loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF710E1D)),
            )
          : Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.only(top: roofHeight - 30),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 20,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ===== Stall Header =====
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Transform.translate(
                                offset: const Offset(10, 0),
                                child: Container(
                                  width: 67,
                                  height: 67,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: const Color(0xFF710E1D),
                                      width: 2,
                                    ),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: (widget.stall.imagePath.isNotEmpty)
                                        ? Image.network(
                                            widget.stall.imagePath,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                                  // fallback if image fails to load
                                                  return Image.asset(
                                                    'assets/png/image-square.png',
                                                    fit: BoxFit.cover,
                                                  );
                                                },
                                          )
                                        : Image.asset(
                                            'assets/png/image-square.png',
                                            fit: BoxFit.cover,
                                          ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              SizedBox(
                                width: 210,
                                height: 80,
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 8, top: 2),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      SizedBox(
                                        width: 180,
                                        child: Padding(
                                        padding: const EdgeInsets.only(top: 6),
                                        child: AutoSizeText(
                                          widget.stall.stallName,
                                          style: const TextStyle(
                                            fontSize: 28,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.black,
                                          ),
                                          maxLines: 1,
                                          minFontSize: 26,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      ),
                                      Transform.translate(
                                        offset: const Offset(0, -8),
                                        child: Text(
                                          widget.stall.location,
                                          style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.black,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              // === Stall title + location with adaptive top padding ===
                              GestureDetector(
                                onTap: () =>
                                    _toggleFavorite(),
                                child: Transform.translate(
                                  offset: const Offset(-12, 0),
                                  child: Container(
                                    width: 34,
                                    height: 34,
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Color(0x50000000),
                                          offset: Offset(0, 2),
                                          blurRadius: 4,
                                          spreadRadius: 1,
                                        ),
                                      ],
                                    ),
                                    child: Center(
                                      child: SvgPicture.asset(
                                        isFavorited
                                            ? 'assets/icons/heart-red-selected.svg'
                                            : 'assets/icons/heart-red-hollow.svg',
                                        height: 24,
                                        width: 24,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 14),

                          // ===== Filter Row =====
                          Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 600),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                    width: double.infinity,
                                    child: Center(
                                      child: Wrap(
                                        alignment: WrapAlignment.center,
                                        crossAxisAlignment:
                                            WrapCrossAlignment.center,
                                        spacing: 10,
                                        runSpacing: 10,
                                        children: [
                                          _buildFilterButton(),
                                          ..._buildVisibleTags(),
                                        ],
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 12),

                                  AnimatedSize(
                                    duration: const Duration(milliseconds: 200),
                                    curve: Curves.easeInOut,
                                    child: isFilterOpen
                                        ? ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 0,
                                                  ),
                                              child: _buildDropdownFilters(),
                                            ),
                                          )
                                        : const SizedBox.shrink(),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // ===== Menu Grid =====
                          ClipRect(
                            child: Column(
                              children: [
                                Transform.translate(
                                  offset: const Offset(0, -22),
                                  child: Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      10,
                                      0,
                                      10,
                                      10,
                                    ),

                                    child: Builder(
                                      builder: (context) {
                                        // ✅ Sort dishes: available first
                                        final sortedItems = [...menuItems]
                                          ..sort((a, b) {
                                            if (a.available == b.available)
                                              return 0;
                                            return a.available
                                                ? -1
                                                : 1; // available before unavailable
                                          });

                                        // ✅ Optional: handle no dishes
                                        if (sortedItems.isEmpty) {
                                          return const Center(
                                            child: Text(
                                              'No dishes found.',
                                              style: TextStyle(
                                                fontSize: 16,
                                                color: Colors.black54,
                                              ),
                                            ),
                                          );
                                        }

                                        // ✅ The grid itself
                                        return GridView.builder(
                                          shrinkWrap: true,
                                          physics:
                                              const NeverScrollableScrollPhysics(),
                                          itemCount: sortedItems.length,
                                          gridDelegate:
                                              const SliverGridDelegateWithFixedCrossAxisCount(
                                                crossAxisCount: 2,
                                                childAspectRatio: 0.9,
                                                crossAxisSpacing: 23,
                                                mainAxisSpacing: 23,
                                              ),
                                          itemBuilder: (context, index) {
                                            final item = sortedItems[index];

                                            return GestureDetector( 
                                              onTap: () {
                                                if (!item.available) {
                                                  return;
                                                }
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (_) =>
                                                        StallDishViewPage(
                                                          stall: widget.stall,
                                                          dish: item,
                                                        ),
                                                  ),
                                                );
                                              },
                                              child: Opacity(
                                                opacity: item.available
                                                    ? 1
                                                    : 0.4,
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                    color: Colors.white,
                                                    border: Border.all(
                                                      color: const Color(
                                                        0xFF710E1D,
                                                      ),
                                                      width: 1,
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12,
                                                        ),
                                                    boxShadow: const [
                                                      BoxShadow(
                                                        color: Color(
                                                          0x25000000,
                                                        ),
                                                        offset: Offset(0, 4),
                                                        blurRadius: 4,
                                                      ),
                                                    ],
                                                  ),
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .center,
                                                    children: [
                                                      ClipRRect(
                                                        borderRadius:
                                                            const BorderRadius.only(
                                                              topLeft:
                                                                  Radius.circular(
                                                                    12,
                                                                  ),
                                                              topRight:
                                                                  Radius.circular(
                                                                    12,
                                                                  ),
                                                            ),
                                                        child:
                                                            (item.imageUrl !=
                                                                    null &&
                                                                item
                                                                    .imageUrl!
                                                                    .isNotEmpty)
                                                            ? Image.network(
                                                                item.imageUrl!,
                                                                fit: BoxFit
                                                                    .cover,
                                                                width: double
                                                                    .infinity,
                                                                height: 122,
                                                              )
                                                            : Image.asset(
                                                                'assets/png/image-square.png',
                                                                fit: BoxFit
                                                                    .cover,
                                                                width: double
                                                                    .infinity,
                                                                height: 122,
                                                              ),
                                                      ),
                                                      Container(
                                                        width: double.infinity,
                                                        height: 1,
                                                        color: const Color(
                                                          0xff710E1D,
                                                        ),
                                                      ),
                                                      Padding(
                                                        padding:
                                                            const EdgeInsets.all(
                                                              6.0,
                                                            ),
                                                        child: Text(
                                                          item.dishName,
                                                          style:
                                                              const TextStyle(
                                                                fontSize: 14,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500,
                                                              ),
                                                          textAlign:
                                                              TextAlign.center,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ],
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

  // ==== Filter Button ====
  Widget _buildFilterButton() {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: _toggleOverlay,
        child: Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFF710E1D), width: 1),
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: Color(0x25000000),
                offset: Offset(0, 4),
                blurRadius: 4,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF710E1D), width: 1),
                ),
                child: Center(
                  child: SvgPicture.asset(
                    "assets/icons/filter-button.svg",
                    width: 10,
                    height: 10,
                    color: const Color(0xFF710E1D),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                "Filter",
                style: TextStyle(fontSize: 12, color: Colors.black),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==== Dropdown Filters ====
  Widget _buildDropdownFilters() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFF710E1D), width: 1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: GridView(
        padding: EdgeInsets.zero,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 8,
          mainAxisSpacing: 2,
          mainAxisExtent: 46,
        ),
        children: filters.map((filter) {
          final String label = filter["label"] as String;
          final Color color = filter["color"] as Color;
          final bool isSelected = selectedFilters.contains(label);

          return Align(
            alignment: Alignment.center,
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      selectedFilters.remove(label);
                    } else {
                      selectedFilters.add(label);
                    }
                  });
                },
                child: SizedBox(
                  width: 135,
                  height: 33,
                  child: Container(
                    padding: const EdgeInsets.only(left: 8, right: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFF710E1D),
                        width: isSelected ? 3 : 1.2,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x25000000),
                          offset: Offset(0, 4),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ==== Fixed Choice Tag ====
  Widget _buildFixedChoiceTag(String label) {
    final color =
        (filters.firstWhere(
              (f) => f["label"] == label,
              orElse: () => {"color": const Color(0xFF710E1D)},
            )["color"]
            as Color);

    final isSelected = selectedFilters.contains(label);

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          setState(() {
            if (isSelected) {
              selectedFilters.remove(label);
            } else {
              selectedFilters.add(label);
            }
          });
        },
        child: Container(
          width: 102,
          height: 32,
          padding: const EdgeInsets.only(left: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFF710E1D),
              width: isSelected ? 3 : 1.2,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x25000000),
                offset: Offset(0, 4),
                blurRadius: 4,
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(fontSize: 12, color: Colors.black),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==== Additional Selected Tags (from dropdown) ====
  List<Widget> _buildSelectedTags() {
    final dynamicTags = selectedFilters
        .where((label) => label != "Beef" && label != "Chicken")
        .toList();

    return dynamicTags.map((label) {
      final color =
          (filters.firstWhere(
                (f) => f["label"] == label,
                orElse: () => {"color": const Color(0xFF710E1D)},
              )["color"]
              as Color);

      return Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            setState(() {
              selectedFilters.remove(label);
            });
          },
          child: Container(
            height: 32,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF710E1D), width: 2),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x25000000),
                  offset: Offset(0, 4),
                  blurRadius: 4,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  margin: const EdgeInsets.only(right: 6),
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(fontSize: 12, color: Colors.black),
                ),
              ],
            ),
          ),
        ),
      );
    }).toList();
  }
}
// */
