import 'dart:async';

import 'package:country_coder/country_coder.dart';
import 'package:csv/csv.dart';
import 'package:flag/flag_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'API/iss_api.dart';
import 'package:geojson_vi/geojson_vi.dart';
import 'dart:math';

class IssMap extends StatefulWidget {
  @override
  State<IssMap> createState() => _IssMapState();
}

class _IssMapState extends State<IssMap> {


  @override
  Widget build(BuildContext context) {
    IssMapState issMapState = context.watch<IssMapState>();
    Timer.periodic(Duration(seconds: 1), (timer) {
      if (!issMapState.pathPredicted) {
        predictNLatLng(issMapState, 10000);
      }
      else {
        timer.cancel();
      }
    });
    Timer.periodic(Duration(milliseconds: 500), (Timer t) => adjustPath(issMapState));
    return Stack(
      children: [
        FlutterMap(
          options: MapOptions(
            maxBounds: LatLngBounds( LatLng(-70, -190), LatLng(80, 190)),
            minZoom: 0,
            maxZoom: 8,
            zoom: 2,
          ),
          children: [
            TileLayer(
                urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                subdomains: ['a', 'b', 'c'],
            ),
            IssMarker(),
            IssPath(),
            IssPredictedPath(),
            SelectedMarker(),
          ],
        ),
        Align(
          alignment: Alignment.topRight,
          child: SpeedCard(),
        ),
        Align(
          alignment: Alignment.bottomLeft,
          child: CountrySelector(),
        )
      ]
    );
  }

  Future<void> adjustPath(IssMapState issMapState) async {
    LatLng exPos = IssApi.instance.getPreviousLatLng();
    LatLng currPos = IssApi.instance.getLatLng();
    int nDisplayed = issMapState.selectedTime != null ? issMapState.selectedTime!.difference(DateTime.now().add(Duration(hours: 2))).inSeconds~/9 + 1 : 0;

    if (nDisplayed != 0) {
      bool risingLat = exPos.latitude < currPos.latitude ? true : false;
      List<LatLng> predictedPath = issMapState.predictedPath;
      for(int i=0; i<predictedPath.length; i++) {
        if((predictedPath[i].latitude <= currPos.latitude && currPos.latitude <= predictedPath[i+1].latitude && risingLat) ||
            (predictedPath[i].latitude >= currPos.latitude && currPos.latitude >= predictedPath[i+1].latitude && !risingLat)) {
          issMapState.setAdjustedPath([currPos] + predictedPath.sublist(i+1, i+1+nDisplayed));
          break;
        }
      }
    }
  }

  Future<void> predictNLatLng(IssMapState issMapState,int nPredictions) async {
    LatLng exPos = IssApi.instance.getPreviousLatLng();
    LatLng currPos = IssApi.instance.getLatLng();
    double currTime = IssApi.instance.getTime();
    if (exPos != LatLng(0, 0) && currPos != LatLng(0, 0)) {
      final rawData = await rootBundle.loadString("assets/data1.csv");
      List<List<dynamic>> data = const CsvToListConverter(eol: '\n').convert(rawData);
      data.removeAt(0);

      List<double> lats = data.map((row) => double.parse(row[1].toString())).toList();
      List<double> lngs = data.map((row) => double.parse(row[2].toString())).toList();

      List<LatLng> predictions = [];
      List<double> predictionTimes = [];
      int correspondingIndex = 0;
      bool risingLat = exPos.latitude < currPos.latitude ? true : false;
      int i=0;
      while (correspondingIndex == 0) {
        if((lats[i] <= currPos.latitude && currPos.latitude <= lats[i+1] && risingLat) ||
            (lats[i] >= currPos.latitude && currPos.latitude >= lats[i+1] && !risingLat)) {
          correspondingIndex = i;
        }
        i++;
      }

      double ecartLat = currPos.latitude - lats[correspondingIndex];
      double ecartLng = currPos.longitude - lngs[correspondingIndex];

      for(int i=0; i<nPredictions; i++) {
        int ind = i%5580;
        double lat = lats[correspondingIndex + ind] + ecartLat;
        double lng = lngs[correspondingIndex + ind] + ecartLng;
        if (lng < -180) {lng += 360;}
        else if (lng > 180) {lng -= 360;}

        predictionTimes.add(currTime + 9*i);
        predictions.add(LatLng(lat, lng));
      }

      issMapState.setPredictionPath(predictions, predictionTimes);
      await countryCheck(issMapState);
    }
  }

