import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final List<String> _recentSearches = [];

  String _query = '';

  final List<Map<String, String>> _dishes = [
    {
      'name': 'Tapsilog',
      'stall': 'KIRSTENJOY',
      'image': 'assets/png/tocino.png',
    },
    {'name': 'Tocilog', 'stall': 'MAMAMO', 'image': 'assets/png/tocilog.png'},
  ];

  void _onSearchChanged(String value) {
    setState(() {
      _query = value.trim();
    });
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

  @override
  Widget build(BuildContext context) {
    final searchResults = _query.isEmpty
        ? []
        : _dishes
              .where(
                (dish) =>
                    dish['name']!.toLowerCase().contains(_query.toLowerCase()),
              )
              .toList();

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
                  _addToRecentSearches(value);
                  _searchController.clear();
                  _onSearchChanged('');
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
                  contentPadding: const EdgeInsets.symmetric(vertical: 12), //
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

            // Grid of Search Results
            if (searchResults.isNotEmpty)
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
                    final dish = searchResults[index];
                    return Container(
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
                              child: Image.asset(
                                dish['image']!,
                                fit: BoxFit.cover,
                                width: double.infinity,
                              ),
                            ),
                          ),

                          //red line
                          Container(
                            width: double.infinity,
                            height: 1,
                            color: Color(0xff710E1D),
                          ),

                          Padding(
                            padding: const EdgeInsets.all(6.0),
                            child: Column(
                              children: [
                                Text(
                                  dish['name']!,
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
                                  dish['stall']!,
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
                    );
                  },
                ),
              ),

            // Recent searches list
            if (_recentSearches.isNotEmpty && _query.isEmpty)
              Expanded(
                child: ListView.builder(
                  itemCount:
                      _recentSearches.length + 1, // +1 for the "Clear" button
                  itemBuilder: (context, index) {
                    if (index < _recentSearches.length) {
                      final item = _recentSearches[index];
                      return Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 4.0,
                            ), // tighter spacing
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
                          // Divider only between items
                          if (index != _recentSearches.length - 1)
                            const Divider(
                              color: Color(0xFFC5C5C5),
                              thickness: 1,
                              height: 0,
                            ),
                        ],
                      );
                    } else {
                      // "Clear search history" under the last item
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
