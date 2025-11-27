// import 'package:flutter/material.dart';
// import 'package:vpnprowithjava/api/purchase_api.dart';
//
// fetchOffers(BuildContext context) async {
//   final offerings = await PurchaseApi.fetchOffers();
//
//   if (offerings.isEmpty) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text('No Plans Found')),
//     );
//   } else {
//     final packages = offerings
//         .map((offer) => offer.availablePackages)
//         .expand((pair) => pair)
//         .toList();
//
//     // Do something with the packages, if needed
//   }
// }
//
//
// // Utils.showSheet (
// //   context,(context) =>PaywallWidget(
// //     packages.packages,
// //     title:'hsfhfsjhfsj',
// //     description:'fdddddddddddddd',
// //     onClickedPackage:(package) async{
// //       await PurchaseApi.purchasePackage(package);
// //       Navigator.pop(context);
// //     }
// //   )
// // );
