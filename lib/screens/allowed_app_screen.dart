import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/appsProvider.dart';

class AllowedAppsScreen extends StatefulWidget {
  const AllowedAppsScreen({super.key});

  @override
  State<AllowedAppsScreen> createState() => _AllowedAppsScreenState();
}

class _AllowedAppsScreenState extends State<AllowedAppsScreen> {
  MethodChannel platform = const MethodChannel("disallowList");

  void _disallowApp(String packageName) async {
    await platform.invokeMethod("applyChanges", {"packageName": packageName});
  }
  @override
  Widget build(BuildContext context) {
    final apps = Provider.of<AppsProvider>(context).getAllApps;
    final isLoading = Provider.of<AppsProvider>(context).isLoading;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
                bottomRight: Radius.circular(7),
                bottomLeft: Radius.circular(7))),
        backgroundColor: Colors.grey.shade900,
        leading: IconButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            icon: const Icon(Icons.arrow_back_ios,color: Colors.white,)),
        title: Text(
          'Allowed apps',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600,color: Colors.white),
        ),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : apps.isEmpty
              ? const Center(
                  child: Text("No App Found!"),
                )
              : Padding(
                padding: const EdgeInsets.only(top: 5),
                child: ListView.builder(
                    primary: true,
                    itemCount: apps.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: EdgeInsets.symmetric(vertical: 3),
                        child: ListTile(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(7)),
                          tileColor: Colors.grey.shade900,
                          leading: CircleAvatar(
                            backgroundImage: MemoryImage(apps[index].app.icon!),
                      
                            backgroundColor: Colors.white,
                          ),
                          title: Text(
                            apps[index].app.name!,
                            style: GoogleFonts.poppins(color: Colors.white),
                          ),
                          trailing: Switch(
                              activeColor: Colors.blue,
                              value: apps[index].isSelected,
                              onChanged: (bool val) {
                                setState(() {
                                  apps[index].isSelected = val;
                                  context.read<AppsProvider>().updateAppsList(
                                      apps[index].app.packageName!,
                                    
                                      apps[index].isSelected);
                                });
                          
                                _disallowApp(apps[index].app.packageName!);
                              }),
                        ),
                      );
                    },
                  ),
              ),
    );
  }
}
