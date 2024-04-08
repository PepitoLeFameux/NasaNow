import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'API/api.dart';
import 'package:full_screen_image/full_screen_image.dart';

class ApodSelectionNotifier with ChangeNotifier {
  int selectedApod = 0;
  String selectedDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
  final api = Api.instance;

  void setSelectedApod(int index) {
    selectedApod = index;
    notifyListeners();
  }
}

class APODPage extends StatelessWidget {
  const APODPage({Key? key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.4),
          borderRadius: BorderRadius.only(
            topLeft: Radius.zero,
            topRight: Radius.zero,
            bottomLeft: Radius.zero,
            bottomRight: Radius.zero,
          ),
        ),
        child: ChangeNotifierProvider<ApodSelectionNotifier>(
          create: (_) => ApodSelectionNotifier(),
          child: Consumer<ApodSelectionNotifier>(
            builder: (context, notifier, _) {
              return FutureBuilder<List<Map<String, dynamic>>>(
                future: notifier.api.getApodInfos(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  } else {
                    List<Map<String, dynamic>> items = snapshot.data!.toList();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Container(
                            color: Colors.transparent,
                            padding: EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Astronomy Picture Of the Day - ${DateFormat.yMMMd().format(DateTime.parse(notifier.selectedDate))} - ${items[notifier.selectedApod]['title']}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black54,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  items[notifier.selectedApod]['desc']!,
                                  style: TextStyle(fontSize: 11, color: Colors.black45),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  "Copyright: ${items[notifier.selectedApod]['copyright']}",
                                  style: TextStyle(fontSize: 11, color: Colors.black54),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Container(
                              color: Colors.transparent,
                              child: FutureBuilder<Uint8List>(
                                future: notifier.api.getApodImageData(items[notifier.selectedApod]['date'], true),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState == ConnectionState.waiting) {
                                    return Center(child: CircularProgressIndicator());
                                  } else if (snapshot.hasError) {
                                    return Text('Error: ${snapshot.error}');
                                  } else {
                                    return FullScreenWidget(
                                      disposeLevel: DisposeLevel.Medium,
                                      child: Hero(
                                        tag: "Astronomy Picture of The Day",
                                        child: Image.memory(
                                          snapshot.data!,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    );
                                  }
                                },
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  }
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
