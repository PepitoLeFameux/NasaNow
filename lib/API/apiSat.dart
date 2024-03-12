import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';

class Satellite {
  final String name;
  final String id;
  final double latitude;
  final double longitude;

  Satellite({
    required this.name,
    required this.id,
    required this.latitude,
    required this.longitude,
  });

  factory Satellite.fromJson(Map<String, dynamic> json) {
    return Satellite(
      name: json['name'] ?? "",
      id: json['id'] ?? "",
      latitude: json['latitude'] != null ? double.parse(json['latitude']) : 0.0,
      longitude: json['longitude'] != null ? double.parse(json['longitude']) : 0.0,
    );
  }
}

class SatelliteApi {
  final String apiKey;

  SatelliteApi({required this.apiKey});

  Future<List<Satellite>> getAllSatellites() async {
    try {
      final response = await Dio().get(
        'https://sscweb.gsfc.nasa.gov/WS/sscr/2/catalog.json',
        queryParameters: {'format': 'json', 'category': 'all'},
        options: Options(headers: {'Authorization': 'Bearer $apiKey'}),
      );

      List<Satellite> satellites = [];
      List<dynamic> data = response.data['satcat'];

      for (var item in data) {
        final Satellite satellite = Satellite.fromJson(item);
        satellites.add(satellite);
      }

      return satellites;
    } catch (e) {
      print('Error fetching satellite data: $e');
      return [];
    }
  }
}

void main() async {
  final apiKey = 'dZISEuetcZ7WiCrmQIsuKzJoaK3Zd8i1eSIhVJ3l';
  final satelliteApi = SatelliteApi(apiKey: apiKey);

  try {
    final satellites = await satelliteApi.getAllSatellites();

    for (var satellite in satellites) {
      print('Satellite Name: ${satellite.name}');
      print('Satellite ID: ${satellite.id}');
      print('Latitude: ${satellite.latitude}');
      print('Longitude: ${satellite.longitude}');
      print('-------------------');
    }
  } catch (e) {
    print('Error: $e');
  }
}