  Future<List<String>> countriesWherePoint(LatLng point, Map<String,dynamic> index) async {
    List<String> correspondingCountriesI = [];
    index.forEach((name, bounds) {
      if(bounds[0] <= point.longitude &&
          point.longitude <= bounds[1] &&
          bounds[2] <= point.latitude &&
          point.latitude <= bounds[3] ) {
        if(!correspondingCountriesI.contains(name)) {
          correspondingCountriesI.add(name);
        }
      }
    });
    return correspondingCountriesI;
  }

  Future<void> countryCheck(IssMapState issMapState) async {
    // Load and parse your GeoJSON file for country boundaries (pseudo-code)
    final GeoJSONFeatureCollection countryBoundaries = GeoJSONFeatureCollection.fromJSON(await rootBundle.loadString('assets/ne_50m_admin_0_countries.geojson'));
    List<Map<String, dynamic>> listCountryNamePoly = [];

    // Iterate through country polygons to check if the point is inside any
    for (final feature in countryBoundaries.features) {
      if (feature?.geometry.type == GeoJSONType.polygon) {
        final polygon = feature?.geometry as GeoJSONPolygon;
        listCountryNamePoly.add({"name": feature?.properties?['name'],
          "polygon":polygon.coordinates[0]});
      }
      else if(feature?.geometry.type == GeoJSONType.multiPolygon) {
        final multiPoly = feature?.geometry as GeoJSONMultiPolygon;
        for(List<List<List<double>>> polygon in multiPoly.coordinates) {
          listCountryNamePoly.add({"name": feature?.properties?['name'],
            "polygon":polygon[0]});
          //debugPrint(polyString.substring(1, polyString.length-1));
        }
      }
    }
    List<LatLng> predictedPath = issMapState.predictedPath;

    Map<String, dynamic> index = {};
    String countryName = listCountryNamePoly[0]['name'];
    double minLng = 300, maxLng = -300, minLat = 100, maxLat = -100;
    for(int i=0; i<listCountryNamePoly.length; i++) {
      String newName = listCountryNamePoly[i]['name'];
      if(newName != countryName){
        index.addAll({countryName:[minLng, maxLng, minLat, maxLat]});
        minLng = 300; maxLng = -300; minLat = 100; maxLat = -100;
      }
      for(List<double> latlng in listCountryNamePoly[i]['polygon']){
        minLng = min(minLng, latlng[0]);
        maxLng = max(maxLng, latlng[0]);
        minLat = min(minLat, latlng[1]);
        maxLat = max(maxLat, latlng[1]);
      }
      countryName = newName;
    }

    List<Map<String, dynamic>> results = [];
    String name;
    for(var (i, point) in predictedPath.indexed) {
      List<String> selectedCountries = await countriesWherePoint(point, index);
      for(Map<String, dynamic> country in listCountryNamePoly) {
        name = country['name'];
        if(selectedCountries.contains(name)){
          GeoJSONPolygon poly = GeoJSONPolygon([country['polygon']]);
          if (poly.isPointInside([point.longitude, point.latitude]) && !results.any((m) => (m['name'] == name))) {
            results.add({'name':name, 'point':point, 'time':issMapState.predictedTimes[i]});
          }
        }
      }
    }

    issMapState.setPredictionCountries(results);
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
              child: position==LatLng(0, 0) ? CircularProgressIndicator() : Image.asset('images/iss.png')
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

class IssPredictedPath extends StatefulWidget {

  const IssPredictedPath({super.key});

  @override
  State<IssPredictedPath> createState() => _IssPredictedPathState();
}

class _IssPredictedPathState extends State<IssPredictedPath> {

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    IssMapState issMapState = context.watch<IssMapState>();
    return PolylineLayer(
      polylines: cutPath(issMapState.adjustedPath),
    );
  }

  List<Polyline> cutPath(List<LatLng> adjustedPath){
    List<Polyline> list = [];
    List<LatLng> segment = [];

    if (adjustedPath.isNotEmpty) {
      LatLng oldLoc = adjustedPath[0];
      late LatLng location;
      for(location in adjustedPath){
        segment.add(oldLoc);
        if((oldLoc.longitude - location.longitude).abs() > 180){
          list.add(
              Polyline(
                  points: List.from(segment),
                  color: Color.fromARGB(150, 107, 116, 128),
                  strokeWidth: 2
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
              color: Color.fromARGB(150, 107, 116, 128),
              strokeWidth: 2
          )
      );
      return list;
    }
    return [];
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

class CountrySelector extends StatefulWidget {
  const CountrySelector({super.key});

  @override
  State<CountrySelector> createState() => _CountrySelectorState();
}

class _CountrySelectorState extends State<CountrySelector> {

  final countries = CountryCoder.instance.load();

  @override
  Widget build(BuildContext context) {
    IssMapState issMapState = context.watch<IssMapState>();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Text('Next pass estimation', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),),
            DropdownButton(
              value: issMapState.selectedCountry,
              hint: issMapState.countryPredictionOver ? Text('Choose a country') : Text('Loading...'),
              icon: Icon(Icons.arrow_downward_outlined),
              onChanged: (name) {
                setState(() {
                  issMapState.setSelectedCountry(name);
                });
              },
              items: issMapState.predictedCountries.map<DropdownMenuItem>((e){
                return DropdownMenuItem<String>(
                  value: e['name'],
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flag.fromString(countries.iso1A2Code(lon:e['point'].longitude, lat: e['point'].latitude)!, width: 50),
                      SizedBox(width: 20),
                      Text(e['name']),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class SelectedMarker extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    IssMapState issMapState = context.watch<IssMapState>();
    return MarkerLayer(
      markers: issMapState.selectedLatlng != null ? [
        Marker(
          height: 100,
          width: 250,
          anchorPos: AnchorPos.align(AnchorAlign.center),
          point: issMapState.selectedLatlng!,
          builder: (BuildContext context) => Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              Expanded(
                flex: 1,
                child: Card(
                  color: Color.fromARGB(100, 255, 255, 255),
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Text("${issMapState.selectedTime.toString().substring(0,issMapState.selectedTime.toString().length - 5)} UTC+2 (Paris)",
                        style: TextStyle(fontSize: 12)),
                  ),
                ),
              ),
              Expanded(
                flex: 1, child: Icon(Icons.remove_red_eye)
              ),
              Expanded(
                flex: 1, child: SizedBox()
              )
            ],
          )
        )
      ] : [],
    );
  }
}

class IssMapState extends ChangeNotifier {
  List<Map<String, dynamic>> predictedCountries = [];
  List<LatLng> predictedPath = [];
  List<double> predictedTimes = [];
  List<LatLng> adjustedPath = [];
  bool pathPredicted = false;
  bool countryPredictionOver = false;

  String? selectedCountry;
  DateTime? selectedTime;
  LatLng? selectedLatlng;

  void setPredictionCountries(List<Map<String, dynamic>> predictionCountries) {
    predictedCountries = predictionCountries;
    predictedCountries.sort((a, b) => a['name'].compareTo(b['name']));
    countryPredictionOver = true;
    notifyListeners();
  }
  void setPredictionPath(List<LatLng> predictionPath, List<double> listTimes) {
    predictedPath = predictionPath;
    predictedTimes = listTimes;
    pathPredicted = true;
    notifyListeners();
  }
  void setAdjustedPath(List<LatLng> adjustedPath) {
    this.adjustedPath = adjustedPath;
    notifyListeners();
  }
  void setSelectedCountry(String name) {
    selectedCountry = name;
    selectedTime = DateTime.fromMillisecondsSinceEpoch(predictedCountries.firstWhere((e) => e['name'] == selectedCountry)['time'].toInt() * 1000).toUtc().add(Duration(hours: 2));
    selectedLatlng = predictedCountries.firstWhere((e) => e['name'] == selectedCountry)['point'];
    notifyListeners();
  }
}