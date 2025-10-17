/*
  File: customer_navbar.dart
  Purpose: Implements the bottom navigation bar for customers, allowing
           easy switching between Stalls, Bookmarks, Search, and Account
           pages. Manages the currently selected tab state.
  Developers: Magat, Maria Josephine M. [jsphnmgt]
              Pineda, Mary Alexa Ysabelle V. [hrspnd]
*/

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'customer-stall-pages/stalls.dart';
import 'customer-stall-pages/bookmarks.dart';
import 'customer-stall-pages/search.dart';
import 'account-pages/account_profile.dart';

class CustomerNavBar extends StatefulWidget {
  final int currentIndex; 

  const CustomerNavBar({
    super.key,
    this.currentIndex = 0, 
  });

  @override
  State<CustomerNavBar> createState() => _CustomerNavBarState();
}

class _CustomerNavBarState extends State<CustomerNavBar> {
  late int _currentIndex;

  final List<Widget> _pages = const [
    StallsPage(), //stalls
    BookmarksPage(), //bookmarks
    SearchPage(), //search
    AccountPage(), //account
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
            label: "Stalls",
          ),
          BottomNavigationBarItem(
            icon: SizedBox(
              width: 26,
              height: 26,
              child: SvgPicture.asset('assets/icons/botnav-bookmark.svg'),
            ),
            activeIcon: SizedBox(
              width: 26,
              height: 26,
              child: SvgPicture.asset('assets/icons/botnav-bookmark-selected.svg'),
            ),
            label: "Bookmarks",
          ),
          BottomNavigationBarItem(
            icon: SizedBox(
              width: 26,
              height: 26,
              child: SvgPicture.asset('assets/icons/botnav-search.svg'),
            ),
            activeIcon: SizedBox(
              width: 26,
              height: 26,
              child: SvgPicture.asset('assets/icons/botnav-search-selected.svg'),
            ),
            label: "Search",
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
