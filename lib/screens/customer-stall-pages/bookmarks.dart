import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../store_roof.dart';
import '../models/stalls_model.dart'; 

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
