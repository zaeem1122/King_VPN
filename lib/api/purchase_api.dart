// import 'package:purchases_flutter/purchases_flutter.dart';
//
// class PurchaseApi {
//   static const _apiKey = 'goog_NoYwHIkyjMzvjiPxWquGMAZAgiT';
//
//   static Future<void> init() async {
//     try {
//       await Purchases.setDebugLogsEnabled(true);
//       await Purchases.setup(_apiKey);
//     } catch (e) {
//       print('Initialization Error: $e');
//     }
//   }
// static Future<List<Offering>> fetchOffers() async {
//     try {
//       final offerings = await Purchases.getOfferings();
//       final current = offerings.current;
//       return current == null ? [] : [current];
//     } catch (e) {
//       print('Fetching Offers Error: $e');
//       return [];
//     }
//   }
//
//
//   static Future<bool>purchasePackage(Package package)async{
//     try{
//     await Purchases.purchasePackage(package);
//     return true;
//
//     }catch(e){
//       return false;
//     }
//   }
// }
