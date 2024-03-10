import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nasa_now/api.dart';


class APODPage extends StatefulWidget{
  const APODPage({super.key});

  @override
  State<APODPage> createState() => _APODPageState();
}

class _APODPageState extends State<APODPage> {
  
  int selectedApod = 0;
  Future<List<String>>? apodDaysDesc;

  @override
  void initState(){
    super.initState();
  }
  
  @override
  Widget build(BuildContext context){
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: Api().getApodInfos(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else {
          // Display the images
          List<Map<String, dynamic>> items = snapshot.data!.reversed.toList();
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text('Astronomy Picture Of the Day'),
                  ),
                ),
              ),
              Divider(color: Colors.white, indent: 100, endIndent: 100,),
              Expanded(
                flex: 3,
                child: Row(
                  children: [
                    Expanded(
                        flex: 3,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Image.memory(items[0]['hddata']),
                        )
                    ),
                    Expanded(
                        flex: 4,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: SingleChildScrollView(child: Text(items[0]['desc']!)),
                            ),
                          ),
                        )
                    )
                  ],
                ),
              ),
              VerticalDivider(color: Colors.white, indent: 30, endIndent: 30),
              Expanded(
                flex: 2,
                child: GridView(
                  gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 100,
                      childAspectRatio: 16/9
                  ),
                ),
              )
            ]
          );
        }
      },
    );
  }
}