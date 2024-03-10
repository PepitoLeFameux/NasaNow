import 'dart:developer';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

class Api{
  final apiKey = '0pVa9K2kUiwq4AiTue75Rz77ncgIUfCB6cx5HFAh';
  List<Map<String, dynamic>> apodInfos = [];
  static int nDays = 1;
  bool alreadyInit = false;

  //Pour faire un singleton
  static final Api _instance = Api._privateConstructor();
  Api._privateConstructor();
  static Api get instance => _instance;

  Future<List<Map<String, dynamic>>> getApodInfos() async {

    List<Map<String, dynamic>> list = [];
    if (!alreadyInit) {
      DateTime nDaysAgo = DateTime.now().subtract(Duration(days: nDays));
      String formattedDate = DateFormat('yyyy-MM-dd').format(nDaysAgo);

      final response = await Dio().get(
          'https://api.nasa.gov/planetary/apod',
          queryParameters: {'api_key': apiKey, 'start_date': formattedDate}
      );


      for(var item in response.data){
        if(item['media_type'] == 'image'){


          final String imageUrl = item['url']!;
          final String date = item['date']!;
          final String path = 'APOD-$date.${imageUrl.split('.').last}';
          final String hdPath = 'APOD-$date-HD.${imageUrl.split('.').last}';

          debugPrint(date);

          Dio dio = Dio();
          var response = await dio.get<List<int>>(
            item.containsKey('hdurl') ? item['hdurl'] : item['url'],
            options: Options(responseType: ResponseType.bytes),
          );
          Uint8List hdData = Uint8List.fromList(response.data!);

          dio = Dio();
          response = await dio.get<List<int>>(
            item['url'],
            options: Options(responseType: ResponseType.bytes),
          );
          Uint8List data = Uint8List.fromList(response.data!);

          list.add({
            'hdurl': item.containsKey('hdurl') ? item['hdurl'] : item['url'],
            'url': item['url'],
            'desc': item['explanation'],
            'date': item['date'],
            'path': path,
            'hdpath': hdPath,
            'hddata': hdData,
            'data': data,
          });
        }
      }
      apodInfos = list;
      alreadyInit = true;
    }
    list = apodInfos;
    return list;
  }
}