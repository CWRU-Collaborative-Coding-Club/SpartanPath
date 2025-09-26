import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

class MapScreen extends StatefulWidget {
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  MapboxMap? mapboxMap;

  void _onMapCreated(MapboxMap mapboxMap) {
    this.mapboxMap = mapboxMap;
    _restrictMapBounds();
  }

  void _restrictMapBounds() async {
    if (mapboxMap != null) {
      // Define the bounding box for CWRU
      CoordinateBounds cwruBounds = CoordinateBounds(
        southwest: Point(coordinates: Position(-81.6150, 41.5000)), // (-81.6150, 41.5000),
        northeast: Point(coordinates: Position(-81.6045, 41.5100)),
        infiniteBounds: false
        
      );

      await mapboxMap!.setBounds(CameraBoundsOptions(
        bounds: cwruBounds,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MapWidget(
        onMapCreated: _onMapCreated,
        // If needed, set the access token globally before running the app:
      ),
    );
  }
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  MapboxOptions.setAccessToken("");
  runApp(MaterialApp(
    home: MapScreen(),
  ));
}