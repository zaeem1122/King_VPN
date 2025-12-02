import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../https/vpnServerHttp.dart';
import '../modals/vpnConfig.dart';
import '../main.dart'; // for navigatorKey

class VpnProvider extends ChangeNotifier {
  VpnConfig? _vpnConfig;

  /// Used to prevent showing toast repeatedly
  bool hasShownToast = false;

  VpnProvider() {
    /// Auto-load best server when provider initializes
    Future.delayed(Duration.zero, () async {
      final ctx = navigatorKey.currentContext;
      if (ctx != null) {
        // Load saved config first, then best server if none exists
        await loadVpnConfig();
        if (_vpnConfig == null) {
          await loadBestServerOnAppStart(ctx);
        }
      }
    });
  }

  /// Setter - Auto-save when config changes
  set vpnConfig(VpnConfig? vpnConfig) {
    _vpnConfig = vpnConfig;
    notifyListeners();
    // Auto-save whenever config changes
    if (vpnConfig != null) {
      saveVpnConfig();
    }
  }

  /// Getter
  VpnConfig? get vpnConfig => _vpnConfig;

  /// Static instance helper
  static VpnProvider instance(BuildContext context) =>
      Provider.of(context, listen: false);

  /// Save VPN config to SharedPreferences
  Future<void> saveVpnConfig() async {
    if (_vpnConfig != null) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setInt('vpn_id', _vpnConfig!.id);
      await prefs.setString('vpn_country', _vpnConfig!.country);
      await prefs.setString('vpn_country_code', _vpnConfig!.countryCode);
      await prefs.setString('vpn_ovpn', _vpnConfig!.ovpn);
      await prefs.setString('vpn_username', _vpnConfig!.username ?? '');
      await prefs.setString('vpn_password', _vpnConfig!.password ?? '');
      await prefs.setString('vpn_state', _vpnConfig!.state);
      await prefs.setString('vpn_ip_address', _vpnConfig!.ipAddress);
      await prefs.setString('vpn_ispro', _vpnConfig!.ispro);
      print("✔ VPN config saved: ${_vpnConfig!.country}");
    }
  }

  /// Load VPN config from SharedPreferences
  Future<void> loadVpnConfig() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? id = prefs.getInt('vpn_id');
    String? country = prefs.getString('vpn_country');
    String? countryCode = prefs.getString('vpn_country_code');
    String? ovpn = prefs.getString('vpn_ovpn');
    String? username = prefs.getString('vpn_username');
    String? password = prefs.getString('vpn_password');
    String? state = prefs.getString('vpn_state');
    String? ipAddress = prefs.getString('vpn_ip_address');
    String? ispro = prefs.getString('vpn_ispro');

    if (id != null && country != null && countryCode != null && ovpn != null && state != null && ipAddress != null && ispro != null) {
      // Recreate VpnConfig object with all required parameters
      _vpnConfig = VpnConfig(
        id: id,
        country: country,
        countryCode: countryCode,
        ovpn: ovpn,
        username: username?.isNotEmpty == true ? username : null,
        password: password?.isNotEmpty == true ? password : null,
        state: state,
        ipAddress: ipAddress,
        ispro: ispro,
      );
      notifyListeners();
      print("✔ VPN config loaded: $country (ID: $id)");
    } else {
      print("⚠ No saved VPN config found");
    }
  }

  /// Clear saved VPN config
  Future<void> clearVpnConfig() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('vpn_id');
    await prefs.remove('vpn_country');
    await prefs.remove('vpn_country_code');
    await prefs.remove('vpn_ovpn');
    await prefs.remove('vpn_username');
    await prefs.remove('vpn_password');
    await prefs.remove('vpn_state');
    await prefs.remove('vpn_ip_address');
    await prefs.remove('vpn_ispro');
    _vpnConfig = null;
    notifyListeners();
    print("✔ VPN config cleared");
  }

  /// AUTO LOAD BEST SERVER FROM API
  Future<void> loadBestServerOnAppStart(BuildContext context) async {
    try {
      await VpnServerHttp(context).getBestServer(context);
      print("✔ Best server loaded on app start");
    } catch (e) {
      print("❌ Error loading best server: $e");
    }
  }
}