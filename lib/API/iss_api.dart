import 'dart:async';
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'dart:io';

class IssApi {

  //Pour faire un singleton
  static final IssApi _instance = IssApi._privateConstructor();
  IssApi._privateConstructor(){Timer.periodic(Duration(seconds: 1, milliseconds: 500), (Timer t) => getIssPosition());}
  static IssApi get instance => _instance;

  static double lat = 0, lon = 0, time = 0, speed = 0;
  List<LatLng> positionsList = [];
  List<int> timeList = [];
  List<bool> dayLightList = [];
  static double histTime = (DateTime.now().millisecondsSinceEpoch ~/ 1000).toDouble();
  static int step = 9;
  //static double maxData = 10800 / step;
  static double maxData = double.infinity;

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

  Future<void> saveToCsv() async {
    List<Map<String, dynamic>> data = [];
    for(int i=0; i<timeList.length; i++){
      data.add({'time': timeList[i], 'lat': positionsList[i].latitude, 'lon': positionsList[i].longitude});
    }
    String csvContent = listMapToCsv(data);
    String filePath = 'C:/Users/123ro/Desktop/csv/data.csv';
    File file = File(filePath);

    try {
      // Write the CSV string to the file, creating the file if it doesn't exist
      await file.writeAsString(csvContent);
      debugPrint('Data successfully saved as CSV at $filePath');
    } catch (e) {
      // If an error occurs, print it or handle it as needed
      debugPrint('Failed to save data as CSV: $e');
    }
  }

  String listMapToCsv(List<Map<String, dynamic>> list) {
    if (list.isEmpty) return '';
    List<String> headers = list.first.keys.toList();
    List<List<dynamic>> csvRows = [headers];

    for (var map in list) {
      csvRows.add(headers.map((h) => map[h]?.toString() ?? '').toList());
    }

    return csvRows.map((row) => row.join(',')).join('\n');
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
      speed = today['velocity'] / 3.6;
      timeList.add(time.toInt());
      positionsList.add(LatLng(lat, lon));
      dayLightList.add(today['visibility'] == 'dayLight' ? true : false);

      if (positionsList.length < maxData) {
        for (var position in data.sublist(1, data.length)) {
          positionsList.insert(0, LatLng(position['latitude'], position['longitude']));
          timeList.insert(0, position['timestamp'].toInt());
          dayLightList.insert(0,position['visibility'] == 'dayLight' ? true : false);
        }
      }
    //saveToCsv();
    }
    else {
      throw Exception('Failed to load ISS position');
    }
  }
}
