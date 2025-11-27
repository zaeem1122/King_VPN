import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import 'package:vpnprowithjava/modals/vpnConfig.dart';
import 'package:vpnprowithjava/modals/vpnServer.dart';

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

    // Select server in UI
    controller.setSelectedIndex(index);
    controller.setSelectedTab(widget.tab);
    controllerVPN.vpnConfig = VpnConfig.fromJson(server.toJson());

    // Check if connected already and disconnect
    final comp = vpnConnectionProvider.stage?.toString() == null
        ? "Disconnect"
        : vpnConnectionProvider.stage.toString().split('.').last;

    if (comp == "connected") {
      vpnConnectionProvider.engine.disconnect();
      await Future.delayed(const Duration(seconds: 1));

      // Only allowed toast (disconnect toast)
      Fluttertoast.showToast(
        msg: "Disconnected from previous server",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.TOP,
        backgroundColor: Colors.orange,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    }

    // Start VPN connection
    vpnConnectionProvider.setRadius();

    adsProvider.loadInterstitialAd().then((_) {
      adsProvider.showInterstitialAd();
    });

    if (vpnConnectionProvider.getInitCheck()) {
      vpnConnectionProvider.initialize();
    }

    if (controllerVPN.vpnConfig != null) {
      showProgressDialog(context);

      await vpnConnectionProvider.initPlatformState(
        controllerVPN.vpnConfig!.ovpn,
        controllerVPN.vpnConfig!.country,
        apps.getDisallowedList,
        controllerVPN.vpnConfig!.username ?? "",
        controllerVPN.vpnConfig!.password ?? "",
      );

      await Future.delayed(const Duration(seconds: 3));
      Navigator.pop(context); // Close progress dialog
      Navigator.pop(context); // Close server list

      // NO TOAST HERE — Toast is now handled ONLY by provider (when actual connected)
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
                  color: index == controller.getSelectedIndex() &&
                      widget.tab == controller.getSelectedTab()
                      ? Colors.amber
                      : Colors.grey,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
