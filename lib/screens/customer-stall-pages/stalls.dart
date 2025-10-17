/*
  File: stalls.dart
  Purpose: Displays a list of all canteen stalls with real-time data from Supabase. 
           Includes bookmark management, pull-to-refresh, and navigation to stall-specific dishes.
  Developers: Magat, Maria Josephine M. [jsphnmgt]
              Pineda, Mary Alexa Ysabelle V. [hrspnd]
*/

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:haulam/screens/customer-stall-pages/stall_dishes.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../store_roof.dart';
import '../../models/stalls_model.dart';

final supabase = Supabase.instance.client;

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

  // ==================== BACK END ==================== //

  Future<void> fetchStalls() async {
    setState(() => isLoading = true);

    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        setState(() => isLoading = false);
        return;
      }

      // Fetch all stalls
      final stallsRes = await supabase.from('Stalls').select();

      // Fetch current user's bookmarks
      final bookmarksRes = await supabase
          .from('Bookmarks')
          .select('stall_id')
          .eq('user_id', user.id);

      final bookmarkedIds = (bookmarksRes as List)
          .map((b) => b['stall_id'].toString())
          .toSet();

      setState(() {
        stalls = (stallsRes as List).map<Stall>((stall) {
          final isFav = bookmarkedIds.contains(stall['id'].toString());
          return Stall(
            id: stall['id'].toString(),
            imagePath: stall['image_url'] ?? '',
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
            isFavorited: isFav,
            stallName: stall['stall_name'] ?? "No Stall",
            openTime: stall['open_time'] as String?,
            closeTime: stall['close_time'] as String?,
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
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      if (isFavorited) {
        // Add to bookmarks
        await supabase.from('Bookmarks').insert({
          'user_id': user.id,
          'stall_id': stallId,
        });
      } else {
        // Remove from bookmarks
        await supabase
            .from('Bookmarks')
            .delete()
            .eq('user_id', user.id)
            .eq('stall_id', stallId);
      }
    } catch (e) {
      print("Error updating favorite: $e");
    }
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
          Positioned.fill(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: fetchStalls,
                    color: Color(0xff710E1D),
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
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
                                        stallName: stall.stallName,
                                      );
                                    });
                                    updateFavorite(stall.id, isFav);
                                  },
                                  onReload: fetchStalls,
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

class StallCard extends StatelessWidget {
  final Stall stall;
  final ValueChanged<bool> onFavoriteToggle;
  final VoidCallback? onReload;

  const StallCard({
    super.key,
    required this.stall,
    required this.onFavoriteToggle,
    this.onReload,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => StallDishesPage(stall: stall)),
        ).then((_) {
          onReload?.call();
        });
      },
      child: Center(
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
                    (stall.imagePath.isNotEmpty)
                        ? Image.network(
                            stall.imagePath,
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
                        onTap: () {
                          // Prevent tap from propagating to parent
                          onFavoriteToggle(!stall.isFavorited);
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
      ),
    );
  }
}
