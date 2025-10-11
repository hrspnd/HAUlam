import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:haulam/screens/customer-stall-pages/bookmarks.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../store_roof.dart';
import '../models/stalls_model.dart';

final supabase = Supabase.instance.client;

// ====== Stalls Page ======
class StallsPage extends StatefulWidget {
  const StallsPage({super.key});

  @override
  State<StallsPage> createState() => _StallsPageState();
}

class _StallsPageState extends State<StallsPage> {
  List<Stall> stalls = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchStalls();
  }

  // ====== Fetch from Supabase ======
  Future<void> fetchStalls() async {
    setState(() => isLoading = true);

    try {
      final response = await supabase.from('Stalls').select();

      setState(() {
        stalls = response.map<Stall>((stall) {
          return Stall(
            id: stall['id'].toString(),
            imagePath: "assets/png/image-rectangle.png", // Placeholder for now
            title:
                ((stall['stall_name'] ?? 'Unnamed Stall') +
                        ' - ' +
                        (stall['location'] ?? 'No Location'))
                    .trim() ??
                "Unnamed Stall",
            status: (stall['is_open'] == true)
                ? "Currently Open"
                : "Currently Closed",
            location: stall['location'] ?? "Unknown location",
          );
        }).toList();
        isLoading = false;
      });
    } catch (e) {
      print("Error fetching stalls: $e");
      setState(() => isLoading = false);
    }
  }

  Future<void> updateFavorite(String stallId, bool isFavorited) async {
    // TODO: implement backend favorite tracking later
  }

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
                : RefreshIndicator(
                    onRefresh: fetchStalls,
                    color: Color(0xff710E1D),
                    child: SingleChildScrollView(
                      physics:
                          const AlwaysScrollableScrollPhysics(), // enables pull even when short
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
                              "Explore Canteen Stalls",
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Color(0xff000000),
                              ),
                            ),
                          ),

                          // Stall list
                          Transform.translate(
                            offset: const Offset(0, -32),
                            child: ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: stalls.length,
                              itemBuilder: (context, index) {
                                final stall = stalls[index];
                                return StallCard(
                                  stall: stall,
                                  onFavoriteToggle: (isFav) {
                                    setState(() {
                                      stalls[index] = Stall(
                                        id: stall.id,
                                        imagePath: stall.imagePath,
                                        title: stall.title,
                                        status: stall.status,
                                        location: stall.location,
                                        isFavorited: isFav,
                                      );
                                    });
                                    updateFavorite(stall.id, isFav);
                                  },
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),

          // Roof stays on top
          const Positioned(top: 0, left: 0, right: 0, child: StoreRoof()),
        ],
      ),
    );
  }
}

// ====== Stall Card Widget ======
class StallCard extends StatelessWidget {
  final Stall stall;
  final ValueChanged<bool> onFavoriteToggle;

  const StallCard({
    super.key,
    required this.stall,
    required this.onFavoriteToggle,
  });

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
              // Image with favorite button
              Stack(
                children: [
                  Image.asset(
                    stall.imagePath,
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                  Positioned(
                    top: 14,
                    right: 14,
                    child: GestureDetector(
                      onTap: () => onFavoriteToggle(!stall.isFavorited),
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
                            stall.isFavorited
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

              // Info section
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
                      stall.title,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      stall.status,
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

===> LAST WORKING VERSION (NO-Backend) || October 9 12:00AM

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../store_roof.dart';
import '../models/stalls_model.dart'; 

// ====== Stalls Page ======
class StallsPage extends StatefulWidget {
  const StallsPage({super.key});

  @override
  State<StallsPage> createState() => _StallsPageState();
}

class _StallsPageState extends State<StallsPage> {
  // Local stalls (later replaced by backend fetch)
  List<Stall> stalls = [
    Stall(
      id: "1",
      imagePath: "assets/png/stmartha-kirstenjoy.png",
      title: "KIRSTENJOY - St. Martha Hall",
      status: "Currently Open",
      location: "St. Martha Hall",
    ),
    Stall(
      id: "2",
      imagePath: "assets/png/image-rectangle.png",
      title: "Main Canteen - PGN Basement",
      status: "Currently Open",
      location: "PGN Basement",
    ),
  ];

  Future<void> fetchStalls() async {
    // TODO: Fetch from backend (Firebase, API, etc.)
  }

  Future<void> updateFavorite(String stallId, bool isFavorited) async {
    // TODO: Update favorite status in backend
  }

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
                      "Explore Canteen Stalls",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xff000000),
                      ),
                    ),
                  ),

                  // Stall list
                  Transform.translate(
                    offset: const Offset(0, -32),
                    child: ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: stalls.length,
                      itemBuilder: (context, index) {
                        final stall = stalls[index];
                        return StallCard(
                          stall: stall,
                          onFavoriteToggle: (isFav) {
                            setState(() {
                              stalls[index] = Stall(
                                id: stall.id,
                                imagePath: stall.imagePath,
                                title: stall.title,
                                status: stall.status,
                                location: stall.location,
                                isFavorited: isFav,
                              );
                            });
                            updateFavorite(stall.id, isFav);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Roof stays on top
          const Positioned(top: 0, left: 0, right: 0, child: StoreRoof()),
        ],
      ),
    );
  }
}

// ====== Stall Card Widget ======
class StallCard extends StatelessWidget {
  final Stall stall;
  final ValueChanged<bool> onFavoriteToggle;

  const StallCard({
    super.key,
    required this.stall,
    required this.onFavoriteToggle,
  });

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
              // Image with favorite button
              Stack(
                children: [
                  Image.asset(
                    stall.imagePath,
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                  Positioned(
                    top: 14,
                    right: 14,
                    child: GestureDetector(
                      onTap: () => onFavoriteToggle(!stall.isFavorited),
                      child: CircleAvatar(
                        radius: 16,
                        backgroundColor: Colors.white,
                        child: SvgPicture.asset(
                          stall.isFavorited
                              ? "assets/icons/heart-red-selected.svg"
                              : "assets/icons/heart-red-hollow.svg",
                          width: 20,
                          height: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // Info section
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
                      stall.title,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      stall.status,
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