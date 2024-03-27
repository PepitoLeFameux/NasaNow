import 'dart:async';
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class IssApi {

  //Pour faire un singleton
  static final IssApi _instance = IssApi._privateConstructor();
  IssApi._privateConstructor();
  static IssApi get instance => _instance;

  static double? exLat, exLon, exTime;
  List<LatLng> positionsList = [];
  List<bool> dayLightList = [];
  static double histTime = (DateTime.now().millisecondsSinceEpoch ~/ 1000).toDouble();
  static int step = 50;



  List<LatLng> getIssPath() {
    return positionsList;
  }

  List<bool> getDaylightPath() {
    return dayLightList;
  }

  Future<Map<String, double>> getIssPosition() async {
    String uri = 'https://api.wheretheiss.at/v1/satellites/25544/positions?timestamps=';
    uri += '${DateTime
        .now()
        .millisecondsSinceEpoch ~/ 1000},';
    for (var i = 1; i < 10; i++) {
      uri += (histTime - step * i).toInt().toString();
      uri += ',';
    }
    uri = uri.substring(0, uri.length - 1);
    histTime -= step * 9;

    final response = await http.get(Uri.parse(uri));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      dynamic today = data[0];
      final lat = today['latitude'];
      final lon = today['longitude'];
      final time = today['timestamp'];
      final speed = data[0]['velocity'] / 3.6;
      positionsList.add(LatLng(lat, lon));

      if (positionsList.length < 10800 / step) {
        for (var position in data.sublist(1, data.length)) {
          positionsList.insert(
              0, LatLng(position['latitude'], position['longitude']));
          dayLightList.add(
              position['visibility'] == 'dayLight' ? true : false);
        }
      }
      return {'latitude': lat, 'longitude': lon, 'speed': speed};
    }
    else {
      throw Exception('Failed to load ISS position');
    }
  }
}
