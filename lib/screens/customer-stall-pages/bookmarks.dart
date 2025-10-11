import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../store_roof.dart';
import '../../models/stalls_model.dart';

final supabase = Supabase.instance.client;

class BookmarksPage extends StatefulWidget {
  const BookmarksPage({super.key});

  @override
  State<BookmarksPage> createState() => _BookmarksPageState();
}

class _BookmarksPageState extends State<BookmarksPage> {
  List<Stall> bookmarkedStalls = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchBookmarks();
  }

 // =========================== BACK - END [SUPABASE] ==========================

  Future<void> fetchBookmarks() async {
    setState(() => isLoading = true);

    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        setState(() => isLoading = false);
        return;
      }

      final response = await supabase
          .from('Bookmarks')
          .select(
            'stall_id, Stalls (id, stall_name, location, is_open, image_url)',
          )
          .eq('user_id', user.id);

      setState(() {
        bookmarkedStalls = (response as List).map<Stall>((row) {
          final stall = row['Stalls'];
          return Stall(
            id: stall['id'].toString(),
            imagePath: stall['image_url'] ?? '',
            title:
                "${stall['stall_name']} - ${stall['location'] ?? 'No Location'}",
            status: stall['is_open'] == true
                ? "Currently Open"
                : "Currently Closed",
            location: stall['location'] ?? "Unknown",
            isFavorited: true,
          );
        }).toList();
        isLoading = false;
      });
    } catch (e) {
      print("Error fetching bookmarks: $e");
      setState(() => isLoading = false);
    }
  }

  // ====== Remove bookmark ======
  Future<void> toggleBookmark(String stallId, bool isFav) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      if (isFav) {
        // User just favorited → insert into Bookmarks
        await supabase.from('Bookmarks').insert({
          'user_id': user.id,
          'stall_id': stallId,
        });
      } else {
        // User unfavorited → delete from Bookmarks
        await supabase
            .from('Bookmarks')
            .delete()
            .eq('stall_id', stallId)
            .eq('user_id', user.id);
      }
    } catch (e) {
      print("Error toggling bookmark: $e");
    }
  }

  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final roofHeight = screenWidth * 0.48;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned.fill(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: EdgeInsets.only(
                      top: roofHeight - 64,
                      left: 16,
                      right: 16,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.fromLTRB(2, 50, 0, 10),
                          child: Text(
                            "Bookmarks",
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Color(0xff000000),
                            ),
                          ),
                        ),
                        if (bookmarkedStalls.isEmpty)
                          const Padding(
                            padding: EdgeInsets.only(top: 100),
                            child: Center(
                              child: Text(
                                "No bookmarks yet.",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.black54,
                                ),
                              ),
                            ),
                          )
                        else
                          ...bookmarkedStalls.map(
                            (stall) => StallCard(
                              stall: stall,
                              onFavoriteToggle: (isFav) {
                                toggleBookmark(stall.id, isFav);
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
          ),
          const Positioned(top: 0, left: 0, right: 0, child: StoreRoof()),
        ],
      ),
    );
  }
}

// ====== Stall Card (with heart) ======
class StallCard extends StatefulWidget {
  final Stall stall;
  final ValueChanged<bool> onFavoriteToggle;

  const StallCard({
    super.key,
    required this.stall,
    required this.onFavoriteToggle,
  });

  @override
  State<StallCard> createState() => _StallCardState();
}

class _StallCardState extends State<StallCard> {
  late bool isFavorited;

  @override
  void initState() {
    super.initState();
    isFavorited = widget.stall.isFavorited;
  }

