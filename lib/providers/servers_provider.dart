import 'package:flutter/material.dart';
import '../modals/vpnServer.dart';

class ServersProvider with ChangeNotifier {
  int selectedIndex = 0;
  late VpnServer _selectedServer;
  String selectedTab = "free";
  List<VpnServer> _freeServers = [];
  List<VpnServer> _proServers = [];
  bool _isLoading = false;

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
