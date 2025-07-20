import 'package:flutter/material.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/signup_screen.dart';
import '../screens/otp/otp_screen.dart';
import '../screens/auth/username_screen.dart';
import '../screens/home/home_screen.dart';

final Map<String, WidgetBuilder> appRoutes = {
  // '/': (context) => const AuthLoadingScreen(), // Removed or commented out
  '/login': (context) => const LoginScreen(),
  '/signup': (context) => const SignupScreen(),
  '/otp': (context) => const OtpScreen(),
  '/username': (context) => const UsernameScreen(),
  '/home': (context) => const HomeScreen(), // Now the initial route
};