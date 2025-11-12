import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:mapbox_navigation_flutter/mapbox_navigation_flutter.dart';

import 'db.dart';

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
  
  Future<void> _onRouteEvent(e) async {

        _distanceRemaining = await _directions.distanceRemaining;
        _durationRemaining = await _directions.durationRemaining;
    
        switch (e.eventType) {
          case MapBoxEvent.progress_change:
            var progressEvent = e.data as RouteProgressEvent;
            _arrived = progressEvent.arrived;
            if (progressEvent.currentStepInstruction != null)
              _instruction = progressEvent.currentStepInstruction;
            break;
          case MapBoxEvent.route_building:
          case MapBoxEvent.route_built:
            _routeBuilt = true;
            break;
          case MapBoxEvent.route_build_failed:
            _routeBuilt = false;
            break;
          case MapBoxEvent.navigation_running:
            _isNavigating = true;
            break;
          case MapBoxEvent.on_arrival:
            _arrived = true;
            if (!_isMultipleStop) {
              await Future.delayed(Duration(seconds: 3));
              await _controller.finishNavigation();
            } else {}
            break;
          case MapBoxEvent.navigation_finished:
          case MapBoxEvent.navigation_cancelled:
            _routeBuilt = false;
            _isNavigating = false;
            break;
          default:
            break;
        }
        //refresh UI
        setState(() {});
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

  Future<void> startNavigation(Location location) async {
    final origin = await _mapboxMap!.location.getLastKnownLocation();
    if (origin == null) {
      print('User location not available');
      return;
    }

    final destination = Point(
      coordinates: Position(
        location.buildingCoordinates.lng,
        location.buildingCoordinates.lat,
      ),
    );

    final options = MapBoxOptions(
      initialLatitude: origin.latitude,
      initialLongitude: origin.longitude,
      destinationLatitude: location.buildingCoordinates.lat,
      destinationLongitude: location.buildingCoordinates.lng,
      mode: MapBoxNavigationMode.drivingWithTraffic,
      simulateRoute: false,
    );

    await MapBoxNavigation.instance.startNavigation(options);
  }

  @override
  Widget build(BuildContext context) {
    MapBoxNavigation.instance.registerRouteEventListener(_onRouteEvent);
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
