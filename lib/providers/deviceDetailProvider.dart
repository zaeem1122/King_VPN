import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';

class DeviceDetailProvider extends ChangeNotifier {
  AndroidDeviceInfo? androidInfo;
  var _uuid = "";
  get uuid => _uuid;

  AndroidDeviceInfo get deviceInfo => androidInfo!;

  void getDeviceInfo(var id) async {
    androidInfo = await DeviceInfoPlugin().androidInfo;
    print("Device ID : ${androidInfo!.data}");
    _uuid = id;
  }
}
