import 'dart:async';
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

class IssApi {

  //Pour faire un singleton
  static final IssApi _instance = IssApi._privateConstructor();
  IssApi._privateConstructor();
  static IssApi get instance => _instance;
  static double? exLat, exLon, exTime;

  Future<Map<String, double>> getIssPosition() async {
    final response = await http.get(Uri.parse('http://api.open-notify.org/iss-now.json'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final double lat = double.parse(data['iss_position']['latitude']);
      final double lon = double.parse(data['iss_position']['longitude']);
      final double time = data['timestamp'].toDouble();
      final double speed = (exLon != null) ? Geolocator.distanceBetween(exLat!, exLon!, lat, lon)/(time - exTime!): 0;
      exLon = lon;
      exLat = lat;
      exTime = time;
      return {'latitude': lat, 'longitude': lon, 'speed': speed};
    } else {
      throw Exception('Failed to load ISS position');
    }
  }
}
