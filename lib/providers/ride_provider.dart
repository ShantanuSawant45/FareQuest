import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RideProvider with ChangeNotifier {
  List<Bid> _currentBids = [];
  Bid? _selectedBid;
  RideStatus _rideStatus = RideStatus.none;
  String? _currentRideId;

  List<Bid> get currentBids => _currentBids;
  Bid? get selectedBid => _selectedBid;
  RideStatus get rideStatus => _rideStatus;
  String? get currentRideId => _currentRideId;

  // Reference to the rides collection in Firestore
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  CollectionReference get _ridesCollection => _firestore.collection('rides');

  // Listen to bid updates for the current ride
  void listenForBids(String rideId) {
    _ridesCollection
        .doc(rideId)
        .collection('bids')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen((snapshot) {
      _currentBids = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Bid(
          id: doc.id,
          driverId: data['driverId'],
          amount: data['amount'],
          timestamp: (data['timestamp'] as Timestamp).toDate(),
          driverName: data['driverName'] ?? 'Unknown Driver',
          driverRating: data['driverRating'] ?? 0.0,
        );
      }).toList();
      notifyListeners();
    });
  }

  Future<void> requestRide(
      String userId, Map<String, dynamic> rideDetails) async {
    try {
      // Add timestamp and status to ride details
      final rideData = {
        ...rideDetails,
        'userId': userId,
        'status': RideStatus.waiting.toString(),
        'timestamp': FieldValue.serverTimestamp(),
      };

      // Add the ride to Firestore
      final docRef = await _ridesCollection.add(rideData);
      _currentRideId = docRef.id;
      _rideStatus = RideStatus.waiting;

      // Start listening for bids on this ride
      listenForBids(docRef.id);

      notifyListeners();
    } catch (e) {
      print('Error requesting ride: $e');
      rethrow;
    }
  }

  Future<void> placeBid(String driverId, double amount) async {
    if (_currentRideId == null) return;

    try {
      // Create a new bid document in the "bids" subcollection
      await _ridesCollection.doc(_currentRideId).collection('bids').add({
        'driverId': driverId,
        'amount': amount,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'pending',
        // You can add more driver details here
        'driverName': 'Driver Name', // Replace with actual driver name
        'driverRating': 4.5, // Replace with actual driver rating
      });

      // Update the ride status to bidding
      await _ridesCollection.doc(_currentRideId).update({
        'status': RideStatus.bidding.toString(),
      });

      _rideStatus = RideStatus.bidding;
      notifyListeners();
    } catch (e) {
      print('Error placing bid: $e');
      rethrow;
    }
  }

  Future<void> selectBid(Bid bid) async {
    if (_currentRideId == null) return;

    try {
      // Update the selected bid status
      await _ridesCollection
          .doc(_currentRideId)
          .collection('bids')
          .doc(bid.id)
          .update({'status': 'accepted'});

      // Update the ride with selected driver and status
      await _ridesCollection.doc(_currentRideId).update({
        'status': RideStatus.confirmed.toString(),
        'selectedDriverId': bid.driverId,
        'acceptedBidAmount': bid.amount,
        'acceptedAt': FieldValue.serverTimestamp(),
      });

      _selectedBid = bid;
      _rideStatus = RideStatus.confirmed;
      notifyListeners();
    } catch (e) {
      print('Error selecting bid: $e');
      rethrow;
    }
  }

  // Method to get nearby ride requests for drivers
  Future<List<RideRequest>> getNearbyRideRequests() async {
    try {
      final snapshot = await _ridesCollection
          .where('status', isEqualTo: RideStatus.waiting.toString())
          .orderBy('timestamp', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return RideRequest(
          id: doc.id,
          userId: data['userId'],
          pickup: data['pickup'],
          destination: data['destination'],
          fare: data['fare'],
          distance: data['distance'],
          estimatedTime: data['estimatedTime'],
          status: data['status'],
          timestamp: (data['timestamp'] as Timestamp).toDate(),
        );
      }).toList();
    } catch (e) {
      print('Error getting nearby ride requests: $e');
      return [];
    }
  }

  // Method to get user's ride history
  Future<List<RideRequest>> getUserRideHistory(String userId) async {
    try {
      final snapshot = await _ridesCollection
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return RideRequest(
          id: doc.id,
          userId: data['userId'],
          pickup: data['pickup'],
          destination: data['destination'],
          fare: data['fare'],
          distance: data['distance'],
          estimatedTime: data['estimatedTime'],
          status: data['status'],
          timestamp: (data['timestamp'] as Timestamp).toDate(),
        );
      }).toList();
    } catch (e) {
      print('Error getting user ride history: $e');
      return [];
    }
  }
}

class Bid {
  final String id;
  final String driverId;
  final double amount;
  final DateTime timestamp;
  final String driverName;
  final double driverRating;

  Bid({
    required this.driverId,
    required this.amount,
    required this.timestamp,
    this.id = '',
    this.driverName = 'Unknown Driver',
    this.driverRating = 0.0,
  });
}

class RideRequest {
  final String id;
  final String userId;
  final String pickup;
  final String destination;
  final dynamic fare;
  final String distance;
  final String estimatedTime;
  final String status;
  final DateTime timestamp;

  RideRequest({
    required this.id,
    required this.userId,
    required this.pickup,
    required this.destination,
    required this.fare,
    required this.distance,
    required this.estimatedTime,
    required this.status,
    required this.timestamp,
  });
}

enum RideStatus {
  none,
  waiting,
  bidding,
  confirmed,
  inProgress,
  completed,
  cancelled
}
