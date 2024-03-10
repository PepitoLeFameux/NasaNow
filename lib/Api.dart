import 'dart:developer';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';

class Api{
  final apiKey = '0pVa9K2kUiwq4AiTue75Rz77ncgIUfCB6cx5HFAh';

  Future<Map<String, String>> getAPOD() async {
    final response = await Dio().get(
      'https://api.nasa.gov/planetary/apod',
      queryParameters: {'api_key': apiKey}
    );
    return {
      'hdurl': response.data.containsKey('hdurl') ? response.data['hdurl'] : response.data['url'],
      'url':response.data['url'],
      'desc': response.data['explanation']};
  }

  Future<List<Map<String, String>>> getAPODDays(int n) async {

    DateTime nDaysAgo = DateTime.now().subtract(Duration(days: n));
    String formattedDate = DateFormat('yyyy-MM-dd').format(nDaysAgo);



    final response = await Dio().get(
        'https://api.nasa.gov/planetary/apod',
        queryParameters: {'api_key': apiKey, 'start_date': formattedDate}
    );

    List<Map<String, String>> hdUrls = List<Map<String, String>>.from(
      response.data.map((item) => {'hdurl': item['hdurl'], 'url':response.data['url'], 'desc': item['explanation']})
    );

    return hdUrls;
  }
}