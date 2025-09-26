import 'package:flutter/material.dart';

class MapsDemo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text('MapboxMaps examples')),
        body: Text("Mapbox Maps examples will go here"));
  }
}

void main() {
  runApp(MaterialApp(home: MapsDemo()));
}
