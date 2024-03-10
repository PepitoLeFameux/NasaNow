// ignore_for_file: prefer_const_literals_to_create_immutables

import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nasa_now/Api.dart';
import 'package:nasa_now/ApodPage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MyAppState(),
      child: MaterialApp(
        title: 'Nasa Now',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Color.fromARGB(222, 20, 19, 79)),
          fontFamily: 'Megatrans'
        ),
        home: MyHomePage(),
      ),
    );
  }
}

class MyAppState extends ChangeNotifier {

}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  var selectedIndex = 0;

  Future<Map<String, String>>? apod;
  Future<List<Map<String, String>>>? apodDays;
  var imageList = [];

  @override
  void initState() {
    super.initState();
    // Fetch data when the state is initialized.
    apod = Api().getAPOD();
    apodDays = Api().getAPODDays(20);
  }

  @override
  Widget build(BuildContext context) {
    Widget page;
    switch(selectedIndex){
      case 0:
        page = APODPage();
      case 1:
        page = Placeholder();
      default:
        throw UnimplementedError('no widget for $selectedIndex');
    }
    return LayoutBuilder(
        builder: (context, constraints) {
          return Scaffold(
            body: Container(
              width: constraints.maxWidth,
              height: constraints.maxHeight,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topLeft,
                  radius: 1.1,
                  colors: [Color.fromARGB(255, 14, 13, 30), Color.fromARGB(255, 28, 26, 86)],
                )
              ),
              child: Row(
                mainAxisSize: MainAxisSize.max,
                children: [
                  NavigationSideBar(),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(top: 8, left:8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.only(topLeft: Radius.circular(20)),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color.fromARGB(255, 13, 11, 71), Color.fromARGB(255, 27, 23, 133)],
                              begin: Alignment.centerRight,
                              end: Alignment.centerLeft,
                              stops: [0, 1]
                            )
                          ),
                          child: page,
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),
          );
        }
    );
  }
}

class NavigationSideBar extends StatefulWidget {
  const NavigationSideBar({super.key});

  @override
  State<NavigationSideBar> createState() => _NavigationSideBarState();
}

class _NavigationSideBarState extends State<NavigationSideBar>{
  int selectedIndex = 0;
  String debugText = "cc";

  Widget _buildNavItem({required IconData icon, required IconData selectedIcon, required String label, required int index}){
    final bool isSelected = index == selectedIndex;
    return InkWell(
      onTap:  (){
        setState(() {
          selectedIndex = index;
          debugText = "Selected index: $index";
        });
      },
      child: Card(
        color:Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              SizedBox(width: 10,),
              Icon(isSelected ? selectedIcon : icon, color: isSelected ? Colors.white : Color.fromARGB(255, 101, 96, 209)),
              SizedBox(width: 20,),
              Text(label, style: TextStyle(color: isSelected ? Colors.white : Color.fromARGB(255, 101, 96, 209)))]
          ),
        ),
      )

    );
  }

  @override
  Widget build(BuildContext context){
    return Container(
      width: 200,
      child: Padding(
        padding: EdgeInsets.all(8),
        child: Column(
          children: [
            Padding(padding: EdgeInsets.all(20), child: Image.asset("images/nasanow2.png")),
            Divider(color: Colors.white),
            _buildNavItem(icon: Icons.linked_camera_outlined, selectedIcon: Icons.linked_camera, label: 'APOD', index: 0),
            _buildNavItem(icon: Icons.satellite_alt_outlined, selectedIcon: Icons.satellite_alt, label: 'ISS', index: 1),
          ],
        ),
      )
    );
  }
}