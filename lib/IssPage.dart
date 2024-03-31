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
  IssMap map = IssMap();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IssMap(),
    );
  }
}