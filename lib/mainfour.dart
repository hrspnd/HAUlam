import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
// import 'package:haulam/screens/account-pages/dummy_account_profile.dart';
import 'customer-stall-pages/stalls.dart';
import 'customer-stall-pages/bookmarks.dart';
import 'customer-stall-pages/search.dart';
import 'account-pages/account_profile.dart';

class MainFourScaffold extends StatefulWidget {
  final int currentIndex; // <-- Add this to select initial tab

  const MainFourScaffold({
    super.key,
    this.currentIndex = 0, // default to Home
  });

  @override
  State<MainFourScaffold> createState() => _MainFourScaffoldState();
}

class _MainFourScaffoldState extends State<MainFourScaffold> {
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