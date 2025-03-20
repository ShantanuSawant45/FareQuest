import 'package:flutter/foundation.dart';

class RideProvider with ChangeNotifier {
  List<Bid> _currentBids = [];
  Bid? _selectedBid;
  RideStatus _rideStatus = RideStatus.none;

  List<Bid> get currentBids => _currentBids;
  Bid? get selectedBid => _selectedBid;
  RideStatus get rideStatus => _rideStatus;

  Future<void> requestRide(
      String userId, Map<String, dynamic> rideDetails) async {
    // TODO: Implement Firebase Firestore
    // Create new ride request in Firestore
    try {
      _rideStatus = RideStatus.waiting;
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> placeBid(String driverId, double amount) async {
    // TODO: Implement Firebase Firestore
    // Add bid to current ride request
    try {
      final newBid = Bid(
        driverId: driverId,
        amount: amount,
        timestamp: DateTime.now(),
      );
      _currentBids.add(newBid);
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  void selectBid(Bid bid) {
    _selectedBid = bid;
    _rideStatus = RideStatus.confirmed;
    notifyListeners();
  }
}

class Bid {
  final String driverId;
  final double amount;
  final DateTime timestamp;

  Bid({
    required this.driverId,
    required this.amount,
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



