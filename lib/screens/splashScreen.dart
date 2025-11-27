import 'dart:async';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vpnprowithjava/screens/home%20screen.dart';

class SplashScreen extends StatefulWidget {
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with WidgetsBindingObserver {
  bool isFirstLaunch = true;
  bool appKilled = false; 

  @override
  void initState() {
    super.initState();

    Timer(Duration(seconds: 2), () {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => FirstScreen()));
    });
    checkFirstLaunch();
    WidgetsBinding.instance.addObserver(this); 
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this); 
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      appKilled = false;
    }
    super.didChangeAppLifecycleState(state);
  }

  Future<void> checkFirstLaunch() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool launchedBefore = prefs.getBool('launched_before') ?? false;
    if (!launchedBefore || appKilled) {
      Fluttertoast.showToast(
        msg: 'You are unprotected',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      prefs.setBool('launched_before', true); 
      appKilled = false; 
    }
    setState(() {
      isFirstLaunch = launchedBefore;
    });
  }

 

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Container(
          child: Image.asset("assets/images/profile.png"),
        ),
      ),
    );
  }
}
