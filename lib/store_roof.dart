import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class StoreRoof extends StatelessWidget {
  const StoreRoof({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final bannerHeight = screenWidth * 0.48;
    return Transform.translate(
      offset: const Offset(0, -30),
      child: Container(
        width: double.infinity,
        height: bannerHeight,
        child: SvgPicture.asset(
          'assets/icons/store-roof.svg',
          fit: BoxFit.cover,
          width: screenWidth,
        ),
      ),
    );
  }
}
