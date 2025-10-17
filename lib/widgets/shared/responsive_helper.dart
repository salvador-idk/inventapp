import 'package:flutter/material.dart';

class ResponsiveHelper {
  static bool isMobile(BuildContext context) => 
      MediaQuery.of(context).size.width < 600;

  static bool isTablet(BuildContext context) => 
      MediaQuery.of(context).size.width >= 600 && 
      MediaQuery.of(context).size.width < 1200;

  static bool isDesktop(BuildContext context) => 
      MediaQuery.of(context).size.width >= 1200;

  static int getGridCrossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    
    if (width > 1400) return 5;
    if (width > 1200) return 4;
    if (width > 900) return 3;
    if (width > 600) return 2;
    return 1;
  }

  static double getGridAspectRatio(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    
    if (width > 1200) return 0.8;
    if (width > 600) return 0.75;
    return 0.7;
  }
}