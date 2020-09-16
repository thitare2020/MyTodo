import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class LoadingPages extends StatefulWidget {
  @override
  State createState() {
    return LoadingStage();
  }
}

class LoadingStage extends State<LoadingPages> {
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
      body: Center(
          child: Column(children: [
        Align(
          alignment: FractionalOffset.center,
          child: CircularProgressIndicator(),
        ),
        Text('Loading...')
      ])),
    );
  }
}
