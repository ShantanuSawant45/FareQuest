import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';

class LocationProvider with ChangeNotifier {
  LatLng? _currentLocation;
  LatLng? _pickupLocation;
  LatLng? _destinationLocation;
  final Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  List<LatLng> _polylineCoordinates = [];
  StreamSubscription<Position>? _positionStream;
  bool _isLocationTracking = false;

  LatLng? get currentLocation => _currentLocation;
  LatLng? get pickupLocation => _pickupLocation;
  LatLng? get destinationLocation => _destinationLocation;
  Set<Marker> get markers => _markers;
  Set<Polyline> get polylines => _polylines;
  bool get isLocationTracking => _isLocationTracking;

  // TODO: if rhe user location is not on tell him to on the location

  Future<void> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    final position = await Geolocator.getCurrentPosition();
    _currentLocation = LatLng(position.latitude, position.longitude);
    notifyListeners();
  }

  // Start continuous location tracking
  void startLocationUpdates() {
    if (_isLocationTracking) return; // Already tracking

    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // Update if moved 10 meters
      timeLimit: Duration(seconds: 5), // Or after 5 seconds
    );

    _positionStream =
        Geolocator.getPositionStream(locationSettings: locationSettings)
            .listen((Position position) {

      _currentLocation = LatLng(position.latitude, position.longitude);

      // Update the current location marker
      _markers.removeWhere(
          (marker) => marker.markerId == const MarkerId('current_location'));

      _markers.add(
        Marker(
          markerId: const MarkerId('current_location'),
          position: _currentLocation!,
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
          infoWindow: const InfoWindow(title: 'Your Location'),
        ),
      );

      _isLocationTracking = true;
      notifyListeners();
    });
  }

  // Stop location tracking
  void stopLocationUpdates() {
    _positionStream?.cancel();
    _isLocationTracking = false;
    notifyListeners();
  }

  @override
  void dispose() {
    stopLocationUpdates();
    super.dispose();
  }

  void setPickupLocation(LatLng location) {
    _pickupLocation = location;
    _markers.removeWhere((m) => m.markerId == const MarkerId('pickup'));
    _markers.add(
      Marker(
        markerId: const MarkerId('pickup'),
        position: location,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: const InfoWindow(title: 'Pickup Location'),
      ),
    );
    notifyListeners();
  }

  void setDestinationLocation(LatLng location) {
    _destinationLocation = location;
    _markers.removeWhere((m) => m.markerId == const MarkerId('destination'));
    _markers.add(
      Marker(
        markerId: const MarkerId('destination'),
        position: location,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: const InfoWindow(title: 'Destination'),
      ),
    );
    notifyListeners();
  }

  // Future<void> updatePolylines() async {
  //   if (_pickupLocation != null && _destinationLocation != null) {
  //     final polylinePoints = PolylinePoints();
  //
  //     // Create the request object
  //     final request = PolylineRequest(
  //       origin: PointLatLng(_pickupLocation!.latitude, _pickupLocation!.longitude),
  //       destination: PointLatLng(_destinationLocation!.latitude, _destinationLocation!.longitude),
  //       mode: TravelMode.driving, // or .walking, .bicycling, .transit
  //       // apiKey: 'YOUR_GOOGLE_MAPS_API_KEY', // Replace with your actual API key
  //     );
  //
  //     final result = await polylinePoints.getRouteBetweenCoordinates(
  //       request: request,
  //     );
  //
  //     _polylineCoordinates.clear();
  //     if (result.points.isNotEmpty) {
  //       _polylineCoordinates = result.points
  //           .map((point) => LatLng(point.latitude, point.longitude))
  //           .toList();
  //     }
  //
  //     _polylines.clear();
  //     _polylines.add(Polyline(
  //       polylineId: const PolylineId('route'),
  //       color: Colors.blue,
  //       points: _polylineCoordinates,
  //       width: 5,
  //     ));
  //
  //     notifyListeners();
  //   }
  // }
}
