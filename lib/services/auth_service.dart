import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'api_service.dart';
import '../models/auth_state.dart';

class AuthService extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  AppAuthState _state = const AppAuthState();
  bool _isInitialized = false;
  Map<String, dynamic>? _currentUser;

  AppAuthState get state => _state;
  Map<String, dynamic>? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isInitialized => _isInitialized;

  AuthService() {
    _initialize();
  }

  Future<void> _initialize() async {
    // Check if user is already authenticated (e.g., from stored token)
    // This would typically involve checking stored credentials
    _updateState(_state.copyWith(status: AppAuthStatus.unauthenticated));
    _isInitialized = true;
    notifyListeners();
  }

  void _updateState(AppAuthState newState) {
    _state = newState;
    notifyListeners();
  }

  Future<void> requestOTP(String phoneNumber) async {
    try {
      _updateState(_state.copyWith(status: AppAuthStatus.loading));

      final response = await _apiService.requestOTP(phoneNumber);
      
      if (response['success'] == true) {
        _updateState(_state.copyWith(
          status: AppAuthStatus.codeSent,
          phoneNumber: response['phoneNumber'],
        ));
        print('OTP sent successfully');
      } else {
        _updateState(_state.copyWith(
          status: AppAuthStatus.error,
          error: response['message'] ?? 'Failed to send OTP',
        ));
      }
    } on ApiException catch (e) {
      print('Request OTP API error: ${e.toString()}');

      _updateState(_state.copyWith(
        status: AppAuthStatus.error,
        error: e.message,
      ));
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

      final response = await _apiService.verifyOTP(_state.phoneNumber!, smsCode);
      
      if (response['success'] == true && response['user'] != null) {
        _currentUser = response['user'];
        _updateState(_state.copyWith(
          status: AppAuthStatus.verified,
          userId: response['user']['id'],
        ));
      } else {
        _updateState(_state.copyWith(
          status: AppAuthStatus.error,
          error: response['message'] ?? 'Échec de la vérification',
        ));
      }
    } on ApiException catch (e) {
      print('Verify OTP API error: ${e.toString()}');
      _updateState(_state.copyWith(
        status: AppAuthStatus.error,
        error: e.message,
      ));
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
      final response = await _apiService.updateProfile(displayName);
      
      if (response['success'] == true && response['user'] != null) {
        _currentUser = response['user'];
        notifyListeners();
      } else {
        throw Exception(response['message'] ?? 'Failed to update profile');
      }
    } on ApiException catch (e) {
      print('Update profile API error: ${e.toString()}');
      throw Exception(e.message);
    } catch (e) {
      print('Update profile error: ${e.toString()}');
      throw Exception('Erreur lors de la mise à jour du profil');
    }
  }

  Future<void> signOut() async {
    try {
      await _apiService.signOut();
      _currentUser = null;
      _updateState(const AppAuthState(status: AppAuthStatus.unauthenticated));
    } on ApiException catch (e) {
      print('Sign out API error: ${e.toString()}');
      // Even if API call fails, clear local state
      _currentUser = null;
      _updateState(const AppAuthState(status: AppAuthStatus.unauthenticated));
    } catch (e) {
      print('Sign out error: ${e.toString()}');
      // Clear local state even on error
      _currentUser = null;
      _updateState(_state.copyWith(
        status: AppAuthStatus.unauthenticated,
      ));
    }
  }

  void clearError() {
    _updateState(_state.copyWith(error: null));
  }

}