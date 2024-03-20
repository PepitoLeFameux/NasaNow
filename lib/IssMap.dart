import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class IssMap extends StatelessWidget {
  final LatLng issPosition;

  IssMap({required this.issPosition});

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      options: MapOptions(
        center: issPosition,
        zoom: 2.0,
      ),
      layers: [
        TileLayerOptions(
          urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
          subdomains: ['a', 'b', 'c'],
        ),
        MarkerLayerOptions(
          markers: [
            Marker(
              width: 80.0,
              height: 80.0,
              point: issPosition,
              builder: (ctx) => Container(
                child: Icon(
                  Icons.location_on,
                  color: Colors.red,
                  size: 50.0,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}