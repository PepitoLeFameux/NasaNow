import 'dart:async';
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class IssApi {

  //Pour faire un singleton
  static final IssApi _instance = IssApi._privateConstructor();
  IssApi._privateConstructor(){Timer.periodic(Duration(seconds: 1, milliseconds: 500), (Timer t) => getIssPosition());}
  static IssApi get instance => _instance;

  static double lat = 0, lon = 0, time = 0, speed = 0;
  List<LatLng> positionsList = [];
  List<bool> dayLightList = [];
  static double histTime = (DateTime.now().millisecondsSinceEpoch ~/ 1000).toDouble();
  static int step = 50;

  LatLng getLatLng() {
    return LatLng(lat, lon);
  }

  double getSpeed() {
    return speed;
  }

  double getTime() {
    return time;
  }

  List<LatLng> getIssPath() {
    return positionsList;
  }

  List<bool> getDaylightPath() {
    return dayLightList;
  }

  void getIssPosition() async {
    String uri = 'https://api.wheretheiss.at/v1/satellites/25544/positions?timestamps=';
    uri += '${DateTime.now().millisecondsSinceEpoch ~/ 1000},';
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
      lat = today['latitude'];
      lon = today['longitude'];
      time = today['timestamp'].toDouble();
      speed = data[0]['velocity'] / 3.6;
      positionsList.add(LatLng(lat, lon));

      if (positionsList.length < 10800 / step) {
        for (var position in data.sublist(1, data.length)) {
          positionsList.insert(
              0, LatLng(position['latitude'], position['longitude']));
          dayLightList.add(
              position['visibility'] == 'dayLight' ? true : false);
        }
      }
    }
    else {
      throw Exception('Failed to load ISS position');
    }
  }
}
