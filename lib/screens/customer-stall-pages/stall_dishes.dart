import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:auto_size_text/auto_size_text.dart';
import '../store_roof.dart';
import '../models/stalls_model.dart';
import '../models/menu_item.dart';

class StallDishesPage extends StatefulWidget {
  final Stall stall;

  const StallDishesPage({super.key, required this.stall});

  @override
  State<StallDishesPage> createState() => _StallDishesPageState();
}

class _StallDishesPageState extends State<StallDishesPage> {
  late bool isFavorited;
  bool isFilterOpen = false;
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();

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

  List<MenuItem> menuItems = [
    MenuItem(
      id: "1",
      name: "Tapsilog",
      imagePath: "assets/png/image-square.png",
    ),
    MenuItem(
      id: "2",
      name: "Tocilog",
      imagePath: "assets/png/image-square.png",
    ),
    MenuItem(
      id: "3",
      name: "Beef Kaldereta",
      imagePath: "assets/png/image-square.png",
    ),
    MenuItem(
      id: "4",
      name: "Beef Mushroom",
      imagePath: "assets/png/image-square.png",
    ),
    MenuItem(
      id: "5",
      name: "Beef Broccoli",
      imagePath: "assets/png/image-square.png",
      isAvailable: false,
    ),
    MenuItem(
      id: "6",
      name: "Beef Steak",
      imagePath: "assets/png/image-square.png",
      isAvailable: false,
    ),
  ];

  @override
  void initState() {
    super.initState();
    isFavorited = widget.stall.isFavorited;
  }

  void _toggleOverlay() {
    if (isFilterOpen) {
      _removeOverlay();
    } else {
      _showOverlay();
    }
    setState(() => isFilterOpen = !isFilterOpen);
  }

  void _showOverlay() {
  _overlayEntry = OverlayEntry(
    builder: (context) {
      return Stack(
        children: [
          // Tap outside to close the dropdown
          Positioned.fill(
            child: GestureDetector(
              onTap: _toggleOverlay,
              behavior: HitTestBehavior.translucent,
            ),
          ),
          // Fixed dropdown
          Positioned(
            top: 300, // adjust to appear below filter row
            left: 16,
            right: 16,
            child: Material(
              borderRadius: BorderRadius.circular(20),
              color: Colors.white,
              elevation: 0,
              child: _buildDropdownFilters(),
            ),
          ),
        ],
      );
    },
  );

  Overlay.of(context).insert(_overlayEntry!);
}


  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  void dispose() {
    if (isFilterOpen) _removeOverlay();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final roofHeight = screenWidth * 0.48;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
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
                              child: Image.asset(
                                'assets/png/image-square.png',
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Transform.translate(
                            offset: const Offset(8, 0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: AutoSizeText(
                                    widget.stall.title,
                                    style: const TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black,
                                    ),
                                    maxLines: 1,
                                    minFontSize: 15,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Transform.translate(
                                  offset: const Offset(0, -10),
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
                        GestureDetector(
                          onTap: () =>
                              setState(() => isFavorited = !isFavorited),
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

                    const SizedBox(height: 16),

                    // ===== Filter Row =====
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: CompositedTransformTarget(
                          link: _layerLink,
                          child: Wrap(
                            alignment: WrapAlignment.center,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              _buildFilterButton(),
                              ..._buildActiveTags(),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ===== Menu Grid =====
                    Transform.translate(
                      offset: const Offset(0, -40),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: menuItems.length,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 0.9,
                                crossAxisSpacing: 23,
                                mainAxisSpacing: 23,
                              ),
                          itemBuilder: (context, index) {
                            final item = menuItems[index];
                            return Opacity(
                              opacity: item.isAvailable ? 1 : 0.4,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border.all(
                                    color: const Color(0xFF710E1D),
                                    width: 1,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x25000000),
                                      offset: Offset(0, 4),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    ClipRRect(
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(12),
                                        topRight: Radius.circular(12),
                                      ),
                                      child: Image.asset(
                                        item.imagePath,
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                        height: 122,
                                      ),
                                    ),
                                    Container(
                                      width: double.infinity,
                                      height: 1,
                                      color: const Color(0xff710E1D),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(6.0),
                                      child: Text(
                                        item.name,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
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

  // ==== Filter Button ====
  Widget _buildFilterButton() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _toggleOverlay,
      child: Container(
        height: 32, // ✅ fixed height for perfect uniformity
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
          mainAxisAlignment: MainAxisAlignment.center,
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
    );
  }

  // ==== Dropdown Filters ====
  Widget _buildDropdownFilters() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFF710E1D), width: 1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: GridView.count(
        crossAxisCount: 3,
        shrinkWrap: true,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 2.8,
        physics: const NeverScrollableScrollPhysics(),
        children: filters.map((filter) {
          final isSelected = selectedFilters.contains(filter["label"]);
          return GestureDetector(
            onTap: () {
  setState(() {
    if (isSelected) {
      selectedFilters.remove(filter["label"]);
    } else {
      if (!selectedFilters.contains(filter["label"])) {
        selectedFilters.add(filter["label"]);
      }
    }

    // 🔹 Refresh the overlay so changes are visible immediately
    _overlayEntry?.remove();
    _showOverlay();
  });
},


            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFFFE6E6) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFF710E1D),
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    margin: const EdgeInsets.only(right: 6),
                    decoration: BoxDecoration(
                      color: filter["color"],
                      shape: BoxShape.circle,
                    ),
                  ),
                  Flexible(
                    child: Text(
                      filter["label"],
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.black,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ==== Active Tags ====
  List<Widget> _buildActiveTags() {
    final activeFilters = selectedFilters.isNotEmpty
    ? selectedFilters.take(2).toList()
    : ["Beef", "Chicken"];
    return activeFilters.map((label) {
      final color =
          filters.firstWhere(
                (f) => f["label"] == label,
                orElse: () => {"color": const Color(0xFF710E1D)},
              )["color"]
              as Color;
      final isSelected = selectedFilters.contains(label);
      return _buildFixedTag(label, color, isSelected);
    }).toList();
  }

  Widget _buildFixedTag(String label, Color color, bool isSelected) {
  return GestureDetector(
    onTap: () {
  setState(() {
    if (isSelected) {
      selectedFilters.remove(label); // deselect
    }
    // ❌ remove the "else" part — no re-adding here
  });
},

    child: AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 102,
      height: 32,
      padding: const EdgeInsets.only(left: 10, right: 8),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFFFE6E6) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF710E1D),
          width: isSelected ? 2 : 1.2,
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
            style: TextStyle(
              fontSize: 12,
              color: Colors.black,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    ),
  );
}
}
