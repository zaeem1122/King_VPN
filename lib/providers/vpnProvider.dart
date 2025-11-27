import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
        await loadBestServerOnAppStart(ctx);
      }
    });
  }

  /// Setter
  set vpnConfig(VpnConfig? vpnConfig) {
    _vpnConfig = vpnConfig;
    notifyListeners();
  }

  /// Getter
  VpnConfig? get vpnConfig => _vpnConfig;

  /// Static instance helper
  static VpnProvider instance(BuildContext context) =>
      Provider.of(context, listen: false);

  /// AUTO LOAD BEST SERVER FROM API
  Future<void> loadBestServerOnAppStart(BuildContext context) async {
    try {
      await VpnServerHttp(context).getBestServer(context);
      print("Best server loaded on app start ✔");
    } catch (e) {
      print("Error loading best server: $e");
    }
  }
}
