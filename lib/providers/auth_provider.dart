import 'package:flutter/foundation.dart';

class AuthProvider with ChangeNotifier {
  bool _isAuthenticated = false;
  String? _userId;
  bool _isDriver = false;

  bool get isAuthenticated => _isAuthenticated;
  String? get userId => _userId;
  bool get isDriver => _isDriver;

  Future<void> signIn(String email, String password) async {
    // TODO: Implement Firebase Authentication
    // Try to sign in user with Firebase
    try {
      // FirebaseAuth.instance.signInWithEmailAndPassword...
      _isAuthenticated = true;
      _userId = "dummy_user_id";
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signUp(String email, String password, bool isDriver) async {
    // TODO: Implement Firebase Authentication
    // Create new user with Firebase
    try {
      // FirebaseAuth.instance.createUserWithEmailAndPassword...
      _isAuthenticated = true;
      _userId = "dummy_user_id";
      _isDriver = isDriver;
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  void signOut() {
    // TODO: Implement Firebase sign out
    _isAuthenticated = false;
    _userId = null;
    _isDriver = false;
    notifyListeners();
  }
}
