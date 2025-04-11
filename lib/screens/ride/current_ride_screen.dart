import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:se_project/providers/location_provider.dart';
import 'package:se_project/providers/ride_provider.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:flutter_animate/flutter_animate.dart';

class CurrentRideScreen extends StatefulWidget {
  final String rideId;
  final Bid acceptedBid;

  const CurrentRideScreen({
    super.key,
    required this.rideId,
    required this.acceptedBid,
  });

  @override
  State<CurrentRideScreen> createState() => _CurrentRideScreenState();
}

class _CurrentRideScreenState extends State<CurrentRideScreen> {
  GoogleMapController? _mapController;
  RideRequest? _currentRide;
  bool _isLoading = true;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};

  @override
  void initState() {
    super.initState();
    _loadRideDetails();
  }

  Future<void> _loadRideDetails() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load ride details from Firestore
      final rideProvider = Provider.of<RideProvider>(context, listen: false);
      final ride = await rideProvider.getRideById(widget.rideId);

      setState(() {
        _currentRide = ride;
        _isLoading = false;
      });

      // Setup map markers and route
      _setupMapMarkers();
    } catch (e) {
      print('Error loading ride details: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading ride details: $e')),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _setupMapMarkers() {
    if (_currentRide == null) return;

    // For now we're using dummy coordinates until we implement geocoding
    // In a real app, convert pickup and destination addresses to coordinates
    final pickup =
        const LatLng(28.6304, 77.2177); // Delhi coordinates as example
    final destination =
        const LatLng(28.4595, 77.0266); // Gurgaon coordinates as example

    // Add pickup marker
    _markers.add(
      Marker(
        markerId: const MarkerId('pickup'),
        position: pickup,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: InfoWindow(title: 'Pickup: ${_currentRide!.pickup}'),
      ),
    );

    // Add destination marker
    _markers.add(
      Marker(
        markerId: const MarkerId('destination'),
        position: destination,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow:
            InfoWindow(title: 'Destination: ${_currentRide!.destination}'),
      ),
    );

    // Add driver marker (simulated position between pickup and destination)
    final driverLat = (pickup.latitude + destination.latitude) / 2;
    final driverLng = (pickup.longitude + destination.longitude) / 2;
    _markers.add(
      Marker(
        markerId: const MarkerId('driver'),
        position: LatLng(driverLat, driverLng),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
        infoWindow: const InfoWindow(title: 'Driver Location'),
      ),
    );

    // Add polyline for route
    _polylines.add(
      Polyline(
        polylineId: const PolylineId('route'),
        color: Colors.blue,
        width: 5,
        points: [pickup, LatLng(driverLat, driverLng), destination],
      ),
    );

    // Move camera to show all markers
    if (_mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngBounds(
          LatLngBounds(
            southwest: LatLng(
              pickup.latitude < destination.latitude
                  ? pickup.latitude
                  : destination.latitude,
              pickup.longitude < destination.longitude
                  ? pickup.longitude
                  : destination.longitude,
            ),
            northeast: LatLng(
              pickup.latitude > destination.latitude
                  ? pickup.latitude
                  : destination.latitude,
              pickup.longitude > destination.longitude
                  ? pickup.longitude
                  : destination.longitude,
            ),
          ),
          100, // padding
        ),
      );
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    _setupMapMarkers();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                // Map showing the ride
                GoogleMap(
                  onMapCreated: _onMapCreated,
                  initialCameraPosition: const CameraPosition(
                    target:
                        LatLng(28.6139, 77.2090), // Delhi center coordinates
                    zoom: 12,
                  ),
                  markers: _markers,
                  polylines: _polylines,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  mapToolbarEnabled: false,
                  zoomControlsEnabled: false,
                  compassEnabled: false,
                ),

                // Back button
                Positioned(
                  top: MediaQuery.of(context).padding.top + 16,
                  left: 16,
                  child: GlassmorphicContainer(
                    width: 50,
                    height: 50,
                    borderRadius: 25,
                    blur: 20,
                    alignment: Alignment.center,
                    border: 2,
                    linearGradient: LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0.2),
                        Colors.white.withOpacity(0.1),
                      ],
                    ),
                    borderGradient: LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0.2),
                        Colors.white.withOpacity(0.1),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ).animate().fade().scale(),
                ),

                // Ride info panel at the bottom
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: GlassmorphicContainer(
                    width: double.infinity,
                    height: MediaQuery.of(context).size.height * 0.4,
                    borderRadius: 24,
                    blur: 20,
                    alignment: Alignment.bottomCenter,
                    border: 2,
                    linearGradient: LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0.2),
                        Colors.white.withOpacity(0.1),
                      ],
                    ),
                    borderGradient: LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.primary.withOpacity(0.5),
                        Theme.of(context)
                            .colorScheme
                            .secondary
                            .withOpacity(0.5),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Drag handle
                        Container(
                          margin: const EdgeInsets.only(top: 8),
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),

                        // Ride status
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20),
                                  border:
                                      Border.all(color: Colors.green, width: 1),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.directions_car,
                                        color: Colors.green, size: 16),
                                    const SizedBox(width: 4),
                                    Text(
                                      'On the way',
                                      style: TextStyle(
                                        color: Colors.green,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Spacer(),
                              Text(
                                'ETA: ${_currentRide?.estimatedTime ?? '15 mins'}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Driver info
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 30,
                                  backgroundColor:
                                      Theme.of(context).colorScheme.primary,
                                  child: const Icon(Icons.person,
                                      size: 36, color: Colors.white),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        widget.acceptedBid.driverName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Row(
                                        children: [
                                          Icon(Icons.star,
                                              color: Colors.amber, size: 16),
                                          Text(
                                            ' ${widget.acceptedBid.driverRating} · Driver ID: ${widget.acceptedBid.driverId.substring(0, 6)}',
                                            style: TextStyle(
                                                color: Colors.white70),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    // Implement call functionality
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text('Calling driver...')),
                                    );
                                  },
                                  icon: const Icon(Icons.phone),
                                  label: const Text('Call'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Ride details
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    const CircleAvatar(
                                      radius: 8,
                                      backgroundColor: Colors.green,
                                      child: Icon(Icons.trip_origin,
                                          color: Colors.white, size: 10),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        _currentRide?.pickup ??
                                            'Loading pickup...',
                                        style: const TextStyle(
                                            color: Colors.white),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const Padding(
                                  padding: EdgeInsets.only(left: 8),
                                  child: SizedBox(
                                    height: 24,
                                    child: VerticalDivider(
                                      width: 1,
                                      thickness: 1,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 8,
                                      backgroundColor: Colors.red.shade800,
                                      child: const Icon(Icons.location_on,
                                          color: Colors.white, size: 10),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        _currentRide?.destination ??
                                            'Loading destination...',
                                        style: const TextStyle(
                                            color: Colors.white),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Ride payment info
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Payment',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '₹${widget.acceptedBid.amount.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20,
                                    ),
                                  ),
                                ],
                              ),
                              ElevatedButton.icon(
                                onPressed: () {
                                  // Implement cancel ride functionality
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Cancel Ride?'),
                                      content: const Text(
                                          'Do you want to cancel this ride? Cancellation charges may apply.'),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context),
                                          child: const Text('NO'),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            Navigator.pop(
                                                context); // Close dialog
                                            Navigator.pop(
                                                context); // Go back to previous screen
                                          },
                                          child: const Text('YES'),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.cancel_outlined),
                                label: const Text('Cancel Ride'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ).animate().fade().slideY(begin: 0.2),
                ),
              ],
            ),
    );
  }
}
