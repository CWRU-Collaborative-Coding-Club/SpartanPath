package com.example.rhaproject;

import android.os.Bundle;
import androidx.activity.ComponentActivity;
import com.mapbox.geojson.Point;
import com.mapbox.maps.CameraOptions;
import com.mapbox.maps.MapView;

public class MainActivity extends ComponentActivity {
    private MapView mapView;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        // Create a map programmatically and set the initial camera
        mapView = new MapView(this);
        mapView.getMapboxMap().setCamera(
                new CameraOptions.Builder()
                        .center(Point.fromLngLat(-98.0, 39.5))
                        .pitch(0.0)
                        .zoom(2.0)
                        .bearing(0.0)
                        .build()
        );

        // Add the map view to the activity
        setContentView(mapView);
    }
}
