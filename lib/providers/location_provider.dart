import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class LocationProvider with ChangeNotifier {
  LatLng? _currentLocation;
  LatLng? _pickupLocation;
  LatLng? _destinationLocation;
  final Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  List<LatLng> _polylineCoordinates = [];

  LatLng? get currentLocation => _currentLocation;
  LatLng? get pickupLocation => _pickupLocation;
  LatLng? get destinationLocation => _destinationLocation;
  Set<Marker> get markers => _markers;
  Set<Polyline> get polylines => _polylines;

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
  //     PolylinePoints polylinePoints = PolylinePoints();
  //     PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
  //       'AIzaSyAdpipaTyU946lJeZjrF-oTIyAtlvDkjoY', // Use your API key
  //       PointLatLng(_pickupLocation!.latitude, _pickupLocation!.longitude),
  //       PointLatLng(
  //           _destinationLocation!.latitude, _destinationLocation!.longitude), request: null!,
  //     );
  //     _polylineCoordinates.clear();
  //     if (result.points.isNotEmpty) {
  //       for (var point in result.points) {
  //         _polylineCoordinates.add(LatLng(point.latitude, point.longitude));
  //       }
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
