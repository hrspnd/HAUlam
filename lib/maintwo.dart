/*
  File: vendor_navbar.dart
  Purpose: Implements the bottom navigation bar for vendors, allowing
           easy switching between the Vendor Stall page and the Account
           Profile page. Manages the currently selected tab state.
  Developers: Magat, Maria Josephine M. [jsphnmgt]
*/

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:haulam/screens/account-pages/account_profile.dart';
import 'vendor-view-pages/vendor_stall.dart';

class VendorNavBar extends StatefulWidget {
  final int currentIndex; 

  const VendorNavBar({
    super.key,
    this.currentIndex = 0, // default to Home
  });

  @override
  State<VendorNavBar> createState() => _VendorNavBarState();
}

class _VendorNavBarState extends State<VendorNavBar> {
  late int _currentIndex;

  final List<Widget> _pages = const [
    VendorStallPage(), 
    AccountPage(),              
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.currentIndex;
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
