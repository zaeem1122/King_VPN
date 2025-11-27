import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:openvpn_flutter/openvpn_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class VpnConnectionProvider with ChangeNotifier {
  double radius = 0;
  bool hasShownToast = false;
  bool triedToConnect = false;

  bool _isInitialized = false;
  bool _isConnected = false;

  bool get isConnected => _isConnected;

  Future<void> saveVpnState() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool('isConnected', _isConnected);
  }

  Future<void> restoreVpnState() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _isConnected = prefs.getBool('isConnected') ?? false;

    if (_isConnected) {
      initialize();
    }
  }

  void setRadius() {
    radius = 0.25;
    notifyListeners();
  }

  void resetRadius() {
    radius = 0;
    notifyListeners();
  }

  late OpenVPN engine;
  VpnStatus? status;
  VPNStage? stage;

  bool _init = true;

  bool getInitCheck() => _init;

  String defaultVpnUsername = "freeopenvpn";
  String defaultVpnPassword = "605196725";
  String config = "YOUR OPENVPN CONFIG HERE";

  // ==================== INITIALIZE ENGINE ====================
  void initialize() {
    if (!_isInitialized) {
      engine = OpenVPN(
        onVpnStatusChanged: (data) {
          status = data;
          notifyListeners();
        },

        // ❤️ THE IMPORTANT FIX IS HERE ❤️
        onVpnStageChanged: (vpnStage, raw) {
          stage = vpnStage;
          notifyListeners();

          if (vpnStage == VPNStage.connected) {
            _isConnected = true;
            saveVpnState();

            // Show toast ONLY when VPN is fully connected
            Fluttertoast.showToast(
              msg: "Connected Successfully",
              toastLength: Toast.LENGTH_LONG,
              gravity: ToastGravity.TOP,
              backgroundColor: Colors.blue,
              textColor: Colors.white,
              fontSize: 16.0,
              timeInSecForIosWeb: 5,
            );

            Future.delayed(const Duration(seconds: 5), () {
              Fluttertoast.showToast(
                msg: "Now you are protected",
                toastLength: Toast.LENGTH_LONG,
                gravity: ToastGravity.TOP,
                backgroundColor: Colors.blue,
                textColor: Colors.white,
                fontSize: 16.0,
                timeInSecForIosWeb: 5,
              );
            });
          }

          // RESET STATE WHEN DISCONNECTED
          if (vpnStage == VPNStage.disconnected) {
            _isConnected = false;
            saveVpnState();
          }
        },
      );

      engine.initialize(
        groupIdentifier: "group.com.laskarmedia.vpn",
        providerBundleIdentifier: "id.laskarmedia.openvpn_flutter.OpenVPNFlutterPlugin",
        localizedDescription: "VPN by Nizwar",
        lastStage: (stageValue) {
          stage = stageValue;
          notifyListeners();
        },
        lastStatus: (statusValue) {
          status = statusValue;
          notifyListeners();
        },
      );

      _isInitialized = true;
      notifyListeners();
    }
  }

  // ==================== CONNECT VPN ====================
  Future<void> initPlatformState(
      String ovpn,
      String country,
      List<String> disallowedList,
      String username,
      String pass,
      ) async {
    config = ovpn;

    engine.connect(
      config,
      country,
      username: username,
      password: pass,
      bypassPackages: disallowedList,
      certIsRequired: true,
    );

    notifyListeners();
  }
}
