import 'dart:convert';
import 'package:flutter/material.dart';
import '../modals/vpnConfig.dart';
import '../modals/vpnServer.dart';
import '../providers/vpnProvider.dart';
import '../resources/environment.dart';
import 'httpConnection.dart';
import 'package:http/http.dart' as http;

class VpnServerHttp extends HttpConnection {
  VpnServerHttp(BuildContext context) : super(context);

  Future<List<VpnServer>> getServers(String type) async {
    print("📡 API CALL START: Fetching servers of type: $type");
    List<VpnServer> servers = [];
    // Map<String, String> header = {'auth_token': 'VBrcKTECHNO5566'}; origion
    // Map<String, String> header = {'auth_token': 'majid_vpn@4545'};
    Map<String, String> header = {'auth_token': 'vpn@majid20'};
    final res =
    await http.get(Uri.parse("${api}servers/$type"), headers: header);
    // print("${res.statusCode}:${res.body}");
    try {
      if (res.statusCode == 200) {
        var json = jsonDecode(res.body.toString());
        json = json['data'];
        for (final js in json) {
          servers.add(VpnServer.fromJson(js));
        }
        print("✅ API SUCCESS: Loaded ${servers.length} servers for $type");
      } else {
        print("❌ API FAILED: Status code ${res.statusCode}");
      }
    } catch (e) {
      print("⚠️ API ERROR: ${e.toString()}");
    }

    return servers;
  }

  Future<VpnConfig?> getBestServer(BuildContext context) async {
    print("📡 API CALL START: Fetching best VPN server");
    // Map<String, String> header = {'api_key': 'majid_vpn@4545'};
    Map<String, String> header = {'api_key': 'vpn@majid20'};
    final res = await http.get(Uri.parse("${api}servers"), headers: header);
    final vpn = VpnProvider.instance(context);

    if (res.statusCode == 200) {
      final json = jsonDecode(res.body.toString());
      VpnConfig server = VpnConfig.fromJson(json["data"]);
      vpn.vpnConfig = server;
      print("✅ API SUCCESS: Best VPN server loaded - ${server.country}");
    } else {
      print("❌ API FAILED: Status code ${res.statusCode}");
    }

    print("__________________________________________");
    return vpn.vpnConfig;
  }
}