import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:3000/api'; // Change this to your server URL
  
  String? _accessToken;
  
  // Set access token for authenticated requests
  void setAccessToken(String token) {
    _accessToken = token;
  }
  
  // Clear access token
  void clearAccessToken() {
    _accessToken = null;
  }
  
  // Get headers for requests
  Map<String, String> get _headers {
    final headers = {
      'Content-Type': 'application/json',
    };
    
    if (_accessToken != null) {
      headers['Authorization'] = 'Bearer $_accessToken';
    }
    
    return headers;
  }
  
  // Handle API response
  Map<String, dynamic> _handleResponse(http.Response response) {
    final data = json.decode(response.body);
    
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    } else {
      throw ApiException(
        data['error'] ?? 'Unknown error',
        statusCode: response.statusCode,
        details: data['details'],
      );
    }
  }
  
  // Authentication endpoints
  Future<Map<String, dynamic>> requestOTP(String phoneNumber) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/request-otp'),
      headers: _headers,
      body: json.encode({'phoneNumber': phoneNumber}),
    );
    
    return _handleResponse(response);
  }
  
  Future<Map<String, dynamic>> verifyOTP(String phoneNumber, String otpCode) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/verify-otp'),
      headers: _headers,
      body: json.encode({
        'phoneNumber': phoneNumber,
        'otpCode': otpCode,
      }),
    );
    
    final data = _handleResponse(response);
    
    // Set access token if verification successful
    if (data['session'] != null && data['session']['accessToken'] != null) {
      setAccessToken(data['session']['accessToken']);
    }
    
    return data;
  }
  
  Future<Map<String, dynamic>> updateProfile(String displayName) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/auth/profile'),
      headers: _headers,
      body: json.encode({'displayName': displayName}),
    );
    
    return _handleResponse(response);
  }
  
  Future<Map<String, dynamic>> getCurrentUser() async {
    final response = await http.get(
      Uri.parse('$baseUrl/auth/me'),
      headers: _headers,
    );
    
    return _handleResponse(response);
  }
  
  Future<Map<String, dynamic>> signOut() async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/signout'),
      headers: _headers,
    );
    
    clearAccessToken();
    return _handleResponse(response);
  }
  
  // Rider endpoints
  Future<Map<String, dynamic>> getNearbyRiders({
    required LatLng userLocation,
    double radius = 50.0,
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl/riders/nearby?latitude=${userLocation.latitude}&longitude=${userLocation.longitude}&radius=$radius'),
      headers: _headers,
    );
    
    return _handleResponse(response);
  }
  
  Future<Map<String, dynamic>> getRiderById(String riderId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/riders/$riderId'),
      headers: _headers,
    );
    
    return _handleResponse(response);
  }
  
  Future<Map<String, dynamic>> getRiderRatings(String riderId, {int limit = 10}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/riders/$riderId/ratings?limit=$limit'),
      headers: _headers,
    );
    
    return _handleResponse(response);
  }
  
  // Trip endpoints
  Future<Map<String, dynamic>> createTrip({
    required LatLng pickupLocation,
    required String pickupAddress,
    required LatLng destinationLocation,
    required String destinationAddress,
    String? riderId,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/trips'),
      headers: _headers,
      body: json.encode({
        'pickupLocation': {
          'latitude': pickupLocation.latitude,
          'longitude': pickupLocation.longitude,
        },
        'pickupAddress': pickupAddress,
        'destinationLocation': {
          'latitude': destinationLocation.latitude,
          'longitude': destinationLocation.longitude,
        },
        'destinationAddress': destinationAddress,
        if (riderId != null) 'riderId': riderId,
      }),
    );
    
    return _handleResponse(response);
  }
  
  Future<Map<String, dynamic>> getUserTrips({
    String? status,
    int limit = 50,
    int offset = 0,
  }) async {
    String url = '$baseUrl/trips?limit=$limit&offset=$offset';
    if (status != null) {
      url += '&status=$status';
    }
    
    final response = await http.get(
      Uri.parse(url),
      headers: _headers,
    );
    
    return _handleResponse(response);
  }
  
  Future<Map<String, dynamic>> getTripById(String tripId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/trips/$tripId'),
      headers: _headers,
    );
    
    return _handleResponse(response);
  }
  
  Future<Map<String, dynamic>> updateTripStatus(String tripId, String status) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/trips/$tripId/status'),
      headers: _headers,
      body: json.encode({'status': status}),
    );
    
    return _handleResponse(response);
  }
  
  Future<Map<String, dynamic>> cancelTrip(String tripId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/trips/$tripId'),
      headers: _headers,
    );
    
    return _handleResponse(response);
  }
  
  Future<Map<String, dynamic>> rateTrip(String tripId, int rating, {String? comment}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/trips/$tripId/rating'),
      headers: _headers,
      body: json.encode({
        'rating': rating,
        if (comment != null) 'comment': comment,
      }),
    );
    
    return _handleResponse(response);
  }
  
  // Location endpoints
  Future<Map<String, dynamic>> searchLocations(
    String query, {
    LatLng? userLocation,
  }) async {
    String url = '$baseUrl/location/search?query=${Uri.encodeComponent(query)}';
    if (userLocation != null) {
      url += '&latitude=${userLocation.latitude}&longitude=${userLocation.longitude}';
    }
    
    final response = await http.get(
      Uri.parse(url),
      headers: _headers,
    );
    
    return _handleResponse(response);
  }
  
  Future<Map<String, dynamic>> reverseGeocode(LatLng location) async {
    final response = await http.get(
      Uri.parse('$baseUrl/location/reverse?latitude=${location.latitude}&longitude=${location.longitude}'),
      headers: _headers,
    );
    
    return _handleResponse(response);
  }
  
  Future<Map<String, dynamic>> getPlaceDetails(String placeId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/location/place/$placeId'),
      headers: _headers,
    );
    
    return _handleResponse(response);
  }
  
  Future<Map<String, dynamic>> calculateRoute({
    required LatLng origin,
    required LatLng destination,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/location/route'),
      headers: _headers,
      body: json.encode({
        'origin': {
          'latitude': origin.latitude,
          'longitude': origin.longitude,
        },
        'destination': {
          'latitude': destination.latitude,
          'longitude': destination.longitude,
        },
      }),
    );
    
    return _handleResponse(response);
  }
  
  // Promotion endpoints
  Future<Map<String, dynamic>> getPromotions() async {
    final response = await http.get(
      Uri.parse('$baseUrl/promotions'),
      headers: _headers,
    );
    
    return _handleResponse(response);
  }
  
  Future<Map<String, dynamic>> getPromotionById(String promotionId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/promotions/$promotionId'),
      headers: _headers,
    );
    
    return _handleResponse(response);
  }
  
  Future<Map<String, dynamic>> checkPromotionEligibility(String promotionId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/promotions/$promotionId/eligibility'),
      headers: _headers,
    );
    
    return _handleResponse(response);
  }
  
  Future<Map<String, dynamic>> applyPromotion(String promotionId, int tripPrice) async {
    final response = await http.post(
      Uri.parse('$baseUrl/promotions/$promotionId/apply'),
      headers: _headers,
      body: json.encode({'tripPrice': tripPrice}),
    );
    
    return _handleResponse(response);
  }
}

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic details;
  
  ApiException(this.message, {this.statusCode, this.details});
  
  @override
  String toString() => 'ApiException: $message';
}