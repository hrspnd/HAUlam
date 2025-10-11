import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:haulam/screens/account-pages/account_profile.dart';
import 'vendor-view-pages/vendor_stall.dart';
import 'vendor-view-pages/vendor_edit_profile.dart';

class MainTwoScaffold extends StatefulWidget {
  final int currentIndex; // <-- Add this to select initial tab

  const MainTwoScaffold({
    super.key,
    this.currentIndex = 0, // default to Home
  });

  @override
  State<MainTwoScaffold> createState() => _MainTwoScaffoldState();
}

class _MainTwoScaffoldState extends State<MainTwoScaffold> {
  late int _currentIndex;

  final List<Widget> _pages = const [
    VendorStallPage(), //stalls
    // VendorProfilePage(), //profile  <---- pinalitan ko para lang ma-access yung log out tnx josie
    AccountPage(),                  // <---- TEMPORARY 
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.currentIndex; // <-- set initial tab
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        backgroundColor: const Color(0xff65000F),
        selectedItemColor: const Color(0xffFFEDA8),
        unselectedItemColor: const Color(0xffD5C173),
        selectedLabelStyle: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          fontFamily: 'Onest',
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.normal,
        ),
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(
            icon: SizedBox(
              width: 26,
              height: 26,
              child: SvgPicture.asset('assets/icons/botnav-stall.svg'),
            ),
            activeIcon: SizedBox(
              width: 26,
              height: 26,
              child: SvgPicture.asset('assets/icons/botnav-stall-selected.svg'),
            ),
            label: "My Stall",
          ),
          BottomNavigationBarItem(
            icon: SizedBox(
              width: 26,
              height: 26,
              child: SvgPicture.asset('assets/icons/botnav-profile.svg'),
            ),
            activeIcon: SizedBox(
              width: 26,
              height: 26,
              child: SvgPicture.asset('assets/icons/botnav-profile-selected.svg'),
            ),
            label: "Profile",
          ),
        ],
      ),
    );
  }
}