  void _handleTap() {
    setState(() {
      isFavorited = !isFavorited;
    });
    widget.onFavoriteToggle(isFavorited); // still sync with backend
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Center(
      child: Container(
        width: screenWidth * 0.88,
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
          boxShadow: const [
            BoxShadow(
              color: Color.fromARGB(57, 0, 0, 0),
              blurRadius: 6,
              offset: Offset(0, 4),
              spreadRadius: 2,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  (widget.stall.imagePath.isNotEmpty)
                      ? Image.network(
                          widget.stall.imagePath,
                          height: 120,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Image.asset(
                              'assets/png/image-rectangle.png',
                              height: 120,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            );
                          },
                        )
                      : Image.asset(
                          'assets/png/image-rectangle.png',
                          height: 120,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),

                  Positioned(
                    top: 14,
                    right: 14,
                    child: GestureDetector(
                      onTap: _handleTap,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.5),
                              offset: const Offset(0, 2),
                              blurRadius: 4,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 14,
                          backgroundColor: Colors.white,
                          child: SvgPicture.asset(
                            isFavorited
                                ? "assets/icons/heart-red-selected.svg"
                                : "assets/icons/heart-red-hollow.svg",
                            width: 20,
                            height: 20,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(23, 8, 8, 8),
                decoration: const BoxDecoration(
                  color: Color(0xff710E1D),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.stall.title,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      widget.stall.status,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/*

LAST WORKING VERSION --- October 11: 10PM

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../store_roof.dart';
import '../../models/stalls_model.dart'; 

class BookmarksPage extends StatefulWidget {
  const BookmarksPage({super.key});

  @override
  State<BookmarksPage> createState() => _BookmarksPageState();
}

class _BookmarksPageState extends State<BookmarksPage> {
  // Mock bookmarked stalls (local data for now)
  List<Stall> bookmarkedStalls = [
    Stall(
      id: "1",
      imagePath: "assets/png/stmartha-kirstenjoy.png",
      title: "KIRSTENJOY - St. Martha Hall",
      status: "Currently Open",
      isFavorited: true, location: '',
    ),
    Stall(
      id: "2",
      imagePath: "assets/png/image-rectangle.png",
      title: "Main Canteen - PGN Basement",
      status: "Currently Open",
      isFavorited: true, location: '',
    ),
  ];

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
              padding: EdgeInsets.only(
                top: roofHeight - 64,
                left: 16,
                right: 16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(2, 50, 0, 10),
                    child: Text(
                      "Bookmarks",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xff000000),
                      ),
                    ),
                  ),

                  // If no bookmarks, show message
                  if (bookmarkedStalls.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 100),
                      child: Center(
                        child: Text(
                          "No bookmarks yet.",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.black54,
                          ),
                        ),
                      ),
                    )
                  else
                    // Dynamically build StallCards
                    ...bookmarkedStalls.map((stall) => StallCard(
                          stall: stall,
                        )),
                ],
              ),
            ),
          ),

          // Store roof at top
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: StoreRoof(),
          ),
        ],
      ),
    );
  }
}

// Stall Card Widget
class StallCard extends StatefulWidget {
  final Stall stall;

  const StallCard({
    super.key,
    required this.stall,
  });

  @override
  State<StallCard> createState() => _StallCardState();
}

class _StallCardState extends State<StallCard> {
  late bool isFavorited;

  @override
  void initState() {
    super.initState();
    isFavorited = widget.stall.isFavorited;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Center(
      child: Container(
        width: screenWidth * 0.88,
        margin: const EdgeInsets.only(bottom: 20), 
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
          boxShadow: const [
            BoxShadow(
              color: Color.fromARGB(57, 0, 0, 0),
              blurRadius: 6,
              offset: Offset(0, 4),
              spreadRadius: 2,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Stall Image with bookmark button
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                    child: Image.asset(
                      widget.stall.imagePath,
                      height: 120,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),

                  // Bookmark button
                  Positioned(
                    top: 14,
                    right: 14,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          isFavorited = !isFavorited;
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.5),
                              offset: const Offset(0, 2),
                              blurRadius: 4,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 14,
                          backgroundColor: Colors.white,
                          child: SvgPicture.asset(
                            isFavorited
                                ? "assets/icons/heart-red-selected.svg"
                                : "assets/icons/heart-red-hollow.svg",
                            width: 20,
                            height: 20,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // Info Section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(23, 8, 8, 8),
                decoration: const BoxDecoration(
                  color: Color(0xff710E1D),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.stall.title,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      widget.stall.status,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

*/
