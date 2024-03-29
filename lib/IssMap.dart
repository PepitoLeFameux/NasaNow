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
            IssPath()
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
  LatLng position = LatLng(0, 0);

  void updatePosition(){
    setState(() {
      position = IssApi.instance.getLatLng();
    });
  }

  @override
  void initState(){
    super.initState();
    Timer.periodic(Duration(milliseconds: 100), (Timer t) => updatePosition());
  }

  @override
  Widget build(BuildContext buildContext){
    return MarkerLayer(
      markers: [
        Marker(
          width: 80.0,
          height: 80.0,
          point: position,
          builder: (ctx) => Container(
              child: Hero(tag: 'issmarker', child: Image.asset('images/iss.png'))
          ),
        ),
      ],
    );
  }
}


class SpeedCard extends StatefulWidget{
  @override
  State<SpeedCard> createState() => _SpeedCardState();
}

class _SpeedCardState extends State<SpeedCard> {
  LatLng latlng = LatLng(0, 0);
  double speed = 0;

  void updateValues() {
    setState(() {
      latlng = IssApi.instance.getLatLng();
      speed = IssApi.instance.getSpeed();
    });
  }

  @override
  void initState(){
    super.initState();
    Timer.periodic(Duration(milliseconds: 100), (Timer t) => updateValues());
  }

  @override
  Widget build(BuildContext buildContext){
    return Column(
      children: [
        Container(
          width: 160,
          height: 40,
          child: Card(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text("Speed : ${speed.toStringAsFixed(0)} m/s"),
              )
          ),
        ),
        Container(
          width: 160,
          height: 40,
          child: Card(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text("Latitude: ${latlng.latitude.toStringAsFixed(2)}"),
              )
          ),
        ),
        Container(
          width: 160,
          height: 40,
          child: Card(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text("Longitude: ${latlng.longitude.toStringAsFixed(2)}"),
              )
          ),
        ),

      ],
    );
  }
}


class IssPath extends StatefulWidget {
  @override
  State<IssPath> createState() => _IssPathState();
}

class _IssPathState extends State<IssPath> {
  List<LatLng> path = [];

  void updatePath(){
    setState(() {
      path = IssApi.instance.getIssPath();
    });
  }

  @override
  void initState(){
    super.initState();
    Timer.periodic(Duration(milliseconds: 100), (Timer t) => updatePath());
  }

  List<Polyline> cutPath(){
    List<Polyline> list = [];
    List<LatLng> segment = [];

    if (path.isNotEmpty) {
      LatLng oldLoc = path[0];
      late LatLng location;
      for(location in path.sublist(1, path.length)){
        segment.add(oldLoc);
        if((oldLoc.longitude - location.longitude).abs() > 180){
          list.add(
            Polyline(
              points: List.from(segment),
              color: Colors.lightBlue,
              strokeWidth: 4
            )
          );
          segment.clear();
        }
        oldLoc = location;
      }
      segment.add(location);
      list.add(
        Polyline(
          points: List.from(segment),
          color: Colors.lightBlue,
          strokeWidth: 4
        )
      );
      return list;
    }
    return [];
  }

  @override
  Widget build(BuildContext buildContext){
    return PolylineLayer(
      polylines: cutPath(),
    );
  }
}