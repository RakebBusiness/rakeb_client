import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'api_service.dart';

class RiderService {
  final ApiService _apiService = ApiService();

  // Get nearby riders within specified radius
  Future<List<RiderData>> getNearbyRiders({
    required LatLng userLocation,
    double radiusKm = 50.0,
  }) async {
    try {
      print('🔍 Fetching riders from API...');
      
      final response = await _apiService.getNearbyRiders(
        userLocation: userLocation,
        radius: radiusKm,
      );
      
      if (response['success'] == true && response['riders'] != null) {
        final ridersData = response['riders'] as List<dynamic>;
        final riders = ridersData.map((riderJson) => RiderData.fromJson(riderJson)).toList();
        
        print('✅ Found ${riders.length} riders within ${radiusKm}km');
        return riders;
      } else {
        print('⚠️ No riders found');
        return [];
      }
    } on ApiException catch (e) {
      print('❌ API error fetching riders: ${e.message}');
      return [];
    } catch (e) {
      print('❌ Error fetching nearby riders: $e');
      return [];
    }
  }

  // Get rider details by ID
  Future<RiderData?> getRiderById(String riderId) async {
    try {
      final response = await _apiService.getRiderById(riderId);
      
      if (response['success'] == true && response['rider'] != null) {
        return RiderData.fromJson(response['rider']);
      }
      return null;
    } on ApiException catch (e) {
      print('API error fetching rider details: ${e.message}');
      return null;
    } catch (e) {
      print('Error fetching rider details: $e');
      return null;
    }
  }

  // Update rider location (for testing purposes)
  Future<void> updateRiderLocation(String riderId, LatLng newLocation) async {
    try {
      // This would typically be an admin function
      // For now, we'll just log it
      print('Update rider location: $riderId to ${newLocation.latitude}, ${newLocation.longitude}');
    } on ApiException catch (e) {
      print('API error updating rider location: ${e.message}');
      throw Exception(e.message);
    } catch (e) {
      print('Error updating rider location: $e');
      throw Exception('Failed to update rider location');
    }
  }
}

class RiderData {
  final String id;
  final String nomComplet;
  final String numTel;
  final double ratingAverage;
  final LatLng currentLocation;
  final double distanceKm;
  final String status;

  RiderData({
    required this.id,
    required this.nomComplet,
    required this.numTel,
    required this.ratingAverage,
    required this.currentLocation,
    required this.distanceKm,
    required this.status,
  });

  factory RiderData.fromJson(Map<String, dynamic> json) {
    final locationData = json['currentLocation'] ?? {};
    final location = LatLng(
      locationData['latitude']?.toDouble() ?? 36.5644,
      locationData['longitude']?.toDouble() ?? 3.5892,
    );

    return RiderData(
      id: json['id'] ?? '',
      nomComplet: json['nom_complet'] ?? 'Unknown Rider',
      numTel: json['num_tel'] ?? '',
      ratingAverage: (json['rating_average'] ?? 0.0).toDouble(),
      currentLocation: location,
      distanceKm: (json['distanceKm'] ?? 0.0).toDouble(),
      status: json['status'] ?? 'offline',
    );
  }
}