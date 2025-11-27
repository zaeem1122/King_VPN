import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:openvpn_flutter/openvpn_flutter.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simple_ripple_animation/simple_ripple_animation.dart';
import 'package:starsview/starsview.dart';
import 'package:store_redirect/store_redirect.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vpnprowithjava/component/animation_gif.dart';
import 'package:vpnprowithjava/modals/ApplicationModel.dart';
import 'package:vpnprowithjava/screens/allowed_app_screen.dart';
import 'package:vpnprowithjava/screens/more%20screen.dart';
import 'package:vpnprowithjava/screens/server%20screen.dart';

import '../../https/vpnServerHttp.dart';
import '../../providers/ads_provider.dart';
import '../../providers/appsProvider.dart';
import '../../providers/deviceDetailProvider.dart';
import '../../providers/servers_provider.dart';
import '../../providers/vpnProvider.dart';
import '../../providers/vpn_connection_provider.dart';
import '../../utils/GetApps.dart';
import '../resources/prefs.dart';

// ============= ENHANCED RESPONSIVE HELPER =============
class _ResponsiveHelper {
  final BuildContext context;
  late final Size _size;
  late final EdgeInsets _padding;
  late final double _textScaleFactor;

  _ResponsiveHelper(this.context) {
    _size = MediaQuery.of(context).size;
    _padding = MediaQuery.of(context).padding;
    _textScaleFactor = MediaQuery.of(context).textScaleFactor;
  }

  // Screen dimensions
  double get screenHeight => _size.height;
  double get screenWidth => _size.width;
  EdgeInsets get safeAreaPadding => _padding;
  double get topPadding => _padding.top;
  double get bottomPadding => _padding.bottom;

  // Device type detection
  bool get isMobile => screenWidth < 600;
  bool get isTablet => screenWidth >= 600 && screenWidth < 1024;
  bool get isLargeTablet => screenWidth >= 1024;
  bool get isSmallPhone => screenWidth < 360;
  bool get isLargePhone => screenWidth >= 360 && screenWidth < 600;

  // Diagonal size for better scaling
  double get diagonal => _size.shortestSide;

  // Aspect ratio
  double get aspectRatio => screenHeight / screenWidth;
  bool get isTallScreen => aspectRatio > 2.0;
  bool get isWideScreen => aspectRatio < 1.5;

  // Base scale factors
  double get baseScale {
    if (isSmallPhone) return 0.85;
    if (isLargePhone) return 1.0;
    if (isTablet) return 1.2;
    return 1.4;
  }

  // Responsive height calculation
  double height(double pixels) {
    const baseHeight = 844.0; // iPhone 14 Pro height
    return (screenHeight / baseHeight) * pixels;
  }

  // Responsive width calculation
  double width(double pixels) {
    const baseWidth = 390.0; // iPhone 14 Pro width
    return (screenWidth / baseWidth) * pixels;
  }

  // Font size with text scale factor consideration
  double fontSize(double base) {
    double scale = (screenWidth / 390) * baseScale;
    // Clamp the text scale factor to prevent extreme sizes
    double clampedTextScale = _textScaleFactor.clamp(0.8, 1.3);
    return (base * scale) / clampedTextScale;
  }

  // Icon size scaling
  double iconSize(double base) {
    double scale = (diagonal / 390) * baseScale;
    return base * scale;
  }

  // Spacing calculation
  double spacing(double base) {
    double scale = (screenWidth / 390) * baseScale;
    return base * scale;
  }

  // Radius calculation
  double radius(double base) {
    return spacing(base);
  }

  // Button size calculation
  double buttonSize(double base) {
    double scale = (diagonal / 390) * baseScale;
    return base * scale;
  }

  // Responsive value getter
  T getValue<T>({
    required T mobile,
    T? smallPhone,
    T? largePhone,
    T? tablet,
    T? largeTablet,
  }) {
    if (isLargeTablet && largeTablet != null) return largeTablet;
    if (isTablet && tablet != null) return tablet;
    if (isLargePhone && largePhone != null) return largePhone;
    if (isSmallPhone && smallPhone != null) return smallPhone;
    return mobile;
  }

  // Content constraints for larger screens
  BoxConstraints get contentConstraints {
    return BoxConstraints(
      maxWidth: isMobile ? double.infinity : 600,
    );
  }

  // Drawer width
  double get drawerWidth {
    if (isLargeTablet) return 450.0;
    if (isTablet) return 400.0;
    return screenWidth * 0.75;
  }
}

