import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/auth_state.dart';

class AuthService extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  AppAuthState _state = const AppAuthState();
  bool _isInitialized = false;

  AppAuthState get state => _state;
  User? get currentUser => _supabase.auth.currentUser;
  bool get isAuthenticated => currentUser != null;
  bool get isInitialized => _isInitialized;

  AuthService() {
    _initialize();
  }

  Future<void> _initialize() async {
    _supabase.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      final Session? session = data.session;
      
      if (event == AuthChangeEvent.signedIn && session != null) {
        _updateState(_state.copyWith(
          status: AppAuthStatus.authenticated,
          userId: session.user.id,
        ));
      } else if (event == AuthChangeEvent.signedOut) {
        _updateState(_state.copyWith(status: AppAuthStatus.unauthenticated));
      }
    });
    
    // Check initial auth state
    await _checkInitialAuthState();
    _isInitialized = true;
    notifyListeners();
  }

  Future<void> _checkInitialAuthState() async {
    try {
      // Add a small delay to ensure Supabase is fully initialized
      await Future.delayed(const Duration(milliseconds: 100));
      
      final session = _supabase.auth.currentSession;
      if (session != null) {
        _updateState(_state.copyWith(
          status: AppAuthStatus.authenticated,
          userId: session.user.id,
        ));
      } else {
        _updateState(_state.copyWith(status: AppAuthStatus.unauthenticated));
      }
    } catch (e) {
      print('Error checking initial auth state: $e');
      _updateState(_state.copyWith(status: AppAuthStatus.unauthenticated));
    }
  }

  void _updateState(AppAuthState newState) {
    _state = newState;
    notifyListeners();
  }

  Future<void> requestOTP(String phoneNumber) async {
    try {
      _updateState(_state.copyWith(status: AppAuthStatus.loading));

      // Format phone number properly for Algeria (+213)
      String formattedPhone = phoneNumber;
      
      // Clean the phone number first (remove spaces, dashes, etc.)
      String cleanPhone = phoneNumber.replaceAll(RegExp(r'[\s\-\(\)]'), '');
      
      // Format for Algeria (+213)
      if (cleanPhone.startsWith('+213')) {
        // Already has country code, just clean it
        formattedPhone = cleanPhone;
      } else if (cleanPhone.startsWith('213')) {
        // Has country code without +
        formattedPhone = '+$cleanPhone';
      } else if (cleanPhone.startsWith('0')) {
        // Local format: 0512345678 -> +213512345678
        formattedPhone = '+213${cleanPhone.substring(1)}';
      } else if (cleanPhone.length == 9 && (cleanPhone.startsWith('5') || cleanPhone.startsWith('6') || cleanPhone.startsWith('7'))) {
        // Already without leading 0: 512345678 -> +213512345678
        formattedPhone = '+213$cleanPhone';
      } else {
        // Default case - assume it needs +213
        formattedPhone = '+213$cleanPhone';
      }
      
      // Validate the final format
      if (!RegExp(r'^\+213[567]\d{8}$').hasMatch(formattedPhone)) {
        _updateState(_state.copyWith(
          status: AppAuthStatus.error,
          error: 'Format de numéro invalide. Utilisez: 05XXXXXXXX, 06XXXXXXXX ou 07XXXXXXXX',
        ));
        return;
      }

      print('Attempting to send OTP to: $formattedPhone');

      await _supabase.auth.signInWithOtp(
        phone: formattedPhone,
      );

      _updateState(_state.copyWith(
        status: AppAuthStatus.codeSent,
        phoneNumber: formattedPhone,
      ));

      print('OTP sent successfully');
    } catch (e) {
      print('Request OTP error: ${e.toString()}');
      _updateState(_state.copyWith(
        status: AppAuthStatus.error,
        error: _getErrorMessage(e),
      ));
    }
  }

  Future<void> verifyOTP(String smsCode) async {
    try {
      _updateState(_state.copyWith(status: AppAuthStatus.loading));

      if (_state.phoneNumber == null) {
        _updateState(_state.copyWith(
          status: AppAuthStatus.error,
          error: 'Numéro de téléphone manquant',
        ));
        return;
      }

      final AuthResponse response = await _supabase.auth.verifyOTP(
        type: OtpType.sms,
        token: smsCode,
        phone: _state.phoneNumber!,
      );

      if (response.user != null) {
        _updateState(_state.copyWith(
          status: AppAuthStatus.verified,
          userId: response.user!.id,
        ));
      } else {
        _updateState(_state.copyWith(
          status: AppAuthStatus.error,
          error: 'Échec de la vérification',
        ));
      }
    } catch (e) {
      print('Verify OTP error: ${e.toString()}');
      _updateState(_state.copyWith(
        status: AppAuthStatus.error,
        error: _getErrorMessage(e),
      ));
    }
  }

  Future<void> updateUserProfile(String displayName) async {
    try {
      await _supabase.auth.updateUser(
        UserAttributes(
          data: {'display_name': displayName},
        ),
      );
    } catch (e) {
      print('Update profile error: ${e.toString()}');
      throw Exception('Erreur lors de la mise à jour du profil');
    }
  }

  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
      _updateState(const AppAuthState(status: AppAuthStatus.unauthenticated));
    } catch (e) {
      _updateState(_state.copyWith(
        status: AppAuthStatus.error,
        error: 'Erreur de déconnexion: ${e.toString()}',
      ));
    }
  }

  void clearError() {
    _updateState(_state.copyWith(error: null));
  }

  String _getErrorMessage(dynamic error) {
    if (error is AuthException) {
      switch (error.message.toLowerCase()) {
        case 'invalid phone number':
          return 'Le numéro de téléphone est invalide';
        case 'too many requests':
          return 'Trop de tentatives. Réessayez plus tard';
        case 'invalid otp':
        case 'token has expired':
          return 'Code de vérification invalide ou expiré';
        case 'phone not confirmed':
          return 'Numéro de téléphone non confirmé';
        default:
          return 'Erreur d\'authentification: ${error.message}';
      }
    }
    
    return 'Une erreur est survenue: ${error.toString()}';
  }
}