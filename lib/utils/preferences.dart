// import 'dart:ui';
// import 'package:shared_preferences/shared_preferences.dart';

// class Preferences {
//   final SharedPreferences shared;
//   Preferences(this.shared);

//   String? get vpnToken => shared.getString("token");
//   String? get protocol => shared.getString("protocol");
//   bool get privacyPolicy => shared.containsKey('privacy-policy')
//       ? shared.getBool("privacy-policy") ?? false
//       : false;
//   bool get firstOpen => shared.containsKey('first_open')
//       ? shared.getBool("first_open") ?? false
//       : false;
//   List<String> get whitePackages =>
//       shared.getStringList("white_packages") ?? [];

//   Locale? get locale => shared.getString("lang_code") == null
//       ? null
//       : Locale(shared.getString("lang_code") ?? "en",
//           shared.getString("country_code"));

//   Future saveLocale(Locale locale) async {
//     shared.setString("lang_code", locale.languageCode);
//     if (locale.countryCode != null)
//       shared.setString("country_code", locale.countryCode!);
//   }

//   Future saveFirstOpen() {
//     return shared.setBool("first_open", true);
//   }

//   Future saveVpnToken(String token) {
//     return shared.setString("token", token);
//   }

//   Future saveProtocol(String protocol) {
//     return shared.setString("protocol", protocol);
//   }

//   Future acceptPrivacyPolicy() {
//     return shared.setBool("privacy-policy", true);
//   }

//   Future saveWhitePages(List<String> list) {
//     return shared.setStringList("white_packages", list);
//   }

//   static Future<Preferences> init() =>
//       SharedPreferences.getInstance().then((value) => Preferences(value));
// }