// ============= MAIN SCREEN =============
class FirstScreen extends StatefulWidget {
  const FirstScreen({super.key});

  @override
  State<FirstScreen> createState() => _FirstScreenState();
}

class _FirstScreenState extends State<FirstScreen> {
  bool _isConnected = false;
  var v5;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    checkForFlexibleUpdate();
    _getServers();
    _getAllApps();
    _connectivitySubscription =
        Connectivity().onConnectivityChanged.listen(_updateConnectionStatus);
    _loadAppState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Provider.of<AdsProvider>(context, listen: false).loadAds();
      await Provider.of<AdsProvider>(context, listen: false)
          .loadInterstitialAd();
      await Provider.of<VpnConnectionProvider>(context, listen: false)
          .restoreVpnState();
    });
  }

  @override
  void dispose() {
    super.dispose();
    _connectivitySubscription?.cancel();
    _saveAppState();
  }

  Future<void> checkForFlexibleUpdate() async {
    try {
      AppUpdateInfo info = await InAppUpdate.checkForUpdate();
      if (info.updateAvailability == UpdateAvailability.updateAvailable &&
          info.flexibleUpdateAllowed) {
        showUpdateDialog(info);
      }
    } catch (e) {
      print("Update check failed: $e");
    }
  }

  void showUpdateDialog(AppUpdateInfo info) {
    final r = _ResponsiveHelper(context);
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(r.radius(20)),
            side: const BorderSide(color: Colors.grey, width: 0.6),
          ),
          title: Text(
            "Update Available",
            style: TextStyle(
              color: Colors.white,
              fontSize: r.fontSize(18),
              fontWeight: FontWeight.w600,
            ),
          ),
          backgroundColor: Colors.black87,
          content: Text(
            "A new version of the app is available. Please update from the Play Store.",
            style: TextStyle(
              color: Colors.white,
              fontSize: r.fontSize(14),
            ),
          ),
          actions: [
            TextButton(
              child: Text(
                "Not Now",
                style: TextStyle(
                  color: Colors.red,
                  fontSize: r.fontSize(14),
                ),
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: EdgeInsets.symmetric(
                  horizontal: r.spacing(16),
                  vertical: r.spacing(8),
                ),
              ),
              child: Text(
                "Update",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: r.fontSize(14),
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                openPlayStore();
              },
            ),
          ],
        );
      },
    );
  }

  void openPlayStore() async {
    final Uri url = Uri.parse(
      "https://play.google.com/store/apps/details?id=com.kingwire.kingvpn",
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      print("Could not launch Play Store");
    }
  }

  _getAllApps() async {
    await Provider.of<AppsProvider>(context, listen: false).setDisallowList();
    List<ApplicationModel> appsList = [];
    Provider.of<AppsProvider>(context, listen: false).updateLoader(true);
    final apps = await GetApps.GetAllAppInfo();
    for (final app in apps) {
      appsList.add(ApplicationModel(isSelected: true, app: app));
    }
    Provider.of<AppsProvider>(context, listen: false).setAllApps(appsList);
    Provider.of<AppsProvider>(context, listen: false).updateLoader(false);
    Provider.of<DeviceDetailProvider>(context, listen: false).getDeviceInfo(v5);
  }

  _getServers() async {
    final myProvider = Provider.of<ServersProvider>(context, listen: false);
    myProvider.setLoading(true);
    // await VpnServerHttp(context).getBestServer(context);
    if (myProvider.freeServers.isEmpty || myProvider.proServers.isEmpty) {
      final free = await VpnServerHttp(context).getServers("free");
      myProvider.setFreeServers(free);
      final pro = await VpnServerHttp(context).getServers("premium");
      myProvider.setProServers(pro);
      myProvider.setLoading(false);
    }
  }

  Future<void> _saveAppState() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool('isConnected', _isConnected);
    prefs.setBool('showSnackbar', _isConnected);
  }

  Future<void> _loadAppState() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _isConnected = prefs.getBool('isConnected') ?? false;
      bool showSnackbar = prefs.getBool('showSnackbar') ?? false;
      if (showSnackbar) {
        showPersistentSnackbar("Connected", context);
      }
    });
  }

  void _updateConnectionStatus(List<ConnectivityResult> result) {
    final r = _ResponsiveHelper(context);
    if (result.contains(ConnectivityResult.none)) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(r.radius(16)),
            ),
            title: Text(
              'No Internet Connection',
              style: TextStyle(
                fontSize: r.fontSize(18),
                fontWeight: FontWeight.w600,
              ),
            ),
            content: Text(
              'Please check your internet connection.',
              style: TextStyle(fontSize: r.fontSize(14)),
            ),
            actions: <Widget>[
              TextButton(
                child: Text(
                  'OK',
                  style: TextStyle(fontSize: r.fontSize(14)),
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          );
        },
      );
    } else {
      setState(() {
        _isConnected = true;
      });
      _saveAppState();
    }
  }

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  void _openDrawer() {
    _scaffoldKey.currentState!.openDrawer();
  }

  double bytesPerSecondToMbps(double bytesPerSecond) {
    const bitsInByte = 8;
    const bitsInMegabit = 1000000;
    return (bytesPerSecond * bitsInByte) / bitsInMegabit;
  }

  @override
  Widget build(BuildContext context) {
    final r = _ResponsiveHelper(context);

    void showProgressDialog(BuildContext context) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(r.radius(16)),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                SizedBox(height: r.spacing(16)),
                Text(
                  "Connecting to VPN...",
                  style: TextStyle(fontSize: r.fontSize(14)),
                ),
              ],
            ),
          );
        },
      );
    }

    return Scaffold(
      key: _scaffoldKey,
      drawer: _buildDrawer(r),
      body: Container(
        height: r.screenHeight,
        width: r.screenWidth,
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            radius: 0.45,
            colors: [Colors.black, Colors.black],
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: r.contentConstraints,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  height: r.screenHeight,
                  width: r.screenWidth,
                  child: const StarsView(fps: 60),
                ),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    _buildAnimatedBackgrounds(r),
                    _buildMainUI(r, showProgressDialog),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============= DRAWER =============
  Widget _buildDrawer(_ResponsiveHelper r) {
    return Drawer(
      backgroundColor: Colors.black,
      width: r.drawerWidth,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            padding: EdgeInsets.all(r.spacing(25)),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue, Colors.black],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Container(
              height: r.height(50),
              width: r.width(150),
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage("assets/images/ggg.png"),
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          _buildDrawerItem(
            r,
            Icons.app_settings_alt_outlined,
            "Allowed Apps",
                () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const AllowedAppsScreen(),
              ),
            ),
          ),
          const Divider(height: 2, color: Color.fromARGB(255, 218, 218, 218)),
          _buildDrawerItem(r, Icons.block, "Remove Ads", () {
            try {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const RemoveAdsScreen(),
                ),
              );
            } catch (e) {
              print("Navigation Error: $e");
            }
          }),
          const Divider(height: 2, color: Color.fromARGB(255, 218, 218, 218)),
          _buildDrawerItem(r, Icons.info_outline, "Share", () {
            Share.share(
              'https://play.google.com/store/apps/details?id=com.kingwire.kingvpn',
            );
          }),
          const Divider(height: 2, color: Color.fromARGB(255, 218, 218, 218)),
          _buildDrawerItem(r, Icons.star_border, "Rate this app", () {
            StoreRedirect.redirect(androidAppId: 'com.kingwire.kingvpn');
          }),
          const Divider(height: 2, color: Color.fromARGB(255, 218, 218, 218)),
          _buildDrawerItem(r, Icons.feedback, "Feedback", () {
            StoreRedirect.redirect(androidAppId: 'com.kingwire.kingvpn');
          }),
          const Divider(height: 2, color: Color.fromARGB(255, 218, 218, 218)),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
      _ResponsiveHelper r,
      IconData icon,
      String title,
      VoidCallback onTap,
      ) {
    return ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.symmetric(
        horizontal: r.spacing(20),
        vertical: r.spacing(4),
      ),
      leading: Icon(
        icon,
        size: r.iconSize(25),
        color: const Color.fromARGB(255, 218, 218, 218),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: const Color.fromARGB(255, 218, 218, 218),
          fontSize: r.fontSize(16),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  // ============= ANIMATED BACKGROUNDS =============
  Widget _buildAnimatedBackgrounds(_ResponsiveHelper r) {
    return SizedBox(
      height: r.screenHeight,
      width: r.screenWidth,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          SizedBox(height: r.height(169)),
          SizedBox(
            height: r.getValue(
              mobile: r.height(253),
              tablet: r.height(211),
            ),
            width: r.screenWidth,
            child: const FittedBox(
              fit: BoxFit.cover,
              child: GifImageWidget(gifPath: 'assets/vedios/top_gif.gif'),
            ),
          ),
          SizedBox(height: r.height(110)),
          SizedBox(
            height: r.getValue(
              mobile: r.height(295),
              tablet: r.height(253),
            ),
            width: r.screenWidth,
            child: const FittedBox(
              fit: BoxFit.cover,
              child: GifImageWidget(gifPath: 'assets/vedios/bottom_gif.gif'),
            ),
          ),
        ],
      ),
    );
  }

  // ============= MAIN UI =============
  Widget _buildMainUI(_ResponsiveHelper r, Function showProgressDialog) {
    return SizedBox(
      height: r.screenHeight,
      width: r.screenWidth,
      child: Column(
        children: [
          _buildAppBar(r),
          _buildMapAndBanner(r),
          SizedBox(height: r.spacing(32)),
          _buildStatsAndButton(r, showProgressDialog),
          SizedBox(height: r.spacing(125)),
          _buildServerSelector(r),
        ],
      ),
    );
  }

  // ============= APP BAR =============
  Widget _buildAppBar(_ResponsiveHelper r) {
    return Container(
      height: r.height(84) + r.topPadding,
      width: r.screenWidth,
      padding: EdgeInsets.only(
        top: r.topPadding,
        left: r.spacing(8),
        right: r.spacing(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: _openDrawer,
            icon: Icon(
              Icons.menu,
              color: Colors.white,
              size: r.iconSize(28),
            ),
            padding: EdgeInsets.all(r.spacing(8)),
          ),
          Flexible(
            child: Container(
              height: r.height(60),
              constraints: BoxConstraints(
                maxWidth: r.width(120),
              ),
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage("assets/images/vpn_log.png"),
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          SizedBox(width: r.iconSize(28) + r.spacing(16)),
        ],
      ),
    );
  }

  // ============= MAP AND BANNER =============
  Widget _buildMapAndBanner(_ResponsiveHelper r) {
    return Stack(
      alignment: Alignment.topCenter,
      children: [
        Column(
          children: [
            SizedBox(height: r.spacing(20)),
            Container(
              height: r.getValue(
                mobile: r.screenHeight * 0.3,
                tablet: r.screenHeight * 0.25,
                largeTablet: r.screenHeight * 0.22,
              ),
              width: r.screenWidth,
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(600),
                  topRight: Radius.circular(600),
                ),
                image: DecorationImage(
                  image: AssetImage("assets/images/Vpn-MAx-Map.png"),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ],
        ),
        Consumer<AdsProvider>(
          builder: (context, value, child) {
            final bannerAd = value.getBannerAd();
            bool isSubscribed = Prefs.getBool('isSubscribed') ?? false;
            if (bannerAd != null && !isSubscribed) {
              return Container(
                margin: EdgeInsets.only(top: r.spacing(4)),
                alignment: Alignment.center,
                width: bannerAd.size.width.toDouble(),
                height: r.height(80),
                child: AdWidget(ad: bannerAd),
              );
            } else {
              return SizedBox(height: r.height(80));
            }
          },
        ),
      ],
    );
  }

  // ============= STATS AND BUTTON =============
  Widget _buildStatsAndButton(_ResponsiveHelper r, Function showProgressDialog) {
    return Consumer<VpnConnectionProvider>(
      builder: (context, value, child) => Padding(
        padding: EdgeInsets.symmetric(horizontal: r.spacing(16)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Flexible(
              flex: 1,
              child: _buildStatColumn(
                r,
                "Download",
                value.stage?.toString() == "VPNStage.connected"
                    ? bytesPerSecondToMbps(
                    double.parse(value.status!.byteIn ?? "0000"))
                    .toStringAsFixed(2)
                    : "00:00",
                "Mbps",
              ),
            ),
            SizedBox(width: r.spacing(1)),
            Flexible(
              flex: 2,
              child: _buildConnectionButton(r, value, showProgressDialog),
            ),
            SizedBox(width: r.spacing(12)),
            Flexible(
              flex: 1,
              child: _buildStatColumn(
                r,
                "Upload",
                value.stage?.toString() == "VPNStage.connected"
                    ? bytesPerSecondToMbps(
                    double.parse(value.status!.byteOut ?? "0000"))
                    .toStringAsFixed(2)
                    : "00:00",
                "Mbps",
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(
      _ResponsiveHelper r,
      String title,
      String value,
      String unit,
      ) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: r.getValue(
          mobile: r.width(80),
          tablet: r.width(90),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              title,
              style: TextStyle(
                color: Colors.blue,
                fontSize: r.fontSize(14),
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: r.spacing(8)),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                color: Colors.white,
                fontSize: r.fontSize(16),
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: r.spacing(4)),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              unit,
              style: TextStyle(
                color: Colors.blue,
                fontSize: r.fontSize(12),
                fontWeight: FontWeight.w400,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  // ============= CONNECTION BUTTON =============
  // Replace the _buildConnectionButton method with this fixed version

  Widget _buildConnectionButton(
      _ResponsiveHelper r,
      VpnConnectionProvider value,
      Function showProgressDialog,
      ) {
    // Determine status based on VPN stage and isConnected
    String status;
    Color statusColor;

    if (value.stage == VPNStage.connected || value.isConnected) {
      status = "CONNECTED";
      statusColor = Colors.blue;
    } else if (value.stage == VPNStage.connecting ||
        value.stage == VPNStage.prepare ||
        value.stage == VPNStage.authenticating ||
        value.stage == VPNStage.authentication ||
        value.stage == VPNStage.resolve ||
        value.stage == VPNStage.wait_connection) {
      status = "CONNECTING";
      statusColor = Colors.orange;
    } else if (value.stage == VPNStage.disconnected) {
      status = "DISCONNECT";
      statusColor = Colors.white;
    } else {
      status = "READY";
      statusColor = Colors.white;
    }

    double buttonSize = r.buttonSize(140);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: buttonSize,
          width: buttonSize,
          child: RippleAnimation(
            repeat: true,
            color: Colors.blue,
            minRadius: value.stage == VPNStage.disconnected ? 0 : buttonSize * 0.6,
            ripplesCount: 3,
            duration: const Duration(milliseconds: 2000),
            delay: const Duration(milliseconds: 0),
            child: InkWell(
              splashColor: Colors.grey,
              onTap: () => _handleConnectionTap(value, showProgressDialog),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: buttonSize,
                width: buttonSize,
                decoration: BoxDecoration(
                  color: Colors.black,
                  border: Border.all(color: Colors.white, width: 2),
                  borderRadius: BorderRadius.circular(buttonSize / 2),
                  boxShadow: (value.stage == VPNStage.connected || value.isConnected)
                      ? [
                    BoxShadow(
                      color: Colors.grey[500]!,
                      offset: const Offset(4, 4),
                      blurRadius: 15,
                      spreadRadius: 1,
                    ),
                    const BoxShadow(
                      color: Colors.white,
                      offset: Offset(-4, -4),
                      blurRadius: 15,
                      spreadRadius: 1,
                    )
                  ]
                      : null,
                ),
                child: Icon(
                  Icons.power_settings_new_outlined,
                  color: (value.stage == VPNStage.connected || value.isConnected)
                      ? Colors.blue
                      : Colors.grey,
                  size: r.iconSize(70),
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: r.spacing(16)),
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: EdgeInsets.symmetric(
            horizontal: r.spacing(16),
            vertical: r.spacing(8),
          ),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(r.radius(20)),
            border: Border.all(
              color: statusColor.withOpacity(0.5),
              width: 2,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: r.spacing(8),
                width: r.spacing(8),
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: statusColor.withOpacity(0.5),
                      blurRadius: 8,
                      spreadRadius: 2,
                    )
                  ],
                ),
              ),
              SizedBox(width: r.spacing(6)),
              Text(
                status,
                style: TextStyle(
                  color: statusColor,
                  fontSize: r.fontSize(10),
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }


  // ============= CONNECTION HANDLER =============
  // ============= CONNECTION HANDLER =============
  Future<void> _handleConnectionTap(
      VpnConnectionProvider value,
      Function showProgressDialog,
      ) async {
    final vpnProvider = Provider.of<VpnProvider>(context, listen: false);
    final apps = Provider.of<AppsProvider>(context, listen: false);
    final adsProvider = Provider.of<AdsProvider>(context, listen: false);

    // If already connected, disconnect
    if (value.stage == VPNStage.connected || value.isConnected) {
      value.engine.disconnect();
      Fluttertoast.showToast(
        msg: "Disconnected Successfully",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.TOP,
        backgroundColor: Colors.orange,
        textColor: Colors.white,
        fontSize: 16.0,
      );
      return;
    }

    // Show ads before connection
    adsProvider.loadInterstitialAd().then((_) => adsProvider.showInterstitialAd());

    if (value.getInitCheck()) value.initialize();

    if (vpnProvider.vpnConfig != null) {
      // Show progress dialog
      showProgressDialog(context);
      value.triedToConnect = true;
      // Start VPN
      await value.initPlatformState(
        vpnProvider.vpnConfig!.ovpn,
        vpnProvider.vpnConfig!.country,
        apps.getDisallowedList,
        vpnProvider.vpnConfig!.username ?? "",
        vpnProvider.vpnConfig!.password ?? "",
      );

      // Close progress dialog
      Navigator.pop(context);

      // Listen for VPN connection **once**
      _listenVpnConnectionOnce(value);
    } else {
      // No VPN config, navigate to server selection
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ServerTabs()),
      );
    }
  }

// ============= LISTENER THAT RUNS ONLY ONCE ============
  void _listenVpnConnectionOnce(VpnConnectionProvider value) {
    // Remove previous listener if any
    value.removeListener(_vpnListener);

    // Add listener
    value.addListener(_vpnListener);
  }

// Actual listener function
  void _vpnListener() {
    final value = Provider.of<VpnConnectionProvider>(context, listen: false);

    // === SUCCESSFUL CONNECTION ===
    if (value.stage == VPNStage.connected && !value.hasShownToast) {
      Fluttertoast.showToast(
        msg: "Connected Successfully",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.TOP,
        backgroundColor: Colors.blue,
        textColor: Colors.white,
        fontSize: 16.0,
      );

      Future.delayed(const Duration(seconds: 1), () {
        Fluttertoast.showToast(
          msg: "Now you are protected",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.TOP,
          backgroundColor: Colors.blue,
          textColor: Colors.white,
          fontSize: 16.0,
        );
      });

      value.hasShownToast = true;
      value.removeListener(_vpnListener);
      return;
    }

    // === FAILED CONNECTION (DISCONNECTED AFTER USER TAP) ===
    if (value.stage == VPNStage.disconnected && value.triedToConnect == true) {
      Fluttertoast.showToast(
        msg: "VPN connection failed. Please try again.",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.TOP,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
      );

      value.triedToConnect = false; // reset flag
      value.removeListener(_vpnListener);
    }
  }




  // ============= SERVER SELECTOR =============
  Widget _buildServerSelector(_ResponsiveHelper r) {
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ServerTabs()),
      ),
      child: Container(
        height: r.getValue(
          mobile: r.height(56),
          tablet: r.height(64),
        ),
        width: r.getValue(
          mobile: r.width(312),
          tablet: r.width(400),
        ),
        margin: EdgeInsets.symmetric(horizontal: r.spacing(20)),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(r.radius(15)),
          border: Border.all(color: Colors.white, width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Consumer<VpnProvider>(
              builder: (context, value, child) => value.vpnConfig == null
                  ? Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: r.spacing(20),
                ),
                child: Icon(
                  Icons.flag,
                  size: r.iconSize(30),
                  color: Colors.white,
                ),
              )
                  : Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: r.spacing(20),
                ),
                child: Container(
                  height: r.iconSize(30),
                  width: r.iconSize(45),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(r.radius(8)),
                    image: DecorationImage(
                      fit: BoxFit.cover,
                      image: AssetImage(
                        'icons/flags/png250px/${value.vpnConfig!.countryCode.toLowerCase()}.png',
                        package: 'country_icons',
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Consumer<VpnProvider>(
                builder: (context, value, child) => Text(
                  value.vpnConfig == null
                      ? "Select your country"
                      : value.vpnConfig!.country,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: r.fontSize(16),
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: r.spacing(16)),
              child: Icon(
                Icons.arrow_forward_ios,
                color: Colors.white,
                size: r.iconSize(18),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============= PERSISTENT SNACKBAR =============
  void showPersistentSnackbar(String message, BuildContext context) {
    final r = _ResponsiveHelper(context);
    Scaffold.of(context).showBottomSheet((BuildContext context) {
      return SafeArea(
        child: Container(
          padding: EdgeInsets.all(r.spacing(15)),
          decoration: BoxDecoration(
            color: Colors.blue,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(r.radius(16)),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: r.fontSize(14),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.close,
                  color: Colors.white,
                  size: r.iconSize(24),
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      );
    });
  }
}