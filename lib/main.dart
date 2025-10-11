import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:haulam/auth-backend/auth_gate.dart';
import 'package:haulam/auth-backend/auth_page.dart';
import 'package:haulam/auth-backend/testpage.dart';
import 'package:haulam/screens/account-pages/account_details.dart';
import 'package:haulam/screens/customer-stall-pages/bookmarks.dart';
import 'package:haulam/screens/customer-stall-pages/stalls.dart';
import 'package:haulam/screens/customer-stall-pages/stall_dish_view.dart';
import 'package:haulam/screens/account-pages/account_profile.dart';
import 'package:haulam/screens/account-pages/twofactorauth.dart';
import 'package:haulam/screens/account-pages/changepassword.dart';
import 'package:haulam/screens/account-pages/resetpassword.dart';
import 'package:haulam/screens/account-pages/editaccount.dart';
import 'package:haulam/screens/signup-login-pages/loginpage.dart';
import 'package:haulam/screens/signup-login-pages/successpage.dart';
import 'package:haulam/screens/vendor-view-pages/create_stall.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/signup-login-pages/otppage.dart';

import 'screens/customer-stall-pages/stall_dishes.dart';
// import 'screens/signup-login-pages/signuppage.dart';
import 'screens/mainfour.dart';
import 'screens/store_roof.dart';
import 'package:haulam/screens/signup-login-pages/splashpage.dart';
import 'models/menu_item.dart';
import 'models/stalls_model.dart';

import 'screens/maintwo.dart';
import 'screens/vendor-view-pages/vendor_stall.dart';
import 'screens/vendor-view-pages/vendor_dish_view.dart';
import 'screens/vendor-view-pages/vendor_edit_profile.dart';
import 'screens/customer-stall-pages/search.dart';

// import 'screens/signup-login pages/splashpage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: "https://oawyynxtwzwwfvomiwcy.supabase.co",
    anonKey:
        "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9hd3l5bnh0d3p3d2Z2b21pd2N5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTk1NDYyNDksImV4cCI6MjA3NTEyMjI0OX0.qyBc7-vbxYhgyNoRyGJ8PMIP_k6bHsrrblZxINGqxpA",
  );
  // =======================

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]).then((_) {
    runApp(const MyApp());
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // ===== Global Font =====
        fontFamily: 'Onest',
        // =======================
        // ===== Navbar Hover Color =====
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        hoverColor: Colors.transparent,
        // ==============================
        // ===== Circle Progress Color =====
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: Colors.grey,
        ),
        // =================================
        textSelectionTheme: const TextSelectionThemeData(
          cursorColor: Colors.black, //makes cursor black globally
          selectionColor: Color(0x30710E1D), //highlight color
          selectionHandleColor: Color(0xff710E1D), //handle color
        ),
        scaffoldBackgroundColor: Colors.white,

        // ===== GLOBAL OUTLINE / FOCUS COLOR =====
        inputDecorationTheme: InputDecorationTheme(
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xff65000F), width: 2),
          ),
        ),
      ),

      // home: const StallsPage(),
      // home: SignUpPage(showLoginPage: () {  },),
      // home: const LoginPage(),
      // home: const OtpPage(phoneNumber: '87132789123',),
      // home: const SetUpPage(),
      // home: const SuccessPage(),
      // home: const AccountPage(),
      // home: const AccountDetailsPage(),
      // home: const TwoFactorAuthenticationPage(),
      // home: const ChangePasswordPage(),
      // home: const ResetPasswordPage(), 
      // home: const EditAccountPage(), 
      // home: const MainFourScaffold(), // <------------------- YAM
      // home: const StoreRoof(),
      // home: const BookmarksPage(),
      // home: const MainTwoScaffold(),
      // home: const VendorStallPage(),
      // home: const VendorEditProfilePage(),
      // home: VendorDishViewPage(),
      // home: SearchPage(), 
      // home: CreateStallPage(),

      // home: StallDishesPage( // <------------------- JOSIE
      //   stall: Stall(
      //     id: '1',
      //     imagePath: 'assets/png/image-square.png',
      //     title: 'KIRSTENJOY',
      //     status: 'Open',
      //     location: 'St. Martha Hall'
      //   ),
      // ),

      // home: StallDishViewPage(
      //   stall: Stall(
      //     id: 'sample-id',
      //     imagePath: 'assets/sample.png',
      //     title: 'KIRSTENJOY',
      //     status: 'Open',
      //     isFavorited: false,
      //     location: 'PGN Basement',
      //   ),
      //   dish: MenuItem(
      //     id: 'dish-1',
      //     name: 'Tocino',
      //     imagePath: 'assets/png/tocino.png',
      //     price: 80,
      //     description: 'Chopped pork seasoned with spices, onions, and calamansi, served on a sizzling plate for a zesty, savory experience.',
      //     tags: ['Pork', 'Spicy', 'Something', 'LOLS'],
      //   ),
      // ),

      // home: TestProfilePage(),      <---- test info fetcher

      // home: const Wrapper(),

      // home: const AuthGate()

      // eto yung totoong home
      home: const SplashPage(),
    );
  }
}
