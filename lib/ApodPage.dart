import 'dart:ffi';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nasa_now/API/iss_api.dart';
import 'package:provider/provider.dart';
import 'package:nasa_now/API/api.dart';
import 'package:full_screen_image/full_screen_image.dart';

class APODPage extends StatefulWidget{
  const APODPage({super.key});

  @override
  State<APODPage> createState() => _APODPageState();
}

class _APODPageState extends State<APODPage> {

  final api = Api.instance;

  @override
  Widget build(BuildContext context){
    ApodNotifier apodNotifier = context.watch<ApodNotifier>();
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.4),
        borderRadius: BorderRadius.all(Radius.zero),
      ),
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
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Container(
                      color: Colors.transparent,
                      padding: EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Astronomy Picture Of the Day - ${DateFormat.yMMMd().format(DateTime.parse(apodNotifier.selectedDate))} - ${items[apodNotifier.selectedIndex]['title']}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.black54,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            items[apodNotifier.selectedIndex]['desc']!,
                            style: TextStyle(fontSize: 11, color: Colors.black45),
                          ),
                          SizedBox(height: 8),
                          Text(
                            "Copyright: ${items[apodNotifier.selectedIndex]['copyright']}",
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
                          future: Api.instance.getApodImageData(items[apodNotifier.selectedIndex]['date'], true),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return Center(child: CircularProgressIndicator());
                            } else if (snapshot.hasError) {
                              return Text('Error: ${snapshot.error}');
                            } else {
                              return FullScreenWidget(
                                disposeLevel: DisposeLevel.Low,
                                child: Hero(
                                  tag: "Astronomy Picture of The Day",
                                  child: Image.memory(
                                    snapshot.data!,
                                    fit: BoxFit.contain,
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
    ApodNotifier apodNotifier = context.watch<ApodNotifier>();
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
              ApodCard(date: item['date'], selectedDate: apodNotifier.selectedDate),
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
    ApodNotifier apodNotifier = context.watch<ApodNotifier>();
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
                onTap: () => apodNotifier.setSelectedApod(date),
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


class ApodNotifier extends ChangeNotifier {


  int selectedIndex = 0;
  String selectedDate = DateFormat('yyyy-MM-dd').format(DateTime.now());

  void setSelectedApod(String date) {
    selectedIndex = Api.instance.dateToIndex(date);
    selectedDate = date;
    notifyListeners();
  }
}