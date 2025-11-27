// import 'package:flutter/material.dart';
// import 'package:persistent_bottom_nav_bar/persistent_tab_view.dart';
// import 'package:vpnprowithjava/my_icons_icons.dart';
// import 'package:vpnprowithjava/screens/subscription.dart';

// import '../screens/home screen.dart';
// import '../screens/more screen.dart';

// class bottom_navigator extends StatefulWidget {
//   const bottom_navigator({super.key});

//   @override
//   State<bottom_navigator> createState() => _bottom_navigatorState();
// }

// class _bottom_navigatorState extends State<bottom_navigator> {
   
// final controller = PersistentTabController(initialIndex: 0);


// List<Widget> _buildScreens(){
  
// return [
// FirstScreen(),
//  RemoveAdsScreen(),
// ];
//   }
  
// List<PersistentBottomNavBarItem>_navBarsItems(){
// return[
//   PersistentBottomNavBarItem(  
//     icon: new Icon(MyIcons.shield_check_outline, color: Colors.green,),
//     inactiveIcon: new Icon(MyIcons.shield_check_outline, color: Colors.white,),
//     title: ('VPN'),
//     activeColorPrimary: Colors.green,
//     inactiveColorPrimary: Colors.white,
//   ),
//   PersistentBottomNavBarItem(  
//     icon: new Icon(MyIcons.more_01__1_,color:Colors.green, size: 23,),
//     inactiveIcon: new Icon(MyIcons.more_01__1_,color:Colors.white,size: 20,),
//     title: ('More'),
//     activeColorPrimary: Colors.green,
//     inactiveColorPrimary:Colors.white,
//   )
//     ];
//   }
  
//   @override
//   Widget build(BuildContext context) {
//  return 
//   PersistentTabView(
//          context,
//           controller: controller,
//          confineInSafeArea: true,
//          handleAndroidBackButtonPress: true, 
//          hideNavigationBarWhenKeyboardShows:false, 
//          popAllScreensOnTapAnyTabs: true,
//           screens: _buildScreens(), 
//           items: _navBarsItems(),
//           onItemSelected: (item) {
//           controller.index = item;
//           setState(() {});},
//  backgroundColor:  Colors.grey.shade900,
//         decoration: NavBarDecoration(
//         borderRadius: BorderRadius.circular(0.0),
//         colorBehindNavBar: Color.fromARGB(255, 238, 231, 231),
//         ),
//         navBarStyle: NavBarStyle.style6,
//  );
//  }
// }
