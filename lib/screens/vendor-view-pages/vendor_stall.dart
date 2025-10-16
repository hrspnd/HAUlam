import 'package:auto_size_text/auto_size_text.dart' show AutoSizeText;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:haulam/screens/vendor-view-pages/vendor_create_dish.dart';
import 'package:haulam/screens/vendor-view-pages/vendor_edit_dish.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../store_roof.dart';
import 'vendor_edit_profile.dart';
import 'vendor_create_stall.dart';

final supabase = Supabase.instance.client;

class VendorStallPage extends StatefulWidget {
  const VendorStallPage({super.key});

  @override
  State<VendorStallPage> createState() => _VendorStallPageState();
}

class _VendorStallPageState extends State<VendorStallPage> {
  Map<String, dynamic>? stallData;
  bool loading = true;
  List<Map<String, dynamic>> menuItems = [];

  @override
  void initState() {
    super.initState();
    _loadStall();
  }

  // =========================== BACK - END [SUPABASE] ===========================

  void addMenuItem() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const VendorCreateDishPage()),
    ).then((_) => _loadDishes()); // refresh after adding
  }

  void editMenuItem(Map<String, dynamic> menuItem) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => VendorEditDishPage(dish: menuItem)),
    ).then((_) => _loadDishes()); // refresh after saving
  }

  Future<void> _loadStall() async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      setState(() => loading = false);
      return;
    }

    final response = await supabase
        .from('Stalls')
        .select()
        .eq('owner_id', user.id)
        .maybeSingle();

    if (response == null) {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const CreateStallPage()),
        );
      }
    } else {
      setState(() {
        stallData = response;
        loading = false;
      });
      _loadDishes();
    }
  }

  Future<void> _loadDishes() async {
    if (stallData == null) return;

    final dishes = await supabase
        .from('Dishes')
        .select()
        .eq('stall_id', stallData!['id']);

    setState(() {
      menuItems = List<Map<String, dynamic>>.from(dishes);
    });
  }

  Future<void> toggleAvailability(String dishId, bool newStatus) async {
    await supabase
        .from('Dishes')
        .update({'available': newStatus})
        .eq('id', dishId);

    setState(() {
      final index = menuItems.indexWhere((d) => d['id'] == dishId);
      if (index != -1) {
        menuItems[index]['available'] = newStatus;
      }
    });
  }

  Future<void> _toggleStallStatus(bool open) async {
    if (stallData == null) return;

    setState(() {
      stallData?['is_open'] = open;
    });

    await supabase
        .from('Stalls')
        .update({'is_open': open})
        .eq('id', stallData!['id']);
  }
  // =============================================================================

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final roofHeight = screenWidth * 0.48;

    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (stallData == null) {
      return const Scaffold(body: Center(child: Text("No stall found")));
    }

    final isOpen = stallData?['is_open'] ?? false;
    final stallName = stallData?['stall_name'] ?? "My Stall";

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned.fill(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(top: roofHeight - 25),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Stall Header
                    Padding(
                      padding: const EdgeInsets.only(left: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: const Color(0xff710E1D),
                                width: 2,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child:
                                  (stallData?['image_url'] != null &&
                                      stallData!['image_url']
                                          .toString()
                                          .isNotEmpty)
                                  ? Image.network(
                                      stallData!['image_url'],
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
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    SizedBox(
                                      width: 170,
                                      child: AutoSizeText(
                                        stallName,
                                        style: const TextStyle(
                                          fontSize: 26,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        maxLines: 1,
                                        minFontSize: 22,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                VendorEditProfilePage(
                                                  stallId: stallData!['id'],
                                                ),
                                          ),
                                        ).then((_) {
                                          _loadStall();
                                        });
                                      },
                                      child: Expanded(
                                        child: Align(
                                          alignment: Alignment.centerRight,
                                          child: Padding(
                                            padding: const EdgeInsets.only(
                                              right: 16,
                                            ),
                                            child: Container(
                                              padding: const EdgeInsets.all(6),
                                              decoration: BoxDecoration(
                                                color: const Color(0xff710E1D),
                                                shape: BoxShape.circle,
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black
                                                        .withValues(alpha: 0.1),
                                                    blurRadius: 3,
                                                    offset: const Offset(0, 2),
                                                  ),
                                                ],
                                              ),
                                              child: const Icon(
                                                Icons.edit,
                                                color: Colors.white,
                                                size: 18,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Transform.translate(
                                  offset: const Offset(0, -2),
                                  child: Row(
                                    children: [
                                      AnimatedContainer(
                                        duration: const Duration(
                                          milliseconds: 200,
                                        ),
                                        curve: Curves.easeInOut,
                                        child: ChoiceChip(
                                          label: const Text("Closed"),
                                          selected: !isOpen,
                                          backgroundColor: Color(0xffffffff),
                                          selectedColor: Color(0xff710E1D),
                                          checkmarkColor: Colors.white,
                                          labelStyle: TextStyle(
                                            color: isOpen
                                                ? Colors.black
                                                : Colors.white,
                                            fontSize: 12,
                                          ),
                                          materialTapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                          visualDensity: VisualDensity.compact,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 6,
                                          ),
                                          onSelected: (_) =>
                                              _toggleStallStatus(false),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      AnimatedContainer(
                                        duration: const Duration(
                                          milliseconds: 200,
                                        ),
                                        curve: Curves.easeInOut,
                                        child: ChoiceChip(
                                          label: const Text("Open"),
                                          selected: isOpen,
                                          backgroundColor: Color(0xffffffff),
                                          selectedColor: const Color(
                                            0xff710E1D,
                                          ),
                                          checkmarkColor: Colors.white,
                                          labelStyle: TextStyle(
                                            color: isOpen
                                                ? Colors.white
                                                : Colors.black,
                                            fontSize: 12,
                                          ),
                                          materialTapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                          visualDensity: VisualDensity.compact,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 6,
                                          ),
                                          onSelected: (_) =>
                                              _toggleStallStatus(true),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),

                    // ================= MENU GRID =================
                    Transform.translate(
                      offset: const Offset(0, -40),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: menuItems.length + 1,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 0.9,
                                crossAxisSpacing: 23,
                                mainAxisSpacing: 23,
                              ),
                          itemBuilder: (context, index) {
                            if (index == 0) {
                              return GestureDetector(
                                onTap: addMenuItem,
                                child: Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: const Color(0xff710E1D),
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Center(
                                    child: SvgPicture.asset(
                                      'assets/icons/add-button-red.svg',
                                      width: 30,
                                      height: 30,
                                    ),
                                  ),
                                ),
                              );
                            } else {
                              final item = menuItems[index - 1];
                              return GestureDetector(
                                onTap: () => editMenuItem(item),
                                child: Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: const Color(0xff710E1D),
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Expanded(
                                        child: Opacity(
                                          opacity: (item['available'] ?? true)
                                              ? 1.0
                                              : 0.3,
                                          child: ClipRRect(
                                            borderRadius:
                                                const BorderRadius.only(
                                                  topLeft: Radius.circular(7),
                                                  topRight: Radius.circular(7),
                                                ),
                                            child:
                                                (item['image_url'] != null &&
                                                    item['image_url']
                                                        .toString()
                                                        .isNotEmpty)
                                                ? Image.network(
                                                    item['image_url'],
                                                    fit: BoxFit.cover,
                                                    width: double.infinity,
                                                    errorBuilder:
                                                        (
                                                          context,
                                                          error,
                                                          stackTrace,
                                                        ) {
                                                          return Image.asset(
                                                            'assets/png/image-square.png',
                                                            fit: BoxFit.cover,
                                                          );
                                                        },
                                                  )
                                                : Image.asset(
                                                    'assets/png/image-square.png',
                                                    fit: BoxFit.cover,
                                                    width: double.infinity,
                                                  ),
                                          ),
                                        ),
                                      ),

                                      Container(
                                        height: 1,
                                        color: const Color(0xff710E1D),
                                      ),

                                      Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                          6,
                                          4,
                                          6,
                                          1,
                                        ),
                                        child: Text(
                                          item["dish_name"] ?? "Unnamed Dish",
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w400,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 4.0,
                                        ),
                                        child: Text(
                                          (item["available"] ?? true)
                                              ? "Available"
                                              : "Not Available",
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
                              );
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: IgnorePointer(child: StoreRoof()),
          ),
        ],
      ),
    );
  }
}





















//==================================================================================================================

// /*

// LAST COMMMIT: OCTOBER 13 9AM

// Changes made after previous commit:
// --- removed commented blocks of code

// */

// import 'package:flutter/material.dart';
// import 'package:haulam/screens/vendor-view-pages/vendor_create_dish.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';
// import '../store_roof.dart';
// import 'vendor_edit_profile.dart';
// import 'create_stall.dart';

// final supabase = Supabase.instance.client;

// class VendorStallPage extends StatefulWidget {
//   const VendorStallPage({super.key});

//   @override
//   State<VendorStallPage> createState() => _VendorStallPageState();
// }

// class _VendorStallPageState extends State<VendorStallPage> {
//   Map<String, dynamic>? stallData;
//   bool loading = true;

//   @override
//   void initState() {
//     super.initState();
//     _loadStall();
//   }

//   // =========================== BACK - END [SUPABASE] ===========================
//   final List<Map<String, dynamic>> menuItems = [
//     {"name": "Tocilog", "image": "assets/png/tocino.png", "available": true},
//     {
//       "name": "Beef Kaldereta",
//       "image": "assets/png/image-square.png",
//       "available": true,
//     },
//     {
//       "name": "Beef Mushroom",
//       "image": "assets/png/image-square.png",
//       "available": true,
//     },
//     {
//       "name": "Beef Broccoli",
//       "image": "assets/png/image-square.png",
//       "available": false,
//     },
//     {
//       "name": "Beef Steak",
//       "image": "assets/png/image-square.png",
//       "available": false,
//     },
//   ];

//   void addMenuItem() {
//     // Show form and save new menu item 
//     Navigator.push(
//       context,
//       MaterialPageRoute(builder: (context) => const VendorCreateDishPage()),
//     );
//   }

//   void editMenuItem(Map<String, dynamic> menuItem) {
//     // ===== BACKEND: Open edit form and update menu item in Supabase =====
//   }
//   Future<void> _loadStall() async {
//     final user = supabase.auth.currentUser;
//     if (user == null) {
//       // handle no logged in user
//       setState(() => loading = false);
//       return;
//     }

//     final response = await supabase
//         .from('Stalls')
//         .select()
//         .eq('owner_id', user.id)
//         .maybeSingle();

//     if (response == null) {
//       // vendor has no stall yet → redirect
//       if (mounted) {
//         Navigator.pushReplacement(
//           context,
//           MaterialPageRoute(builder: (context) => const CreateStallPage()),
//         );
//       }
//     } else {
//       setState(() {
//         stallData = response;
//         loading = false;
//       });
//     }
//   }

//   Future<void> _toggleStallStatus(bool open) async {
//     if (stallData == null) return;

//     setState(() {
//       stallData?['is_open'] = open;
//     });

//     await supabase
//         .from('Stalls')
//         .update({'is_open': open})
//         .eq('id', stallData!['id']);
//   }
//   // =============================================================================

//   @override
//   Widget build(BuildContext context) {
//     final screenWidth = MediaQuery.of(context).size.width;
//     final roofHeight = screenWidth * 0.48;

//     if (loading) {
//       return const Scaffold(body: Center(child: CircularProgressIndicator()));
//     }

//     if (stallData == null) {
//       return const Scaffold(body: Center(child: Text("No stall found")));
//     }

//     final isOpen = stallData?['is_open'] ?? false;
//     final stallName = stallData?['stall_name'] ?? "My Stall";

//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: Stack(
//         children: [
//           Positioned.fill(
//             child: SingleChildScrollView(
//               padding: EdgeInsets.only(top: roofHeight - 25),
//               child: Padding(
//                 padding: const EdgeInsets.symmetric(
//                   horizontal: 16,
//                   vertical: 20,
//                 ),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     // Stall Header
//                     Padding(
//                       padding: const EdgeInsets.only(left: 10),
//                       child: Row(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Container(
//                             width: 80,
//                             height: 80,
//                             decoration: BoxDecoration(
//                               color: Colors.white,
//                               borderRadius: BorderRadius.circular(10),
//                               border: Border.all(
//                                 color: const Color(0xff710E1D),
//                                 width: 2,
//                               ),
//                             ),
//                             child: ClipRRect(
//                               borderRadius: BorderRadius.circular(10),
//                               child:
//                                   (stallData?['image_url'] != null &&
//                                       stallData!['image_url']
//                                           .toString()
//                                           .isNotEmpty)
//                                   ? Image.network(
//                                       stallData!['image_url'],
//                                       fit: BoxFit.cover,
//                                       errorBuilder:
//                                           (context, error, stackTrace) {
//                                             return Image.asset(
//                                               'assets/png/image-square.png',
//                                               fit: BoxFit.cover,
//                                             );
//                                           },
//                                     )
//                                   : Image.asset(
//                                       'assets/png/image-square.png',
//                                       fit: BoxFit.cover,
//                                     ),
//                             ),
//                           ),

//                           const SizedBox(width: 12),
//                           Expanded(
//                             child: Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 Row(
//                                   mainAxisAlignment:
//                                       MainAxisAlignment.spaceBetween,
//                                   children: [
//                                     Text(
//                                       stallName,
//                                       style: const TextStyle(
//                                         fontSize: 26,
//                                         fontWeight: FontWeight.w600,
//                                       ),
//                                     ),
//                                     GestureDetector(
//                                       onTap: () {
//                                         Navigator.push(
//                                           context,
//                                           MaterialPageRoute(
//                                             builder: (context) =>
//                                                 const VendorEditProfilePage(),
//                                           ),
//                                         );
//                                       },
//                                       child: Transform.translate(
//                                         offset: Offset(-20, 2),
//                                         child: Container(
//                                           padding: const EdgeInsets.all(6),
//                                           decoration: BoxDecoration(
//                                             color: const Color(0xff710E1D),
//                                             shape: BoxShape.circle,
//                                             boxShadow: [
//                                               BoxShadow(
//                                                 color: Colors.black.withValues(
//                                                   alpha: 0.1,
//                                                 ),
//                                                 blurRadius: 3,
//                                                 offset: const Offset(0, 2),
//                                               ),
//                                             ],
//                                           ),
//                                           child: const Icon(
//                                             Icons.edit,
//                                             color: Colors.white,
//                                             size: 18,
//                                           ),
//                                         ),
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                                 const SizedBox(height: 4),
//                                 Transform.translate(
//                                   offset: const Offset(0, -2),
//                                   child: Row(
//                                     children: [
//                                       AnimatedContainer(
//                                         duration: const Duration(
//                                           milliseconds: 200,
//                                         ),
//                                         curve: Curves.easeInOut,
//                                         child: ChoiceChip(
//                                           label: const Text("Closed"),
//                                           selected: !isOpen,
//                                           backgroundColor: Color(0xffffffff),
//                                           selectedColor: Color(0xff710E1D),
//                                           checkmarkColor: Colors.white,
//                                           labelStyle: TextStyle(
//                                             color: isOpen
//                                                 ? Colors.black
//                                                 : Colors.white,
//                                             fontSize: 12,
//                                           ),
//                                           materialTapTargetSize:
//                                               MaterialTapTargetSize.shrinkWrap,
//                                           visualDensity: VisualDensity.compact,
//                                           padding: const EdgeInsets.symmetric(
//                                             horizontal: 8,
//                                             vertical: 6,
//                                           ),
//                                           onSelected: (_) =>
//                                               _toggleStallStatus(false),
//                                         ),
//                                       ),
//                                       const SizedBox(width: 8),
//                                       AnimatedContainer(
//                                         duration: const Duration(
//                                           milliseconds: 200,
//                                         ),
//                                         curve: Curves.easeInOut,
//                                         child: ChoiceChip(
//                                           label: const Text("Open"),
//                                           selected: isOpen,
//                                           backgroundColor: Color(0xffffffff),
//                                           selectedColor: const Color(
//                                             0xff710E1D,
//                                           ),
//                                           checkmarkColor: Colors.white,
//                                           labelStyle: TextStyle(
//                                             color: isOpen
//                                                 ? Colors.white
//                                                 : Colors.black,
//                                             fontSize: 12,
//                                           ),
//                                           materialTapTargetSize:
//                                               MaterialTapTargetSize.shrinkWrap,
//                                           visualDensity: VisualDensity.compact,
//                                           padding: const EdgeInsets.symmetric(
//                                             horizontal: 8,
//                                             vertical: 6,
//                                           ),
//                                           onSelected: (_) =>
//                                               _toggleStallStatus(true),
//                                         ),
//                                       ),
//                                     ],
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//           const Positioned(top: 0, left: 0, right: 0, child: StoreRoof()),
//         ],
//       ),
//       // ======= TEMPORARY "ADD DISH" button =======
//       floatingActionButton: FloatingActionButton(
//         backgroundColor: const Color(0xff710E1D),
//         child: const Icon(Icons.add, color: Colors.white),
//         onPressed: () {
//           addMenuItem();
//         },
//       ),
//     );
//   }
// }
