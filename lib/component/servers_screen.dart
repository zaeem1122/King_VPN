import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import 'package:vpnprowithjava/modals/vpnConfig.dart';
import 'package:vpnprowithjava/modals/vpnServer.dart';
import 'package:openvpn_flutter/openvpn_flutter.dart';

import '../providers/ads_provider.dart';
import '../providers/appsProvider.dart';
import '../providers/servers_provider.dart';
import '../providers/vpnProvider.dart';
import '../providers/vpn_connection_provider.dart';

class ServersScreen extends StatefulWidget {
  final String tab;
  final List<VpnServer> servers;

  const ServersScreen({
    super.key,
    required this.servers,
    required this.tab,
  });

  @override
  State<ServersScreen> createState() => _ServersScreenState();
}

class _ServersScreenState extends State<ServersScreen> {

  @override
  void initState() {
    super.initState();
    _restoreSelectedServer();
  }

  /// 🔥 Restore last selected server from VPN connection provider
  void _restoreSelectedServer() {
    final vpn = Provider.of<VpnConnectionProvider>(context, listen: false);
    final controller = Provider.of<ServersProvider>(context, listen: false);

    // If no saved server, do nothing
    if (vpn.lastConnectedCountryCode == null) return;

    // Find server in this list
    final index = widget.servers.indexWhere((s) =>
    s.countryCode.toLowerCase() == vpn.lastConnectedCountryCode!.toLowerCase()
    );

    if (index != -1) {
      controller.setSelectedIndex(index);
      controller.setSelectedTab(widget.tab);
      controller.setSelectedServer(widget.servers[index]); // important for yellow highlight
    }
  }

  /// Show loading dialog while connecting
  void showProgressDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text("Connecting to VPN..."),
            ],
          ),
        );
      },
    );
  }

  /// Connect to selected server
  Future<void> connectToServer(VpnServer server, int index) async {
    final controller = Provider.of<ServersProvider>(context, listen: false);
    final controllerVPN = Provider.of<VpnProvider>(context, listen: false);
    final vpnConnectionProvider =
    Provider.of<VpnConnectionProvider>(context, listen: false);
    final adsProvider = Provider.of<AdsProvider>(context, listen: false);
    final apps = Provider.of<AppsProvider>(context, listen: false);

    // Update selected server in provider
    controller.setSelectedIndex(index);
    controller.setSelectedTab(widget.tab);
    controller.setSelectedServer(server);

    controllerVPN.vpnConfig = VpnConfig.fromJson(server.toJson());

    // Save as last connected server
    vpnConnectionProvider.lastConnectedCountry = server.country;
    vpnConnectionProvider.lastConnectedCountryCode = server.countryCode;
    await vpnConnectionProvider.saveVpnState();

    // Disconnect if already connected
    if (vpnConnectionProvider.stage == VPNStage.connected) {
      vpnConnectionProvider.engine.disconnect();
      await Future.delayed(const Duration(seconds: 1));
      Fluttertoast.showToast(
        msg: "Disconnected from previous server",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.TOP,
        backgroundColor: Colors.orange,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    }

    vpnConnectionProvider.setRadius();

    // Show interstitial ad if loaded
    adsProvider.loadInterstitialAd().then((_) => adsProvider.showInterstitialAd());

    // Initialize VPN engine if not already
    if (vpnConnectionProvider.getInitCheck()) {
      vpnConnectionProvider.initialize();
    }

    if (controllerVPN.vpnConfig != null) {
      showProgressDialog(context);

      vpnConnectionProvider.triedToConnect = true;

      await vpnConnectionProvider.initPlatformState(
        controllerVPN.vpnConfig!.ovpn,
        controllerVPN.vpnConfig!.country,
        apps.getDisallowedList,
        controllerVPN.vpnConfig!.username ?? "",
        controllerVPN.vpnConfig!.password ?? "",
      );

      Navigator.pop(context); // Close progress dialog
      Navigator.pop(context); // Close server screen
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<ServersProvider>(context);

    if (widget.servers.isEmpty) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text(
            "No Servers Found",
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5.0),
        child: ListView.separated(
          separatorBuilder: (_, __) => const Divider(color: Colors.grey),
          itemCount: widget.servers.length,
          itemBuilder: (context, index) {
            final server = widget.servers[index];

            // Yellow tick if server is selected
            final bool isSelected =
            (index == controller.getSelectedIndex() &&
                widget.tab == controller.getSelectedTab());

            return InkWell(
              onTap: () => connectToServer(server, index),
              child: ListTile(
                leading: Container(
                  height: 40,
                  width: 65,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    image: DecorationImage(
                      fit: BoxFit.cover,
                      image: AssetImage(
                        'icons/flags/png250px/${server.countryCode.toLowerCase()}.png',
                        package: 'country_icons',
                      ),
                    ),
                  ),
                ),
                title: Text(
                  server.country,
                  style: const TextStyle(fontSize: 18, color: Colors.white),
                ),
                trailing: Icon(
                  Icons.check_circle,
                  size: 30,
                  color: isSelected ? Colors.amber : Colors.grey,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
