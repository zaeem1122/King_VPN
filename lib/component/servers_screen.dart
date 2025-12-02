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

  /// 🔥 Restore connected server selection when app restarts
  void _restoreSelectedServer() {
    final vpn = Provider.of<VpnConnectionProvider>(context, listen: false);
    final controller = Provider.of<ServersProvider>(context, listen: false);

    if (!vpn.isConnected) return;

    if (vpn.lastConnectedCountry == null || vpn.lastConnectedCountryCode == null) {
      return;
    }

    // find the index in THIS list of servers
    final index = widget.servers.indexWhere((s) =>
    s.country == vpn.lastConnectedCountry &&
        s.countryCode.toLowerCase() == vpn.lastConnectedCountryCode!.toLowerCase()
    );

    if (index != -1) {
      controller.setSelectedIndex(index);
      controller.setSelectedTab(widget.tab);
    }
  }

  void showProgressDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
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

  Future<void> connectToServer(VpnServer server, int index) async {
    final controller = Provider.of<ServersProvider>(context, listen: false);
    final controllerVPN = Provider.of<VpnProvider>(context, listen: false);
    final vpnConnectionProvider =
    Provider.of<VpnConnectionProvider>(context, listen: false);
    final adsProvider = Provider.of<AdsProvider>(context, listen: false);
    final apps = Provider.of<AppsProvider>(context, listen: false);

    /// Store selected server in UI
    controller.setSelectedIndex(index);
    controller.setSelectedTab(widget.tab);
    controllerVPN.vpnConfig = VpnConfig.fromJson(server.toJson());

    /// 🔥 Save this server as the last connected server immediately
    vpnConnectionProvider.lastConnectedCountry = server.country;
    vpnConnectionProvider.lastConnectedCountryCode = server.countryCode;
    vpnConnectionProvider.saveVpnState();

    // Disconnect if already connected
    final comp = vpnConnectionProvider.stage?.toString() == null
        ? "Disconnect"
        : vpnConnectionProvider.stage.toString().split('.').last;

    if (comp == "connected") {
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

    adsProvider.loadInterstitialAd().then((_) {
      adsProvider.showInterstitialAd();
    });

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

      Navigator.pop(context);
      Navigator.pop(context);
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
            final vpn = Provider.of<VpnConnectionProvider>(context);

            // 🔥 Show yellow tick if:
            // - user selected server this session
            // OR
            // - restored from saved last connected server
            final bool isSelected =
            (index == controller.getSelectedIndex() &&
                widget.tab == controller.getSelectedTab());

            return InkWell(
              onTap: () => connectToServer(widget.servers[index], index),
              child: ListTile(
                leading: Container(
                  height: 40,
                  width: 65,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    image: DecorationImage(
                      fit: BoxFit.cover,
                      image: AssetImage(
                        'icons/flags/png250px/${widget.servers[index].countryCode.toLowerCase()}.png',
                        package: 'country_icons',
                      ),
                    ),
                  ),
                ),
                title: Text(
                  widget.servers[index].country,
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
