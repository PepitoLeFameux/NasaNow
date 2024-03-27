import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'API/iss_api.dart';

class IssMap extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        FlutterMap(
          options: MapOptions(
            zoom: 2.0,
          ),
          children: [
            TileLayer(

                urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                subdomains: ['a', 'b', 'c'],

            ),
            IssMarker(),
          ],
        ),
        Align(
          alignment: Alignment.topRight,
          child: SpeedCard(),
        )
      ]
    );
  }
}

class IssMarker extends StatefulWidget {
  @override
  State<IssMarker> createState() => _IssMarkerState();
}

class _IssMarkerState extends State<IssMarker> {
  late Future<Map<String, double>> position = IssApi.instance.getIssPosition();
  LatLng? exPosition;

  void updatePosition(){
    setState(() {
      position = IssApi.instance.getIssPosition();
    });
  }

  @override
  void initState(){
    super.initState();
    Timer.periodic(Duration(seconds: 1), (Timer t) => updatePosition());
  }

  @override
  Widget build(BuildContext buildContext){
    return FutureBuilder<Map<String, double>>(
      future: position,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return exPosition == null ? Center(child: CircularProgressIndicator()) :
          MarkerLayer(
            markers: [
              Marker(
                width: 80.0,
                height: 80.0,
                point: exPosition!,
                builder: (ctx) => Container(
                    child: Image.asset('images/iss.png')
                ),
              ),
            ],
          );
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else {
          LatLng latlng = LatLng(snapshot.data!['latitude']!, snapshot.data!['longitude']!);
          exPosition = latlng;
          return MarkerLayer(
            markers: [
              Marker(
                width: 80.0,
                height: 80.0,
                point: latlng,
                builder: (ctx) => Container(
                    child: Image.asset('images/iss.png')
                ),
              ),
            ],
          );
        }
      }
    );
  }
}

class SpeedCard extends StatefulWidget{
  @override
  State<SpeedCard> createState() => _SpeedCardState();
}

class _SpeedCardState extends State<SpeedCard> {
  late Future<Map<String, double>> position = IssApi.instance.getIssPosition();
  double exSpeed = 0;

  void updateSpeed() {
    setState(() {
      position = IssApi.instance.getIssPosition();
    });
  }

  @override
  void initState(){
    super.initState();
    Timer.periodic(Duration(seconds: 1), (Timer t) => updateSpeed());
  }

  @override
  Widget build(BuildContext buildContext){
    return FutureBuilder<Map<String, double>>(
        future: position,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return exSpeed == 0 ? Center(child: CircularProgressIndicator()) :
            Card(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text("Speed : ${exSpeed.toStringAsFixed(0)} m/s"),
                )
            );
          } else if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          } else {
            double speed = snapshot.data!['speed']!;
            exSpeed = speed;
            return Card(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text("Speed : ${speed.toStringAsFixed(0)} m/s"),
                )
            );
          }
        }
    );
  }
}
