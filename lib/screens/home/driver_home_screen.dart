import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:se_project/providers/location_provider.dart';
import 'package:se_project/providers/ride_provider.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:math' as math;

class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  GoogleMapController? _mapController;
  bool _showRideRequestsPanel = false;
  bool _showBidPanel = false;
  String? _selectedRideId;
  final _bidAmountController = TextEditingController();
  List<RideRequest> _nearbyRideRequests = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _fetchNearbyRideRequests();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _bidAmountController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    await Provider.of<LocationProvider>(context, listen: false)
        .getCurrentLocation();
  }

  Future<void> _fetchNearbyRideRequests() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final rideProvider = Provider.of<RideProvider>(context, listen: false);
      final requests = await rideProvider.getNearbyRideRequests();

      setState(() {
        _nearbyRideRequests = requests;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching nearby ride requests: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    // Apply custom map style here if needed
  }

  void _showBidForm(String rideId) {
    setState(() {
      _selectedRideId = rideId;
      _showBidPanel = true;
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

          // Driver Status Panel
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            right: 16,
            child: GlassmorphicContainer(
              width: double.infinity,
              height: 100,
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
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      radius: 24,
                      child: const Icon(Icons.person,
                          size: 30, color: Colors.white),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Driver Name',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  borderRadius: BorderRadius.circular(5),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Online',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: true, // Online status
                      onChanged: (value) {
                        // Toggle online status
                      },
                      activeColor: Theme.of(context).colorScheme.primary,
                    ),
                  ],
                ),
              ),
            ).animate().fade().slideY(begin: -0.3),
          ),

          // Toggle Ride Requests Button
          Positioned(
            top: MediaQuery.of(context).padding.top + 132,
            right: 16,
            child: FloatingActionButton(
              backgroundColor: Theme.of(context).colorScheme.primary,
              heroTag: 'rideRequestsBtn',
              onPressed: () {
                setState(
                    () => _showRideRequestsPanel = !_showRideRequestsPanel);
              },
              child: Icon(
                _showRideRequestsPanel ? Icons.close : Icons.list,
                color: Colors.white,
              ),
            ),
          ),

          // Ride Requests Panel
          if (_showRideRequestsPanel)
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
                            'Ride Requests',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              setState(() => _showRideRequestsPanel = false);
                            },
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : _nearbyRideRequests.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.search_off,
                                        size: 48,
                                        color: Colors.grey,
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'No ride requests available',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyLarge,
                                      ),
                                      const SizedBox(height: 24),
                                      ElevatedButton.icon(
                                        onPressed: _fetchNearbyRideRequests,
                                        icon: const Icon(Icons.refresh),
                                        label: const Text('Refresh'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                          foregroundColor: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : ListView.builder(
                                  itemCount: _nearbyRideRequests.length,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16),
                                  itemBuilder: (context, index) {
                                    final ride = _nearbyRideRequests[index];
                                    return Card(
                                      color: Colors.white.withOpacity(0.1),
                                      margin: const EdgeInsets.only(bottom: 10),
                                      elevation: 3,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: ListTile(
                                        contentPadding:
                                            const EdgeInsets.all(16),
                                        leading: CircleAvatar(
                                          backgroundColor: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                          child: const Icon(Icons.location_on,
                                              color: Colors.white),
                                        ),
                                        title: Text(
                                          '${ride.pickup} → ${ride.destination}',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold),
                                        ),
                                        subtitle: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const SizedBox(height: 8),
                                            Row(
                                              children: [
                                                Icon(Icons.straighten,
                                                    size: 16,
                                                    color: Colors.grey[400]),
                                                const SizedBox(width: 4),
                                                Text(
                                                    'Distance: ${ride.distance}'),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                Icon(Icons.timer,
                                                    size: 16,
                                                    color: Colors.grey[400]),
                                                const SizedBox(width: 4),
                                                Text(
                                                    'Est. Time: ${ride.estimatedTime}'),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                Icon(Icons.currency_rupee,
                                                    size: 16,
                                                    color: Colors.grey[400]),
                                                const SizedBox(width: 4),
                                                Text(
                                                    'Est. Fare: ₹${ride.fare}'),
                                              ],
                                            ),
                                          ],
                                        ),
                                        trailing: ElevatedButton(
                                          onPressed: () =>
                                              _showBidForm(ride.id),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Theme.of(context)
                                                .colorScheme
                                                .secondary,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 16, vertical: 12),
                                          ),
                                          child: const Text('Place Bid'),
                                        ),
                                        onTap: () {
                                          // Show pickup and destination on map
                                          // This needs geolocation data - we'll need to enhance
                                          // the RideRequest to include LatLng data
                                          final locationProvider =
                                              Provider.of<LocationProvider>(
                                                  context,
                                                  listen: false);
                                          // For now we're just demonstrating - in a real app
                                          // we would convert address to coordinates
                                        },
                                      ),
                                    );
                                  },
                                ),
                    ),
                  ],
                ),
              ).animate().fade().slideY(begin: 1.0),
            ),

          // Bid Submission Panel
          if (_showBidPanel)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: GlassmorphicContainer(
                width: double.infinity,
                height: 200,
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
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Place Your Bid',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              setState(() => _showBidPanel = false);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _bidAmountController,
                        keyboardType:
                            TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: 'Bid Amount (\$)',
                          hintText: 'Enter your bid',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.9),
                          prefixIcon: const Icon(Icons.attach_money),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            if (_bidAmountController.text.isNotEmpty &&
                                _selectedRideId != null) {
                              // Submit bid
                              final amount =
                                  double.tryParse(_bidAmountController.text) ??
                                      0;
                              if (amount > 0) {
                                // Get the driver ID from authentication
                                // For now, we'll use a placeholder
                                final driverId = "driver_123";

                                Provider.of<RideProvider>(context,
                                        listen: false)
                                    .placeBid(
                                  driverId,
                                  amount,
                                );

                                setState(() {
                                  _showBidPanel = false;
                                  _bidAmountController.clear();
                                });
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).colorScheme.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text(
                            'Submit Bid',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ).animate().fade().slideY(begin: 1.0),
            ),
        ],
      ),
    );
  }
}
