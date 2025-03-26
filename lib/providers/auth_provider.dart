import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:se_project/screens/home/user_home_screen.dart';

class AuthProvider with ChangeNotifier {
  bool _isAuthenticated = false;
  String? _userId;
  bool _isDriver = false;
  final FirebaseAuth _auth=FirebaseAuth.instance;

  bool get isAuthenticated => _isAuthenticated;
  String? get userId => _userId;
  bool get isDriver => _isDriver;

  Future<void> signUp(String email, String password, BuildContext context) async {
    try {
      final UserCredential userCredential =
      await _auth.createUserWithEmailAndPassword(email: email, password: password);

      final User? user = userCredential.user;
      if (user != null) {
        _isAuthenticated = true;
        _userId = user.uid; // Store actual user ID
        notifyListeners();

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => UserHomeScreen()),
        );
      }
    } catch (e) {
      throw Exception("Signup failed: ${e.toString()}");
    }
  }

  Future<void> signIn(String email, String password, BuildContext context) async {
    try {
      final UserCredential userCredential =
      await _auth.signInWithEmailAndPassword(email: email, password: password);

      final User? user = userCredential.user;
      if (user != null) {
        _isAuthenticated = true;
        _userId = user.uid; // Store actual user ID
        notifyListeners();

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => UserHomeScreen()),
        );
      }
    } catch (e) {
      throw Exception("Login failed: ${e.toString()}");
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
