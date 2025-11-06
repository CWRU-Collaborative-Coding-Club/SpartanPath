import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';

class MapScreen extends StatefulWidget {
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  MapboxMap? _mapboxMap;

  void _onMapCreated(MapboxMap mapboxMap) {
    _mapboxMap = mapboxMap;
  }

  // Apply bounds and enable location when the style is fully loaded.
  void _onStyleLoaded(StyleLoadedEventData data) {
    _restrictMapBounds();
    _enableUserLocation();
  }

  Future<void> _enableUserLocation() async {
    final status = await Permission.locationWhenInUse.request();
    if (status.isGranted || status.isLimited) {
      await _mapboxMap?.location.updateSettings(
        LocationComponentSettings(
          enabled: true,
          puckBearingEnabled: true,
          puckBearing: PuckBearing.HEADING,
          pulsingEnabled: true,
          showAccuracyRing: true,
        ),
      );
    }
  }

  Future<void> _restrictMapBounds() async {
    if (_mapboxMap == null) return;
    // Define the bounding box for CWRU
    CoordinateBounds cwruBounds = CoordinateBounds(
      southwest: Point(coordinates: Position(-81.6150, 41.5000)),
      northeast: Point(coordinates: Position(-81.6045, 41.5100)),
      infiniteBounds: false,
    );

    await _mapboxMap!.setBounds(CameraBoundsOptions(
      bounds: cwruBounds,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MapWidget(
        onMapCreated: _onMapCreated,
        onStyleLoadedListener: _onStyleLoaded,
        styleUri: MapboxStyles.MAPBOX_STREETS,
        // If needed, set the access token globally before running the app:
      ),
    );
  }
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  MapboxOptions.setAccessToken("pk.eyJ1IjoiY2hhcmFuNjkyNCIsImEiOiJjbWdsYW15azkwdXc1MmtxNDg1NXQzczJoIn0.Fn4bJ6dBWvp8xueF5J7Gbg");
  runApp(MaterialApp(
    home: MapScreen(),
  ));
}
