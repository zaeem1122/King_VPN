import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../component/servers_screen.dart';
import '../../providers/servers_provider.dart';

class ServerTabs extends StatefulWidget {
  const ServerTabs({super.key});

  @override
  State<ServerTabs> createState() => _ServerTabsState();
}

class _ServerTabsState extends State<ServerTabs> {
  @override
  Widget build(BuildContext context) {
    return Consumer<ServersProvider>(
        builder: (context, value, child) => DefaultTabController(
              length: 2,
              child: Scaffold(
                appBar: AppBar(
                  backgroundColor: const Color(0XFF03406D),
                  leading: IconButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      icon: const Icon(
                        Icons.arrow_back_ios_new,
                        color: Color.fromARGB(255, 218, 218, 218),
                      )),
                  title: const Text(
                    'Select Country',
                    style: TextStyle(
                      color: Color.fromARGB(255, 218, 218, 218),
                    ),
                  ),
                  bottom: const TabBar(
                    labelColor: Colors.white,
                    tabs: [
                      Tab(
                        text: 'Free',
                      ),
                      Tab(
                        text: 'Pro',
                      ),
                    ],
                  ),
                ),
                body: TabBarView(
                  children: [
                    value.isLoading
                        ? Container(
                            color: Colors.black,
                            child: Center(
                                child: CircularProgressIndicator(
                              color: Colors.white,
                            )),
                          )
                        : ServersScreen(
                            servers: value.freeServers,
                            tab: "All Locations",
                          ),
                    ServersScreen(
                      servers: value.proServers,
                      tab: "Recommended",
                    ),
                  ],
                ),
              ),
            ));
  }
}
