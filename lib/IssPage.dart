import 'dart:async';
import 'package:latlong2/latlong.dart';
import 'package:flutter/material.dart';
import 'package:nasa_now/API/iss_api.dart';
import 'package:nasa_now/IssMap.dart';

class IssPage extends StatefulWidget {
  @override
  _IssPageState createState() => _IssPageState();
}

class _IssPageState extends State<IssPage> {
  late IssApi _api;
  late Future<Map<String, double>> _issPosition;

  @override
  void initState() {
    super.initState();
    _api = IssApi();
    _issPosition = _api.getIssPosition();
    // Actualiser la position de l'ISS toutes les 5 secondes
    Timer.periodic(Duration(seconds: 5), (Timer t) => _refreshIssPosition());
  }

  void _refreshIssPosition() {
    setState(() {
      _issPosition = _api.getIssPosition();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ISS Location'),
      ),
      body: FutureBuilder<Map<String, double>>(
        future: _issPosition,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            final issPosition = LatLng(snapshot.data!['latitude']!, snapshot.data!['longitude']!);
            return IssMap(issPosition: issPosition);
          }
        },
      ),
    );
  }
}