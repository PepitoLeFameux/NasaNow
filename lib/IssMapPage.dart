import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;

Future<String> loadMapStyle() async {
  return await rootBundle.loadString('images/style.json');
}

class IssMapPage extends StatefulWidget {
  const IssMapPage({Key? key}) : super(key: key);

  @override
  _IssMapPageState createState() => _IssMapPageState();
}

class _IssMapPageState extends State<IssMapPage> {
  List<Marker> markerList = [];
  MapController mapController = MapController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.secondary,
        title: const Text("ISS Tracker"),
      ),
      body: FutureBuilder(
        future: loadMapStyle(),
        builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
          if (snapshot.hasData) {
            return FlutterMap(
              mapController: mapController,
              options: MapOptions(
                initialCenter: const LatLng(0, 0),
                initialZoom: 4,
                onMapReady: () => getISSPosition(),
              ),
              children: [
                TileLayer(
                  urlTemplate: snapshot.data!,
                ),
                MarkerLayer(
                  markers: markerList,
                )
              ],
            );
          } else {
            return Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }

  void getISSPosition() {
    Timer.periodic(const Duration(seconds: 1), (timer) async {
      final response =
      await http.get(Uri.parse('http://api.open-notify.org/iss-now.json'));
      if (response.statusCode == 200) {
        final parsedJson = jsonDecode(response.body);
        double latitude =
        double.parse(parsedJson["iss_position"]["latitude"]);
        double longitude =
        double.parse(parsedJson["iss_position"]["longitude"]);
        setState(() {
          markerList.clear();
          markerList.add(
            Marker(
              point: LatLng(latitude, longitude),
              child: Image.asset(
                "images/iss.png",
                height: 50,
                width: 50,
              ),
            ),
          );
          mapController.move(LatLng(latitude, longitude), 4);
        });
      }
    });
  }
}
