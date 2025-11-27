// import 'package:flutter/material.dart';
//
// class ResponsiveHelper {
//   final BuildContext context;
//
//   ResponsiveHelper(this.context);
//
//   // Screen dimensions
//   double get screenHeight => MediaQuery.of(context).size.height;
//   double get screenWidth => MediaQuery.of(context).size.width;
//   double get screenSize => screenHeight * screenWidth;
//
//   // Safe area paddings
//   EdgeInsets get safeAreaPadding => MediaQuery.of(context).padding;
//   double get topPadding => safeAreaPadding.top;
//   double get bottomPadding => safeAreaPadding.bottom;
//
//   // Device type detection
//   bool get isMobile => screenWidth < 600;
//   bool get isTablet => screenWidth >= 600 && screenWidth < 1024;
//   bool get isLargeTablet => screenWidth >= 1024;
//
//   // Responsive scaling factors
//   double get scaleFactor {
//     if (isMobile) return 1.0;
//     if (isTablet) return 1.3;
//     return 1.5;
//   }
//
//   // Responsive height
//   double height(double mobileHeight) {
//     return screenHeight * (mobileHeight / 100) * scaleFactor;
//   }
//
//   // Responsive width
//   double width(double mobileWidth) {
//     return screenWidth * (mobileWidth / 100);
//   }
//
//   // Responsive font size
//   double fontSize(double baseFontSize) {
//     if (isMobile) return baseFontSize;
//     if (isTablet) return baseFontSize * 1.2;
//     return baseFontSize * 1.4;
//   }
//
//   // Responsive icon size
//   double iconSize(double baseSize) {
//     if (isMobile) return baseSize;
//     if (isTablet) return baseSize * 1.3;
//     return baseSize * 1.5;
//   }
//
//   // Responsive padding/margin
//   double spacing(double baseSpacing) {
//     if (isMobile) return baseSpacing;
//     if (isTablet) return baseSpacing * 1.2;
//     return baseSpacing * 1.4;
//   }
//
//   // Get responsive value based on device type
//   T getValue<T>({
//     required T mobile,
//     T? tablet,
//     T? largeTablet,
//   }) {
//     if (isLargeTablet && largeTablet != null) return largeTablet;
//     if (isTablet && tablet != null) return tablet;
//     return mobile;
//   }
//
//   // Container constraints for centered content on tablets
//   BoxConstraints get contentConstraints {
//     return BoxConstraints(
//       maxWidth: isMobile ? double.infinity : 600,
//     );
//   }
//
//   // Grid columns based on device
//   int get gridColumns {
//     if (isMobile) return 2;
//     if (isTablet) return 3;
//     return 4;
//   }
// }