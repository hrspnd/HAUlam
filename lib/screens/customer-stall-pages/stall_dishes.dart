/*
  File: stall_dishes.dart
  Purpose: Displays all dishes offered by a specific stall. Includes dish filtering by tags, 
           bookmarking functionality, and Supabase integration for fetching stall dishes, tags, 
           and bookmarks.
  Developers: Magat, Maria Josephine M. [jsphnmgt]
              Pineda, Mary Alexa Ysabelle V. [hrspnd]
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
// ==================== BACK END ==================== //
  bool _bookmarkBusy = false;
  late bool isFavorited;
  bool isFilterOpen = false;
  late bool isClosed;
  static const List<String> _defaultFixed = ["Beef", "Chicken"];

  // Tag palette
  final Map<String, Color> _tagPalette = const {
    "Beef": Color(0xff8B4513),
    "Chicken": Color(0xffFFA726),
    "Fish": Color(0xff76C7C0),
    "Pork": Color(0xffF28B82),
    "Salty": Color(0xff90A4AE),
    "Savory": Color(0xffA1887F),
    "Seafood": Color(0xff0277BD),
    "Soup": Color(0xffBDBDBD),
    "Sour": Color(0xffFFD966),
    "Spicy": Color(0xffE53935),
    "Sweet": Color(0xffF48FB1),
    "Vegetable": Color(0xff81C784),
  };

  List<Map<String, dynamic>> filters = [];

  final Map<String, Set<String>> _dishTagsByDishId = {};

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

  List<MenuItem> menuItems = [];
  bool loading = true;

  Future<void> _loadFiltersFromDB() async {
    try {
      final rows = await supabase.from('Tags').select('name');
      final List data = rows as List;

      setState(() {
        filters = data.map<Map<String, dynamic>>((r) {
          final label = (r['name'] as String).trim();
          return {
            "label": label,
            "color": _tagPalette[label] ?? const Color(0xFF710E1D),
          };
        }).toList();
      });
    } catch (e) {
      setState(() {
        filters = _tagPalette.entries
            .map((e) => {"label": e.key, "color": e.value})
            .toList();
      });
    }
  }

  Future<void> _loadDishesAndTags() async {
    try {
      final dishesRes = await supabase
          .from('Dishes')
          .select('id, dish_name, price, description, image_url, available')
          .eq('stall_id', widget.stall.id);

      final tagsRes = await supabase
          .from('Dishes')
          .select('id, DishTags(tag_id, Tags(name))')
          .eq('stall_id', widget.stall.id);

      final Map<String, Set<String>> dishTags = {};
      for (final row in (tagsRes as List)) {
        final dishId = row['id'].toString();
        final List dt = (row['DishTags'] as List? ?? []);
        final tagNames = <String>{};
        for (final t in dt) {
          final tagRow = t['Tags'];
          if (tagRow != null && tagRow['name'] != null) {
            tagNames.add((tagRow['name'] as String).trim());
          }
        }
        dishTags[dishId] = tagNames;
      }

      final items = (dishesRes as List)
          .map<MenuItem>((e) => MenuItem.fromMap(Map<String, dynamic>.from(e)))
          .toList();

      setState(() {
        menuItems = items;
        _dishTagsByDishId
          ..clear()
          ..addAll(dishTags);
        loading = false;
      });
    } catch (e) {
      setState(() => loading = false);
    }
  }

  Future<void> _loadIsBookmarked() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

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
      isFavorited = newValue;
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
      if (!mounted) return;
      setState(() => isFavorited = !newValue);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not update bookmark: $e')));
    } finally {
      if (!mounted) return;
      setState(() => _bookmarkBusy = false);
    }
  }
  String _fmtTime(String? t) {
  if (t == null || t.isEmpty) return '--:--';
  try {
    final parts = t.split(':');    
    int h = int.parse(parts[0]);
    final m = int.parse(parts[1]);
    final period = h >= 12 ? 'P.M.' : 'A.M.';
    h = h % 12; if (h == 0) h = 12;
    return '$h:${m.toString().padLeft(2, '0')} $period';
  } catch (_) {
    return t; 
  }
}


  @override
  void initState() {
    super.initState();
    isFavorited = widget.stall.isFavorited;
    _loadIsBookmarked();

    _loadFiltersFromDB();
    _loadDishesAndTags();

    isClosed = widget.stall.status.toLowerCase().contains('closed');
  }

  void _toggleOverlay() {
    setState(() => isFilterOpen = !isFilterOpen);
  }

  @override
  void dispose() {
    super.dispose();
  }

  // ================================================== //

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final roofHeight = screenWidth * 0.48;
    List<MenuItem> _applyTagFilter(List<MenuItem> items) {
      if (selectedFilters.isEmpty) return items;

      return items.where((m) {
        final dishId = m.id.toString();
        final tags = _dishTagsByDishId[dishId] ?? const <String>{};
        return selectedFilters.every(tags.contains);
      }).toList();
    }

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
                          Center(
                            child: Row(
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
                                    borderRadius: BorderRadius.circular(8),
                                    child: (widget.stall.imagePath.isNotEmpty)
                                        ? Image.network(
                                            widget.stall.imagePath,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) {
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
                                  padding: const EdgeInsets.only(
                                    left: 8,
                                    top: 2,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      SizedBox(
                                        width: 180,
                                        child: Padding(
                                          padding: const EdgeInsets.only(
                                            top: 6,
                                          ),
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
                              // === Stall title & Location ===
                              GestureDetector(
                                onTap: () => _toggleFavorite(),
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
                          ),

                          // === Operating Hours ===
                          const SizedBox(height: 1),
                          const Divider(color: Color(0xFFC5C5C5), thickness: 1),
                          const SizedBox(height: 1),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12.0,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Operating Hours',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black,
                                  ),
                                ),
                                Text(
                                  '${_fmtTime(widget.stall.openTime)}  -  ${_fmtTime(widget.stall.closeTime)}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 1),
                          const Divider(color: Color(0xFFC5C5C5), thickness: 1),
                          const SizedBox(height: 10),

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
                                        final sortedItems = [...menuItems]
                                          ..sort((a, b) {
                                            if (a.available == b.available)
                                              return 0;
                                            return a.available ? -1 : 1;
                                          });

                                        final filtered = _applyTagFilter(
                                          sortedItems,
                                        );

                                        if (widget.stall.status.toLowerCase().contains('closed')) {
                                          return SizedBox(
                                            height: MediaQuery.of(context).size.height * 0.4,
                                            child: Center(
                                                child: Text(
                                                  '${widget.stall.stallName} is currently closed!',
                                                  textAlign: TextAlign.center,
                                                  style: const TextStyle(
                                                    color: Colors.black54,
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          );
                                        }

                                        if (sortedItems.isEmpty) {
                                          return SizedBox(
                                            height: MediaQuery.of(context).size.height * 0.4,
                                            child: const Center(
                                              child: Text(
                                                'No dishes found.',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  color: Colors.black54,
                                                ),
                                              ),
                                            ),
                                          );
                                        }

                                        if (filtered.isEmpty) {
                                          return SizedBox(
                                            height: MediaQuery.of(context).size.height * 0.4,
                                            child: const Center(
                                              child: Text(
                                                'No dishes match the selected tags.',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  color: Colors.black54,
                                                ),
                                              ),
                                            ),
                                          );
                                        }

                                        return GridView.builder(
                                          itemCount: filtered.length,
                                          shrinkWrap: true,
                                          physics:
                                              const NeverScrollableScrollPhysics(),

                                          gridDelegate:
                                              const SliverGridDelegateWithFixedCrossAxisCount(
                                                crossAxisCount: 2,
                                                crossAxisSpacing: 23,
                                                mainAxisSpacing: 23,
                                                mainAxisExtent: 122 + 1 + 12 + 22, 
                                              ),
                                          itemBuilder: (context, index) {
                                            final item = filtered[index];

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
                                                                    11,
                                                                  ),
                                                              topRight:
                                                                  Radius.circular(
                                                                    11,
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
                                                        child:SizedBox(
                                                          width: double.infinity,
                                                          child: Text(
                                                            item.dishName,
                                                            textAlign: TextAlign.center,
                                                            softWrap: true,
                                                            overflow: TextOverflow.ellipsis,
                                                            maxLines: 1,
                                                            style: const TextStyle(
                                                              fontSize: 14,
                                                              fontWeight: FontWeight.w500,
                                                            ),
                                                          ),
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
}
