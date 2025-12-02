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
  bool restoredFromAppStart = false;

  bool get isConnected => _isConnected;

  // 🔥 ADDED: To remember server after restart
  String? lastConnectedCountry;
  String? lastConnectedCountryCode;

  // ==================== SAVE STATE ====================
  Future<void> saveVpnState() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool('isConnected', _isConnected);

    if (lastConnectedCountry != null) {
      prefs.setString('lastCountry', lastConnectedCountry!);
    }
    if (lastConnectedCountryCode != null) {
      prefs.setString('lastCountryCode', lastConnectedCountryCode!);
    }
  }

  // ==================== RESTORE STATE ====================
  Future<void> restoreVpnState() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    _isConnected = prefs.getBool('isConnected') ?? false;

    lastConnectedCountry = prefs.getString('lastCountry');
    lastConnectedCountryCode = prefs.getString('lastCountryCode');

    if (_isConnected) {
      restoredFromAppStart = true;
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

        onVpnStageChanged: (vpnStage, raw) {
          stage = vpnStage;
          notifyListeners();

          if (vpnStage == VPNStage.connected) {
            _isConnected = true;
            saveVpnState();

            if (!restoredFromAppStart) {
              Fluttertoast.showToast(
                msg: "Connected Successfully",
                toastLength: Toast.LENGTH_LONG,
                gravity: ToastGravity.TOP,
                backgroundColor: Colors.blue,
                textColor: Colors.white,
                fontSize: 16.0,
              );

              Future.delayed(const Duration(seconds: 2), () {
                Fluttertoast.showToast(
                  msg: "Now you are protected",
                  toastLength: Toast.LENGTH_LONG,
                  gravity: ToastGravity.TOP,
                  backgroundColor: Colors.blue,
                  textColor: Colors.white,
                  fontSize: 16.0,
                );
              });
            }

            restoredFromAppStart = false;
          }

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
