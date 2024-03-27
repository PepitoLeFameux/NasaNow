import 'dart:ffi';
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:nasa_now/API/api.dart';
import 'package:full_screen_image/full_screen_image.dart';

class ApodSelectionNotifier with ChangeNotifier {
  int selectedApod = 0;
  String selectedDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
  final api = Api.instance;

  void setSelectedApod(String date) {
    selectedApod = api.dateToIndex(date);
    selectedDate = date;
    notifyListeners();
  }
}

class APODPage extends StatefulWidget{
  const APODPage({Key? key});

  @override
  State<APODPage> createState() => _APODPageState();
}

class _APODPageState extends State<APODPage> {
  final api = Api.instance;
  final ApodSelectionNotifier notifier = ApodSelectionNotifier();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Astronomy Picture of the Day'),
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('images/background_apod.jpeg'),
            fit: BoxFit.cover,
          ),
        ),
        child: ChangeNotifierProvider<ApodSelectionNotifier>.value(
          value: notifier,
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: api.getApodInfos(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              } else {
                List<Map<String, dynamic>> items = snapshot.data!.toList();
                return Column(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Row(
                          children: [
                            Expanded(
                              flex: 1,
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Card(
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: SingleChildScrollView(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.stretch,
                                        children: [
                                          Consumer<ApodSelectionNotifier>(
                                            builder: (context, notifier, child){
                                              return Text('Astronomy Picture Of the Day - ${DateFormat.yMMMd().format(DateTime.parse(notifier.selectedDate))} - ${items[notifier.selectedApod]['title']}');
                                            },
                                          ),
                                          SizedBox(height: 8),
                                          Consumer<ApodSelectionNotifier>(
                                            builder: (context, notifier, child){
                                              return Card(
                                                child: Padding(
                                                  padding: const EdgeInsets.all(8.0),
                                                  child: Text(
                                                    items[notifier.selectedApod]['desc']!,
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                          SizedBox(height: 8),
                                          Consumer<ApodSelectionNotifier>(
                                            builder: (context, notifier, child){
                                              return Card(
                                                child: Padding(
                                                  padding: const EdgeInsets.all(8.0),
                                                  child: Text(
                                                    "Copyright: ${items[notifier.selectedApod]['copyright']}",
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                                flex: 1,
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Consumer<ApodSelectionNotifier>(
                                      builder: (context, notifier, child){
                                        return FutureBuilder<Uint8List>(
                                            future: api.getApodImageData(items[notifier.selectedApod]['date'], true),
                                            builder: (context, snapshot) {
                                              if (snapshot.connectionState == ConnectionState.waiting) {
                                                return Center(child: CircularProgressIndicator());
                                              } else if (snapshot.hasError) {
                                                return Text('Error: ${snapshot.error}');
                                              } else {
                                                return Container(
                                                    child: FullScreenWidget(
                                                        disposeLevel: DisposeLevel.Medium,
                                                        child: Hero(
                                                            tag: "Astronomy Picture of The Day",
                                                            child: Image.memory(snapshot.data!)
                                                        )
                                                    )
                                                );
                                              }
                                            }
                                        );
                                      }
                                  ),
                                )
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                          flex: 1,
                          child: ApodGallery(items: items)
                      )
                    ]
                );
              }
            },
          ),
        ),
      ),
    );
  }
}


class PictureInfoContainer extends StatelessWidget {
  final String title;
  final String content;

  const PictureInfoContainer({
    Key? key,
    required this.title,
    required this.content,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }
}

class ApodGallery extends StatefulWidget{
  final List<Map<String, dynamic>> items;

  const ApodGallery({
    super.key,
    required this.items,
  });

  @override
  State<ApodGallery> createState() => _ApodGalleryState();
}

class _ApodGalleryState extends State<ApodGallery> {


  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.only(topLeft: Radius.circular(8), topRight: Radius.circular(8)),
      child: Container(
        color: Color.fromARGB(50, 0, 0, 0),
        child: GridView(
          gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 200,
            childAspectRatio: 16/9,
          ),
          children: [
            for(var item in widget.items)
              Consumer<ApodSelectionNotifier>(
                  builder: (context, notifier, child){
                    return ApodCard(date: item['date'], selectedDate: notifier.selectedDate);
                  }
              )
          ],
        ),
      ),
    );
  }
}

class ApodCard extends StatelessWidget {

  final String date;
  final String selectedDate;

  const ApodCard({
    super.key,
    required this.date,
    required this.selectedDate,
  });

  @override
  Widget build(BuildContext context){
    return Padding(
      padding: EdgeInsets.all(4),
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
                    onTap: (){Provider.of<ApodSelectionNotifier>(context, listen: false).setSelectedApod(date);},
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                        padding: EdgeInsets.all(3 ),
                        decoration: BoxDecoration(
                            color: date == selectedDate ? Color(0xFFF7FFF7)
                                : Color(0xFF829B87),
                            borderRadius: BorderRadius.circular(12)
                        ),
                        child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.memory(
                                    snapshot.data!,
                                    fit:BoxFit.cover
                                ),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Container(
                                        color: Color(0x88F7FFF7),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(date),
                                          ],
                                        )
                                    )
                                  ],
                                )
                              ],
                            )
                        )
                    ),
                  );
                }
              }
          )
      ),
    );
  }
}