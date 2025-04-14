import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:se_project/providers/auth_provider.dart';
import 'package:se_project/screens/auth/onbording_page.dart';

import 'auth/AskuthPage.dart';
import 'auth/login_screen.dart';
import 'home/user_home_screen.dart';


class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;// agar widgit distroy huwa hoga to return kar doo

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.isAuthenticated) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const UserHomeScreen()),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const OnboardingScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.electric_car,
              size: 100,
              color: Theme.of(context).colorScheme.primary,
            )
                .animate()
                .fade(duration: const Duration(milliseconds: 500))
                .scale(delay: const Duration(milliseconds: 300)),
            const SizedBox(height: 20),
            Text(
              'Neo Rides',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
            )
                .animate()
                .fade(delay: const Duration(milliseconds: 300))
                .slideY(begin: 0.2),
          ],
        ),
      ),
    );
  }
}
