import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../modals/vpnServer.dart';

class ServersProvider with ChangeNotifier {
  int selectedIndex = 0;
  late VpnServer _selectedServer;
  String selectedTab = "free";
  List<VpnServer> _freeServers = [];
  List<VpnServer> _proServers = [];
  bool _isLoading = false;

  // Add this for restoring
  Future<void> restoreSelectedServer() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? lastCountryCode = prefs.getString('lastCountryCode');

    if (lastCountryCode != null) {
      // Find server in free servers
      VpnServer? server = _freeServers.firstWhere(
            (s) => s.countryCode == lastCountryCode,
        orElse: () => _proServers.firstWhere(
              (s) => s.countryCode == lastCountryCode,
          orElse: () => _freeServers.isNotEmpty ? _freeServers[0] : _proServers[0],
        ),
      );

      _selectedServer = server;
      selectedIndex = (_freeServers + _proServers).indexOf(server);
      notifyListeners();
    }
  }

  void setLoading(bool isLoading) {
    _isLoading = isLoading;
    notifyListeners();
  }

  bool get isLoading => _isLoading;

  VpnServer get selectedServer => _selectedServer;

  List<VpnServer> get freeServers => _freeServers;

  List<VpnServer> get proServers => _proServers;

  int getSelectedIndex() => selectedIndex;

  String getSelectedTab() => selectedTab;


  void setSelectedServer(VpnServer server) {
    _selectedServer = server;

    int index = _freeServers.indexOf(server);
    if (index == -1) index = _proServers.indexOf(server);

    if (index != -1) selectedIndex = index;

    notifyListeners();
  }

  void setSelectedIndex(int index) {
    selectedIndex = index;
    notifyListeners();
  }

  void setSelectedTab(String tab) {
    selectedTab = tab;
    notifyListeners();
  }

  void setFreeServers(List<VpnServer> servers) {
    _freeServers = servers;
    notifyListeners();
  }

  void setProServers(List<VpnServer> servers) {
    _proServers = servers;
    notifyListeners();
  }
}
