import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

class Coordinates {
    final double lat;
    final double lng;

  Coordinates({required this.lat, required this.lng});
}

class Location {


    final String buildingName;
    final String buildingSISName; 
    final Coordinates buildingCoordinates;
    final List<Coordinates>? entranceCoordinates;


    Location({required this.buildingName, required this.buildingSISName,required this.buildingCoordinates, this.entranceCoordinates});
    factory Location.fromDocument(DocumentSnapshot doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Location(
            buildingName: data['buildingName'],
            buildingCoordinates: Coordinates(
                lat: data['buildingCoordinates']['lat'],
                lng: data['buildingCoordinates']['lng'],
            ),
            entranceCoordinates: data['entranceCoordinates'] != null
                ? (data['entranceCoordinates'] as List)
                    .map((e) => Coordinates(lat: e['lat'], lng: e['lng']))
                    .toList()
                : null,
            buildingSISName: data['buildingSISName'],
        );
    }
}

Future<void> initializeFirebase() async {
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
    );
}
Future<List<Location>> getLocations() async {
    FirebaseFirestore db = FirebaseFirestore.instance;
    try {
        QuerySnapshot querySnapshot = await db.collection('locations').get();
        List<Location> locations = [];
        for (var doc in querySnapshot.docs) {
            locations.add(Location.fromDocument(doc));
        }
        return locations;
    } catch (e) {
        print('Error fetching locations: $e');
        return [];
    }
}

