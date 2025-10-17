/*
  File: search.dart
  Purpose: Provides a search interface for customers to find dishes across
           different stalls. Supports live search with debounce, recent search
           history management, and navigation to individual dish views. Integrates
           with Supabase for fetching dish and stall data.
  Developers: Rebusa, Amber Kaia J. [juliankaiaaa]
              Magat, Maria Josephine M. [jsphnmgt]
              Pineda, Mary Alexa Ysabelle V. [hrspnd]
*/

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:haulam/models/stalls_model.dart';
import 'package:haulam/models/menu_item.dart';
import 'package:haulam/screens/customer-stall-pages/stall_dish_view.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  // ==================== BACK END ==================== //
  final supabase = Supabase.instance.client;

  final TextEditingController _searchController = TextEditingController();
  final List<String> _recentSearches = [];
  String _query = '';

  // Live results from Supabase mapped to your UI keys: name, stall, image
  List<Map<String, dynamic>> _results = [];
  bool _loading = false;

  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    setState(() => _query = value.trim());

    // debounce to avoid calling on every keystroke
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (_query.isEmpty) {
        setState(() => _results = []);
      } else {
        _searchDishes(_query);
      }
    });
  }

  Future<void> _searchDishes(String q) async {
    try {
      setState(() => _loading = true);

      final rows = await supabase
          .from('Dishes')
          .select(
            'id, dish_name, image_url, stall_id, available, price, description, created_at, '
            'stall:"Stalls"(id, stall_name, location, image_url, is_open)',
          )
          .ilike('dish_name', '%$q%')
          .order('available', ascending: false)
          .limit(50);

      setState(() {
        _results = List<Map<String, dynamic>>.from(rows);
        _loading = false;
      });
    } on PostgrestException catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Supabase error: ${e.message}')));
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unexpected error: $e')));
    }
  }

  void _addToRecentSearches(String value) {
    if (value.isNotEmpty && !_recentSearches.contains(value)) {
      setState(() {
        _recentSearches.insert(0, value);
      });
    }
  }

  void _removeSearch(String value) {
    setState(() {
      _recentSearches.remove(value);
    });
  }

  void _clearHistory() {
    setState(() {
      _recentSearches.clear();
    });
  }

  // ================================================== //

  @override
  Widget build(BuildContext context) {
    final searchResults = _query.isEmpty ? [] : _results;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: const Color(0xff65000F),
        toolbarHeight: 100,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(25)),
        ),
        title: const Padding(
          padding: EdgeInsets.only(top: 40.0, right: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                'Search',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.only(top: 40, left: 32, right: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Search Field
            Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
                borderRadius: BorderRadius.circular(17),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                onSubmitted: (value) {
                  final v = value.trim();
                  if (v.isEmpty) return;
                  _addToRecentSearches(v);
                  setState(() => _query = v);
                  _searchDishes(v);
                },
                decoration: InputDecoration(
                  prefixIcon: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: SvgPicture.asset(
                      'assets/icons/search.svg',
                      width: 20,
                      height: 20,
                      colorFilter: const ColorFilter.mode(
                        Colors.black,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  hintText: 'Search dishes',
                  hintStyle: const TextStyle(color: Color(0xFFC5C5C5)),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(17),
                    borderSide: const BorderSide(color: Colors.black),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(17),
                    borderSide: const BorderSide(
                      color: Color(0xff65000F),
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ),

            const Divider(color: Color(0xFFC5C5C5), thickness: 1),

            // Loading state
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              ),

            // Grid of Search Results
            if (!_loading && searchResults.isNotEmpty)
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.only(bottom: 20),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.9,
                    crossAxisSpacing: 23,
                    mainAxisSpacing: 23,
                  ),
                  itemCount: searchResults.length,
                  itemBuilder: (context, index) {
                    final r = searchResults[index];
                    final stallMap = r['stall'] as Map<String, dynamic>?;
                    final isOpenBool = (stallMap?['is_open'] as bool?) ?? false;
                    final img = r['image_url'] as String?;
                    final dishName = (r['dish_name'] as String?) ?? '';
                    final stallName =
                        (stallMap?['stall_name'] as String?) ?? '';
                    final stallObj = Stall.fromMap({
                      'imagePath': (stallMap?['image_url'] as String?) ?? '',
                      'stallName': (stallMap?['stall_name'] as String?) ?? '',
                      'status': isOpenBool ? 'Open' : 'Closed',
                      'location': (stallMap?['location'] as String?) ?? '',
                    }, (stallMap?['id'] ?? r['stall_id'] ?? '') as String);

                    // Build MenuItem (matches your Dishes model)
                    final dishObj = MenuItem(
                      id: r['id'] as String,
                      stallId: r['stall_id'] as String?,
                      dishName: dishName,
                      description: r['description'] as String?,
                      price: (r['price'] as num?)?.toDouble() ?? 0.0,
                      imageUrl: img,
                      available: (r['available'] as bool?) ?? true,
                      createdAt:
                          DateTime.tryParse(
                            (r['created_at'] as String?) ?? '',
                          ) ??
                          DateTime.now(),
                    );
                    return GestureDetector(
                      onTap: () {
                        if (!dishObj.available) {
                          return;
                        }
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => StallDishViewPage(
                              stall: stallObj,
                              dish: dishObj,
                            ),
                          ),
                        );
                      },
                      child: Opacity(
                        opacity: dishObj.available ? 1 : 0.4,
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
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(12),
                                    topRight: Radius.circular(12),
                                  ),
                                  child: (img != null && img.isNotEmpty)
                                      ? Image.network(
                                          img,
                                          fit: BoxFit.cover,
                                          width: double.infinity,
                                          errorBuilder: (_, __, ___) =>
                                              Image.asset(
                                                'assets/png/image-square.png',
                                                fit: BoxFit.cover,
                                                width: double.infinity,
                                              ),
                                        )
                                      : Image.asset(
                                          'assets/png/image-square.png',
                                          fit: BoxFit.cover,
                                          width: double.infinity,
                                        ),
                                ),
                              ),
                              Container(
                                width: double.infinity,
                                height: 1,
                                color: const Color(0xff710E1D),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(6.0),
                                child: Column(
                                  children: [
                                    Text(
                                      dishName,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      textAlign: TextAlign.center,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      stallName,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w400,
                                        color: Colors.grey,
                                      ),
                                      textAlign: TextAlign.center,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

            // Recent searches list (only when no query)
            if (_recentSearches.isNotEmpty && _query.isEmpty)
              Expanded(
                child: ListView.builder(
                  itemCount: _recentSearches.length + 1,
                  itemBuilder: (context, index) {
                    if (index < _recentSearches.length) {
                      final item = _recentSearches[index];
                      return Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: ListTile(
                              minVerticalPadding: 0,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12.0,
                              ),
                              leading: const Icon(
                                Icons.access_time,
                                color: Colors.black,
                              ),
                              title: Text(
                                item,
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 14,
                                ),
                              ),
                              trailing: IconButton(
                                icon: SvgPicture.asset(
                                  'assets/icons/x-icon-grey.svg',
                                  width: 18,
                                  height: 18,
                                ),
                                onPressed: () => _removeSearch(item),
                              ),
                              onTap: () {
                                _searchController.text = item;
                                _onSearchChanged(item);
                              },
                            ),
                          ),
                          if (index != _recentSearches.length - 1)
                            const Divider(
                              color: Color(0xFFC5C5C5),
                              thickness: 1,
                              height: 0,
                            ),
                        ],
                      );
                    } else {
                      return Padding(
                        padding: const EdgeInsets.only(top: 2, bottom: 10),
                        child: Center(
                          child: TextButton(
                            onPressed: _clearHistory,
                            child: const Text(
                              'Clear search history',
                              style: TextStyle(
                                color: Color(0xFFC5C5C5),
                                fontSize: 12,
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                          ),
                        ),
                      );
                    }
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
