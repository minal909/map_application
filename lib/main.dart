import 'dart:math';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: PathRecorder(
      distanceBetweenPoints: 5,
    ),
  ));
}

class PathRecorder extends StatefulWidget {
  final double distanceBetweenPoints;

  const PathRecorder({Key? key, required this.distanceBetweenPoints})
      : super(key: key);

  @override
  State<PathRecorder> createState() => _PathRecorderState();
}

class _PathRecorderState extends State<PathRecorder> {
  List<Position> recordedPoints = [];
  Position? currentPosition;
  late GoogleMapController mapController;

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  Future<void> _getLocation() async {
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    setState(() {
      currentPosition = position;
    });
  }

  void _generatePath() async {
    if (currentPosition == null) {
      return;
    }
    double previousLatitude = currentPosition!.latitude;
    double previousLongitude = currentPosition!.longitude;

    for (double distance = widget.distanceBetweenPoints;
        distance < 150;
        distance += widget.distanceBetweenPoints) {
      double newLatitude = previousLatitude +
          distance / (111132 * (cos(previousLatitude * pi / 180)));
      double newLongitude = previousLongitude;

      recordedPoints.add(Position(
        latitude: newLatitude,
        longitude: newLongitude,
        timestamp: DateTime.now(),
        accuracy: 0.0,
        altitude: 0.0,
        altitudeAccuracy: 0.0,
        heading: 0.0,
        headingAccuracy: 0.0,
        speed: 0.0,
        speedAccuracy: 0.0,
      ));

      previousLatitude = newLatitude;
    }
    _updateMarkers();
  }

  Set<Marker> markers = {};

  Future<void> _requestLocationPermission() async {
    if (await Permission.location.request().isGranted) {
      await _getLocation();
    } else {}
  }

  void _updateMarkers() {
    markers.clear();
    for (Position position in recordedPoints) {
      markers.add(Marker(
        markerId: MarkerId(position.toString()),
        position: LatLng(position.latitude, position.longitude),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Path Recorder'),
        ),
        body: Stack(
          children: [
            GoogleMap(
              onMapCreated: _onMapCreated,
              initialCameraPosition: CameraPosition(
                target: LatLng(
                    currentPosition == null ? 0.0 : currentPosition!.latitude,
                    currentPosition == null ? 0.0 : currentPosition!.longitude),
                zoom: 11.0,
              ),
              markers: markers.toSet(),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton(
                    onPressed: _requestLocationPermission,
                    child: const Text('Get Location'),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: _generatePath,
                    child: const Text('Generate Path'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
