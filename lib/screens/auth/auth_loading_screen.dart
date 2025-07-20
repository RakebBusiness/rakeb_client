import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';

class AuthLoadingScreen extends StatefulWidget {
  const AuthLoadingScreen({super.key});

  @override
  State<AuthLoadingScreen> createState() => _AuthLoadingScreenState();
}

class _AuthLoadingScreenState extends State<AuthLoadingScreen> {
  @override
  void initState() {
    super.initState();
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    // Give the auth service time to initialize
    await Future.delayed(const Duration(milliseconds: 1000));
    
    if (mounted) {
      final authService = Provider.of<AuthService>(context, listen: false);
      
      // Wait for auth service to be fully initialized
      while (!authService.isInitialized) {
        await Future.delayed(const Duration(milliseconds: 100));
        if (!mounted) return;
      }
      
      // Check if user is already authenticated
      if (authService.isAuthenticated) {
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        Navigator.pushReplacementNamed(context, '/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF32C156),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App Logo/Icon
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(60),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(
                Icons.pedal_bike,
                size: 60,
                color: Color(0xFF32C156),
              ),
            ),
            const SizedBox(height: 30),
            
            // App Name
            const Text(
              'Rakib',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 10),
            
            // Tagline
            const Text(
              'Your Ride, Your Way',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white,
                fontWeight: FontWeight.w300,
              ),
            ),
            const SizedBox(height: 50),
            
            // Loading Indicator
            const SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 20),
            
            // Loading Text
            const Text(
              'Initializing...',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white,
                fontWeight: FontWeight.w300,
              ),
            ),
          ],
        ),
      ),
    );
  }
}