import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class IssApi {
  Future<Map<String, double>> getIssPosition() async {
    final response = await http.get(Uri.parse('http://api.open-notify.org/iss-now.json'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final double lat = double.parse(data['iss_position']['latitude']);
      final double lon = double.parse(data['iss_position']['longitude']);
      return {'latitude': lat, 'longitude': lon};
    } else {
      throw Exception('Failed to load ISS position');
    }
  }
}
