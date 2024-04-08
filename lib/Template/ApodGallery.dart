import 'package:flutter/material.dart';
import 'package:nasa_now/API/api.dart';
import 'package:nasa_now/ApodPage.dart';
import 'package:provider/provider.dart';
import 'dart:typed_data';

class ApodGalleryPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('APOD Gallery'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: Api.instance.getApodInfos(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          } else {
            List<Map<String, dynamic>> items = snapshot.data!.toList();
            return ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) {
                return ApodCard(
                  date: items[index]['date'],
                  index: index, // Pass the index here
                );
              },
            );
          }
        },
      ),
    );
  }
}

class ApodCard extends StatelessWidget {
  final String date;
  final int index; // New index parameter

  const ApodCard({
    required this.date,
    required this.index, // Added index parameter
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(8),
      child: Card(
        child: FutureBuilder<Uint8List>(
          future: Api.instance.getApodImageData(date, false),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            } else {
              return InkWell(
                onTap: () {
                  Provider.of<ApodSelectionNotifier>(context, listen: false).setSelectedApod(index); // Pass the index here
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Image.memory(
                      snapshot.data!,
                      fit: BoxFit.cover,
                    ),
                    Padding(
                      padding: EdgeInsets.all(8),
                      child: Text(
                        date,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              );
            }
          },
        ),
      ),
    );
  }
}
