import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nasa_now/Api.dart';


class APODPage extends StatelessWidget{
  const APODPage({super.key});

  @override
  Widget build(BuildContext context){
    return Column(
      children: [
        Expanded(
          flex: 2,
          child: SingleChildScrollView(
            child: Column(
              children: [

              ],
            ),
          ),
        ),
        Divider(color: Colors.white, indent: 30, endIndent: 30),
        Expanded(
          flex: 2,
          child: GridView(
            gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 100,
                childAspectRatio: 16/9
            ),
          ),
        )
      ],
    );
  }
}