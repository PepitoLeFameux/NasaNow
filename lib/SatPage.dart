import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nasa_now/API/apiSat.dart';

class SatSelectionNotifier with ChangeNotifier {
  int selectedSatellite = 0;
  final List<Satellite> satellites;
  SatSelectionNotifier(this.satellites);

  void setSelectedSatellite(int index) {
    selectedSatellite = index;
    notifyListeners();
  }
}

class SatPage extends StatefulWidget {
  const SatPage({Key? key}) : super(key: key);

  @override
  _SatPageState createState() => _SatPageState();
}

class _SatPageState extends State<SatPage> {
  final api = SatelliteApi(apiKey: 'dZISEuetcZ7WiCrmQIsuKzJoaK3Zd8i1eSIhVJ3l');

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Satellite>>(
      future: api.getAllSatellites(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else {
          final satellites = snapshot.data!;
          final notifier = SatSelectionNotifier(satellites);
          return ChangeNotifierProvider<SatSelectionNotifier>.value(
            value: notifier,
            child: Scaffold(
              appBar: AppBar(title: Text('Satellite Information')),
              body: Column(
                children: [
                  Expanded(
                    flex: 1,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Consumer<SatSelectionNotifier>(
                            builder: (context, notifier, _) {
                              final selectedSatellite =
                              notifier.satellites[notifier.selectedSatellite];
                              return Text('Selected Satellite: ${selectedSatellite.name}');
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 6,
                    child: ListView.builder(
                      itemCount: satellites.length,
                      itemBuilder: (context, index) {
                        final satellite = satellites[index];
                        return ListTile(
                          title: Text(satellite.name),
                          onTap: () => notifier.setSelectedSatellite(index),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      },
    );
  }
}