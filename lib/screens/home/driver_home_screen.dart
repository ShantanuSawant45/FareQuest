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
  bool _isDriverOnline = true;
  DateTime? _lastRefreshTime;

  @override
  void initState() {
    super.initState();
    _initializeLocationTracking();
    _fetchNearbyRideRequests();

    // Set up auto-refresh timer for every 30 seconds
    Future.delayed(Duration.zero, () {
      _setupAutoRefresh();
    });
  }

  void _setupAutoRefresh() {
    // Only set up timer if not already set
    Future.delayed(const Duration(seconds: 30), () {
      if (mounted && _isDriverOnline) {
        _fetchNearbyRideRequests();
        _setupAutoRefresh(); // Schedule next refresh
      }
    });
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _bidAmountController.dispose();
    super.dispose();
  }

  Future<void> _initializeLocationTracking() async {
    final locationProvider =
    Provider.of<LocationProvider>(context, listen: false);

    await locationProvider.getCurrentLocation();

    locationProvider.startLocationUpdates();

    if (_mapController != null && locationProvider.currentLocation != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(
          locationProvider.currentLocation!,
          17.0,
        ),
      );
    }
  }

  Future<void> _getCurrentLocation() async {
    final locationProvider =
    Provider.of<LocationProvider>(context, listen: false);
    await locationProvider.getCurrentLocation();

    if (_mapController != null && locationProvider.currentLocation != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(
          locationProvider.currentLocation!,
          17.0,
        ),
      );
    }
  }

  Future<void> _fetchNearbyRideRequests() async {
    setState(() {
      _isLoading = true;
    });

    try {
      print('Driver screen: Fetching nearby ride requests...');
      final rideProvider = Provider.of<RideProvider>(context, listen: false);

      // Print current status
      print('Driver online: $_isDriverOnline');

      final requests = await rideProvider.getNearbyRideRequests();

      _lastRefreshTime = DateTime.now();
      print('Driver screen: Received ${requests.length} ride requests');

      // Debug log each request
      for (var request in requests) {
        print('Ride ID: ${request.id}');
        print('  From: ${request.pickup}');
        print('  To: ${request.destination}');
        print('  Status: ${request.status}');
      }

      setState(() {
        _nearbyRideRequests = requests;
        _isLoading = false;
      });

      // Show a message if requests were found
      if (requests.isNotEmpty && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Found ${requests.length} ride requests'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Driver screen: Error fetching nearby ride requests: $e');
      print('Driver screen: Stack trace: ${StackTrace.current}');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load ride requests: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }

      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;

    final currentLocation =
        Provider.of<LocationProvider>(context, listen: false).currentLocation;
    if (currentLocation != null) {
      controller.animateCamera(
        CameraUpdate.newLatLngZoom(
          currentLocation,
          17.0,
        ),
      );
    }
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
                      value: _isDriverOnline,
                      onChanged: (value) {
                        setState(() {
                          _isDriverOnline = value;
                        });

                        final locationProvider = Provider.of<LocationProvider>(
                            context,
                            listen: false);

                        // If driver went online, start location tracking and refresh
                        if (value) {
                          locationProvider.startLocationUpdates();
                          _getCurrentLocation();
                          _fetchNearbyRideRequests();
                        } else {
                          // If driver went offline, stop location tracking
                          locationProvider.stopLocationUpdates();
                        }
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
            child: Column(
              children: [
                FloatingActionButton(
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
                const SizedBox(height: 12),
                FloatingActionButton(
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                  heroTag: 'refreshBtn',
                  onPressed: () {
                    _fetchNearbyRideRequests();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Refreshing nearby ride requests...'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                  child: const Icon(
                    Icons.refresh,
                    color: Colors.white,
                  ),
                ),
              ],
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
                height: MediaQuery.of(context).size.height * 0.6,
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
                            const SizedBox(height: 8),
                            Text(
                              _lastRefreshTime != null
                                  ? 'Last refreshed: ${_lastRefreshTime!.hour.toString().padLeft(2, '0')}:${_lastRefreshTime!.minute.toString().padLeft(2, '0')}'
                                  : '',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Only showing rides from the last 10 minutes',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                  fontStyle: FontStyle.italic),
                              textAlign: TextAlign.center,
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
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
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
                                      Expanded(
                                        child: Text(
                                          'Distance: ${ride.distance}',
                                          overflow:
                                          TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(Icons.timer,
                                          size: 16,
                                          color: Colors.grey[400]),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          'Est. Time: ${ride.estimatedTime}',
                                          overflow:
                                          TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(Icons.currency_rupee,
                                          size: 16,
                                          color: Colors.grey[400]),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          'Est. Fare: ₹${ride.fare}',
                                          overflow:
                                          TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              trailing: SizedBox(
                                width: 80,
                                child: ElevatedButton(
                                  onPressed: () =>
                                      _showBidForm(ride.id),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Theme.of(context)
                                        .colorScheme
                                        .secondary,
                                    foregroundColor: Colors.white,
                                    padding:
                                    const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 10),
                                  ),
                                  child: const Text('Place Bid'),
                                ),
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
                height: 240,
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
                child: SingleChildScrollView(
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
                                final amount = double.tryParse(
                                    _bidAmountController.text) ??
                                    0;
                                if (amount > 0) {
                                  // Get the driver ID from authentication
                                  // For now, we'll use a placeholder
                                  final driverId = "driver_123";

                                  try {
                                    // Use an instance method to store the current ride ID
                                    final rideProvider =
                                    Provider.of<RideProvider>(context,
                                        listen: false);

                                    // Set the current ride ID before placing a bid
                                    if (_selectedRideId != null) {
                                      rideProvider
                                          .setCurrentRideId(_selectedRideId!);
                                    }

                                    rideProvider.placeBid(
                                      driverId,
                                      amount,
                                    );

                                    // Show success message
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                            'Bid of ₹${amount.toStringAsFixed(2)} placed successfully!'),
                                        backgroundColor: Colors.green,
                                      ),
                                    );

                                    setState(() {
                                      _showBidPanel = false;
                                      _bidAmountController.clear();
                                    });
                                  } catch (e) {
                                    // Show error message
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                            'Error placing bid: ${e.toString()}'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
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
                ),
              ).animate().fade().slideY(begin: 1.0),
            ),
        ],
      ),
    );
  }
}