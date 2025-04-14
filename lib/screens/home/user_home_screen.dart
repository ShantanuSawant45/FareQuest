import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_places_flutter/google_places_flutter.dart';
import 'package:google_places_flutter/model/prediction.dart';
import 'package:provider/provider.dart';
import 'package:se_project/providers/location_provider.dart';
import 'package:se_project/providers/ride_provider.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:math' as math;
import 'package:se_project/screens/ride/current_ride_screen.dart';

class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({super.key});

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  GoogleMapController? _mapController;
  bool _showBidsPanel = false;
  final _pickupController = TextEditingController();
  final _destinationController = TextEditingController();
  static const _googleApiKey = 'AIzaSyAdpipaTyU946lJeZjrF-oTIyAtlvDkjoY';
  bool _showFareDetails = false;
  double _estimatedFare = 0.0;
  String _estimatedTime = "";
  String _estimatedDistance = "";

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _pickupController.dispose();
    _destinationController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    await Provider.of<LocationProvider>(context, listen: false)
        .getCurrentLocation();
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  void _calculateFare(double distanceInKm) {
    const baseFare = 50.0;
    const perKmCharge = 12.0;

    _estimatedFare = baseFare + (distanceInKm * perKmCharge);

    final timeInMinutes = (distanceInKm * 2 + 5).round();
    if (timeInMinutes < 60) {
      _estimatedTime = "$timeInMinutes mins";
    } else {
      final hours = timeInMinutes ~/ 60;
      final mins = timeInMinutes % 60;
      _estimatedTime = "$hours hr ${mins > 0 ? '$mins mins' : ''}";
    }

    _estimatedDistance = "${distanceInKm.toStringAsFixed(1)} km";

    setState(() {
      _showFareDetails = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Consumer<LocationProvider>(
            builder: (context, locationProvider, _) {
              final currentLocation = locationProvider.currentLocation;
              return GoogleMap(
                onMapCreated: _onMapCreated,
                initialCameraPosition: CameraPosition(
                  target: currentLocation ?? const LatLng(37.7749, -122.4194),
                  zoom: 15,
                ),
                myLocationEnabled: true,
                myLocationButtonEnabled: false,
                markers: {
                  ...locationProvider.markers,
                  if (currentLocation != null)
                    Marker(
                      markerId: const MarkerId('current_location'),
                      position: currentLocation,
                      icon: BitmapDescriptor.defaultMarkerWithHue(
                        BitmapDescriptor.hueViolet,
                      ),
                      infoWindow: const InfoWindow(title: 'Your Location'),
                    ),
                },
                polylines: locationProvider.polylines,
              );
            },
          ),

          // Location Input Panel
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            right: 16,
            child: GlassmorphicContainer(
              width: double.infinity,
              height: 180,
              borderRadius: 20,
              blur: 30,
              alignment: Alignment.center,
              border: 2,
              linearGradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.1),
                  Colors.white.withOpacity(0.05),
                ],
              ),
              borderGradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary.withOpacity(0.5),
                  Theme.of(context).colorScheme.secondary.withOpacity(0.5),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    GooglePlaceAutoCompleteTextField(
                      textStyle: TextStyle(
                          color: Colors.black, fontWeight: FontWeight.w400),
                      textEditingController: _pickupController,
                      googleAPIKey: _googleApiKey,
                      inputDecoration: InputDecoration(
                        hintText: 'Pickup Location',
                        hintStyle: TextStyle(color: Colors.black54,fontWeight: FontWeight.bold),
                        prefixIcon: Icon(
                          Icons.location_on,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.9),
                      ),
                      debounceTime: 800,
                      countries: const ["in"],
                      isLatLngRequired: true,
                      itemClick: (Prediction prediction) {
                        _pickupController.text = prediction.description ?? '';
                      },
                      seperatedBuilder: Divider(
                        height: 1,
                        color: Colors.grey.shade300,
                      ),
                      getPlaceDetailWithLatLng: (Prediction prediction) async {
                        final location = LatLng(
                            double.parse(prediction.lat ?? "0"),
                            double.parse(prediction.lng ?? "0"));
                        final locationProvider = Provider.of<LocationProvider>(
                            context,
                            listen: false);
                        locationProvider.setPickupLocation(location);
                        _mapController?.animateCamera(
                          CameraUpdate.newLatLngZoom(location, 15),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    GooglePlaceAutoCompleteTextField(
                      textStyle: TextStyle(
                          color: Colors.black, fontWeight: FontWeight.w400),
                      textEditingController: _destinationController,
                      googleAPIKey: _googleApiKey,
                      inputDecoration: InputDecoration(
                        hintText: 'Destination',
                        hintStyle: TextStyle(color: Colors.black54,fontWeight: FontWeight.bold),
                        prefixIcon: Icon(
                          Icons.location_searching,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.9),
                      ),
                      debounceTime: 800,
                      countries: const ["in"],
                      isLatLngRequired: true,
                      itemClick: (Prediction prediction) {
                        _destinationController.text =
                            prediction.description ?? '';
                      },
                      seperatedBuilder: Divider(
                        height: 1,
                        color: Colors.grey.shade300,
                      ),
                      getPlaceDetailWithLatLng: (Prediction prediction) async {
                        final location = LatLng(
                            double.parse(prediction.lat ?? "0"),
                            double.parse(prediction.lng ?? "0"));

                        final locationProvider = Provider.of<LocationProvider>(
                            context,
                            listen: false);
                        locationProvider.setDestinationLocation(location);

                        _mapController?.animateCamera(
                          CameraUpdate.newCameraPosition(
                            CameraPosition(
                              target: location,
                              zoom: 15,
                            ),
                          ),
                        );

                        if (locationProvider.pickupLocation != null &&
                            locationProvider.destinationLocation != null) {
                          final double distanceInMeters =
                          await _calculateDistance(
                              locationProvider.pickupLocation!,
                              locationProvider.destinationLocation!);

                          final distanceInKm = distanceInMeters / 1000;
                          _calculateFare(distanceInKm);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ).animate().fade().slideY(begin: -0.3),
          ),

          // Fare Details Panel
          if (_showFareDetails)
            Positioned(
              bottom: _showBidsPanel ? 300 : 96,
              left: 16,
              right: 16,
              child: GlassmorphicContainer(
                width: double.infinity,
                height: 130,
                borderRadius: 20,
                blur: 20,
                alignment: Alignment.center,
                border: 2,
                linearGradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.1),
                    Colors.white.withOpacity(0.05),
                  ],
                ),
                borderGradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary.withOpacity(0.5),
                    Theme.of(context).colorScheme.secondary.withOpacity(0.5),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Distance:',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(
                            _estimatedDistance,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Estimated Time:',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(
                            _estimatedTime,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Estimated Fare:',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(
                            '₹${_estimatedFare.toStringAsFixed(2)}',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ).animate().fade().slideY(begin: 0.3),
            ),

          // Request Ride Button
          Positioned(
            bottom: _showBidsPanel ? 300 : 32,
            left: 16,
            right: 16,
            child: ElevatedButton(
              onPressed: _showFareDetails
                  ? () {
                setState(() => _showBidsPanel = true);
                final locationProvider = Provider.of<LocationProvider>(context, listen: false);
                Provider.of<RideProvider>(context, listen: false)
                    .requestRide(
                  "user_id",
                  {
                    "pickup": _pickupController.text,
                    "destination": _destinationController.text,
                    "fare": _estimatedFare,
                    "distance": _estimatedDistance,
                    "estimatedTime": _estimatedTime,
                    "pickupLatLng": {
                      "lat": locationProvider.pickupLocation!.latitude,
                      "lng": locationProvider.pickupLocation!.longitude,
                    },
                    "destinationLatLng": {
                      "lat": locationProvider.destinationLocation!.latitude,
                      "lng": locationProvider.destinationLocation!.longitude,
                    },
                  },
                );
              }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                disabledBackgroundColor: Colors.grey.shade400,
              ),
              child: const Text(
                'Request Ride',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold,color: Colors.black),
              ),
            ).animate().fade().slideY(begin: 0.3),
          ),

          // Bids Panel
          if (_showBidsPanel)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: GlassmorphicContainer(
                width: double.infinity,
                height: 280,
                borderRadius: 20,
                blur: 20,
                border: 2,
                linearGradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.1),
                    Colors.white.withOpacity(0.05),
                  ],
                ),
                borderGradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary.withOpacity(0.5),
                    Theme.of(context).colorScheme.secondary.withOpacity(0.5),
                  ],
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Driver Bids',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          IconButton(
                            icon: const Icon(Icons.close,color: Colors.black,),
                            onPressed: () {
                              setState(() => _showBidsPanel = false);
                            },
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Consumer<RideProvider>(
                        builder: (context, rideProvider, _) {
                          if (rideProvider.currentBids.isEmpty) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const CircularProgressIndicator(),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Waiting for driver bids...',
                                    style:TextStyle(color: Colors.black54,fontWeight: FontWeight.bold)

                                  ),
                                ],
                              ),
                            );
                          }
                          return ListView.builder(
                            itemCount: rideProvider.currentBids.length,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemBuilder: (context, index) {
                              final bid = rideProvider.currentBids[index];
                              return Card(
                                color: Colors.white.withOpacity(0.1),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor:
                                    Theme.of(context).colorScheme.primary,
                                    child: const Icon(Icons.person),
                                  ),
                                  title: Text('Driver ${bid.driverId}'),
                                  subtitle: Text(
                                    'Bid: \$${bid.amount.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .secondary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  trailing: ElevatedButton(
                                    onPressed: () {
                                      rideProvider.selectBid(bid);
                                      final locationProvider = Provider.of<LocationProvider>(context, listen: false);
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              CurrentRideScreen(
                                                rideId: rideProvider.currentRideId!,
                                                acceptedBid: bid,
                                                pickupLocation: locationProvider.pickupLocation!,
                                                destinationLocation: locationProvider.destinationLocation!,
                                              ),
                                        ),
                                      );
                                    },
                                    child: const Text('Accept'),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ).animate().fade().slideY(begin: 1.0),
            ),
        ],
      ),
    );
  }

  Future<double> _calculateDistance(LatLng pickup, LatLng destination) async {
    const radius = 6371.0;

    final lat1 = pickup.latitude * (math.pi / 180);
    final lon1 = pickup.longitude * (math.pi / 180);
    final lat2 = destination.latitude * (math.pi / 180);
    final lon2 = destination.longitude * (math.pi / 180);

    final dlon = lon2 - lon1;
    final dlat = lat2 - lat1;
    final a = math.pow(math.sin(dlat / 2), 2) +
        math.cos(lat1) * math.cos(lat2) * math.pow(math.sin(dlon / 2), 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return radius * c * 1000;
  }
}