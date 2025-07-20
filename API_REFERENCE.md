# Rakib App - API Reference

## Overview

This document provides detailed API reference for the Rakib ride-sharing application, including authentication, rider management, trip booking, and location services.

## Base Configuration

### Supabase Configuration
```dart
import 'package:supabase_flutter/supabase_flutter.dart';

await Supabase.initialize(
  url: 'https://hatscaabqgcrvrxxszco.supabase.co',
  anonKey: 'your-anon-key',
);

final supabase = Supabase.instance.client;
```

### Headers
All authenticated requests require:
```dart
{
  'Authorization': 'Bearer ${session.accessToken}',
  'Content-Type': 'application/json',
  'apikey': 'your-anon-key'
}
```

## Authentication API

### 1. Request OTP

Send OTP code to user's phone number.

**Method**: `POST`  
**Endpoint**: Supabase Auth  
**Function**: `signInWithOtp()`

```dart
Future<void> requestOTP(String phoneNumber) async {
  try {
    await supabase.auth.signInWithOtp(
      phone: phoneNumber, // Format: +213XXXXXXXXX
    );
  } catch (e) {
    throw AuthException(e.toString());
  }
}
```

**Parameters**:
- `phone` (string, required): Phone number in international format (+213XXXXXXXXX)

**Response**:
```dart
// Success: No return value, OTP sent via SMS
// Error: AuthException with error message
```

**Supported Phone Formats**:
- `+213512345678` (International format)
- `0512345678` (Local format with leading 0)
- `512345678` (Local format without leading 0)

**Error Codes**:
- `invalid_phone`: Invalid phone number format
- `too_many_requests`: Rate limit exceeded
- `sms_send_failed`: SMS delivery failed

### 2. Verify OTP

Verify the OTP code sent to user's phone.

**Method**: `POST`  
**Endpoint**: Supabase Auth  
**Function**: `verifyOTP()`

```dart
Future<AuthResponse> verifyOTP(String smsCode, String phoneNumber) async {
  try {
    final response = await supabase.auth.verifyOTP(
      type: OtpType.sms,
      token: smsCode,
      phone: phoneNumber,
    );
    return response;
  } catch (e) {
    throw AuthException(e.toString());
  }
}
```

**Parameters**:
- `token` (string, required): 6-digit OTP code
- `phone` (string, required): Phone number used for OTP request
- `type` (OtpType, required): Always `OtpType.sms`

**Response**:
```dart
AuthResponse {
  user: User?, // User object if verification successful
  session: Session?, // Session with access tokens
}
```

**Error Codes**:
- `invalid_otp`: Invalid or expired OTP code
- `token_expired`: OTP code has expired
- `too_many_attempts`: Too many failed verification attempts

### 3. Update User Profile

Update user profile information.

**Method**: `PATCH`  
**Endpoint**: Supabase Auth  
**Function**: `updateUser()`

```dart
Future<void> updateUserProfile(String displayName) async {
  try {
    await supabase.auth.updateUser(
      UserAttributes(
        data: {'display_name': displayName},
      ),
    );
  } catch (e) {
    throw Exception('Profile update failed');
  }
}
```

**Parameters**:
- `data` (Map, required): User metadata to update

**Response**:
```dart
// Success: User profile updated
// Error: Exception with error message
```

### 4. Sign Out

Sign out current user and invalidate session.

**Method**: `POST`  
**Endpoint**: Supabase Auth  
**Function**: `signOut()`

```dart
Future<void> signOut() async {
  try {
    await supabase.auth.signOut();
  } catch (e) {
    throw Exception('Sign out failed');
  }
}
```

**Response**:
```dart
// Success: User signed out, session invalidated
// Error: Exception with error message
```

## Rider Management API

### 1. Get Nearby Riders

Retrieve list of available riders within specified radius.

**Method**: `GET`  
**Endpoint**: `/rest/v1/motards`  
**Function**: `getNearbyRiders()`

```dart
Future<List<RiderData>> getNearbyRiders({
  required LatLng userLocation,
  double radiusKm = 50.0,
}) async {
  try {
    final response = await supabase
        .from('motards')
        .select('*')
        .eq('status', 'online')
        .limit(20);
    
    return _processRiderData(response, userLocation, radiusKm);
  } catch (e) {
    throw Exception('Failed to fetch riders');
  }
}
```

**Parameters**:
- `userLocation` (LatLng, required): User's current location
- `radiusKm` (double, optional): Search radius in kilometers (default: 50.0)

**Response**:
```dart
List<RiderData> [
  {
    id: "uuid",
    nomComplet: "Rider Name",
    numTel: "+213XXXXXXXXX",
    ratingAverage: 4.5,
    currentLocation: LatLng(36.7538, 3.0588),
    distanceKm: 2.3,
    status: "online"
  }
]
```

**Query Parameters**:
- `status` (string): Filter by rider status ('online', 'offline', 'busy')
- `limit` (integer): Maximum number of results (default: 20)

### 2. Get Rider Details

Get detailed information about a specific rider.

**Method**: `GET`  
**Endpoint**: `/rest/v1/motards`  
**Function**: `getRiderById()`

```dart
Future<RiderData?> getRiderById(String riderId) async {
  try {
    final response = await supabase
        .from('motards')
        .select('*')
        .eq('id', riderId)
        .single();
    
    return RiderData.fromJson(response);
  } catch (e) {
    return null;
  }
}
```

**Parameters**:
- `riderId` (string, required): Unique rider identifier

**Response**:
```dart
RiderData {
  id: "uuid",
  nomComplet: "Rider Name",
  numTel: "+213XXXXXXXXX",
  ratingAverage: 4.5,
  currentLocation: LatLng(36.7538, 3.0588),
  distanceKm: 0.0, // Not calculated for single rider
  status: "online",
  vehicleType: "motorcycle",
  licensePlate: "ABC123"
}
```

### 3. Update Rider Location

Update rider's current location (for testing purposes).

**Method**: `PATCH`  
**Endpoint**: `/rest/v1/motards`  
**Function**: `updateRiderLocation()`

```dart
Future<void> updateRiderLocation(String riderId, LatLng newLocation) async {
  try {
    await supabase
        .from('motards')
        .update({
          'current_location': 'POINT(${newLocation.longitude} ${newLocation.latitude})',
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', riderId);
  } catch (e) {
    throw Exception('Failed to update rider location');
  }
}
```

**Parameters**:
- `riderId` (string, required): Unique rider identifier
- `newLocation` (LatLng, required): New location coordinates

**Response**:
```dart
// Success: Location updated
// Error: Exception with error message
```

## Trip Management API

### 1. Create Trip

Create a new trip booking.

**Method**: `POST`  
**Endpoint**: `/rest/v1/trips`

```dart
Future<String> createTrip({
  required String userId,
  required LatLng pickupLocation,
  required String pickupAddress,
  required LatLng destinationLocation,
  required String destinationAddress,
  required double distanceKm,
  required int estimatedDurationMinutes,
  required int priceDA,
  String? riderId,
}) async {
  try {
    final response = await supabase.from('trips').insert({
      'user_id': userId,
      'rider_id': riderId,
      'pickup_location': 'POINT(${pickupLocation.longitude} ${pickupLocation.latitude})',
      'pickup_address': pickupAddress,
      'destination_location': 'POINT(${destinationLocation.longitude} ${destinationLocation.latitude})',
      'destination_address': destinationAddress,
      'distance_km': distanceKm,
      'estimated_duration_minutes': estimatedDurationMinutes,
      'price_da': priceDA,
      'status': 'pending',
    }).select().single();
    
    return response['id'];
  } catch (e) {
    throw Exception('Failed to create trip');
  }
}
```

**Parameters**:
- `userId` (string, required): User ID from authentication
- `pickupLocation` (LatLng, required): Pickup coordinates
- `pickupAddress` (string, required): Pickup address text
- `destinationLocation` (LatLng, required): Destination coordinates
- `destinationAddress` (string, required): Destination address text
- `distanceKm` (double, required): Trip distance in kilometers
- `estimatedDurationMinutes` (int, required): Estimated trip duration
- `priceDA` (int, required): Trip price in Algerian Dinars
- `riderId` (string, optional): Specific rider ID if pre-selected

**Response**:
```dart
String // Trip ID (UUID)
```

### 2. Get User Trips

Retrieve trip history for a user.

**Method**: `GET`  
**Endpoint**: `/rest/v1/trips`

```dart
Future<List<TripData>> getUserTrips(String userId, {
  String? status,
  int limit = 50,
}) async {
  try {
    var query = supabase
        .from('trips')
        .select('*, motards(nom_complet, rating_average)')
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(limit);
    
    if (status != null) {
      query = query.eq('status', status);
    }
    
    final response = await query;
    return response.map((trip) => TripData.fromJson(trip)).toList();
  } catch (e) {
    throw Exception('Failed to fetch trips');
  }
}
```

**Parameters**:
- `userId` (string, required): User ID from authentication
- `status` (string, optional): Filter by trip status
- `limit` (int, optional): Maximum number of results (default: 50)

**Response**:
```dart
List<TripData> [
  {
    id: "uuid",
    userId: "uuid",
    riderId: "uuid",
    pickupLocation: LatLng(36.7538, 3.0588),
    pickupAddress: "Pickup Address",
    destinationLocation: LatLng(36.7638, 3.0688),
    destinationAddress: "Destination Address",
    distanceKm: 5.2,
    estimatedDurationMinutes: 15,
    priceDA: 350,
    status: "completed",
    requestedAt: DateTime,
    completedAt: DateTime,
    riderName: "Rider Name",
    riderRating: 4.5
  }
]
```

### 3. Update Trip Status

Update the status of an existing trip.

**Method**: `PATCH`  
**Endpoint**: `/rest/v1/trips`

```dart
Future<void> updateTripStatus(String tripId, String newStatus) async {
  try {
    await supabase
        .from('trips')
        .update({
          'status': newStatus,
          'updated_at': DateTime.now().toIso8601String(),
          if (newStatus == 'in_progress') 'started_at': DateTime.now().toIso8601String(),
          if (newStatus == 'completed') 'completed_at': DateTime.now().toIso8601String(),
        })
        .eq('id', tripId);
  } catch (e) {
    throw Exception('Failed to update trip status');
  }
}
```

**Parameters**:
- `tripId` (string, required): Trip ID
- `newStatus` (string, required): New status ('pending', 'accepted', 'in_progress', 'completed', 'cancelled')

**Response**:
```dart
// Success: Trip status updated
// Error: Exception with error message
```

## Location Services API

### 1. Get Current Location

Get user's current GPS location.

**Function**: `getCurrentLocation()`

```dart
Future<Position> getCurrentLocation() async {
  try {
    // Check if location services are enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled');
    }

    // Check location permissions
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied');
    }

    // Get current position
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
      timeLimit: const Duration(seconds: 10),
    );

    return position;
  } catch (e) {
    throw Exception('Failed to get current location: ${e.toString()}');
  }
}
```

**Response**:
```dart
Position {
  latitude: 36.7538,
  longitude: 3.0588,
  accuracy: 5.0,
  altitude: 100.0,
  heading: 0.0,
  speed: 0.0,
  timestamp: DateTime
}
```

### 2. Geocode Address

Convert coordinates to human-readable address.

**Function**: `placemarkFromCoordinates()`

```dart
Future<String> getAddressFromCoordinates(double latitude, double longitude) async {
  try {
    List<Placemark> placemarks = await placemarkFromCoordinates(latitude, longitude);
    
    if (placemarks.isNotEmpty) {
      final placemark = placemarks.first;
      return '${placemark.street ?? ''}, ${placemark.locality ?? ''}'.trim();
    }
    
    return 'Unknown Location';
  } catch (e) {
    throw Exception('Failed to get address: ${e.toString()}');
  }
}
```

**Parameters**:
- `latitude` (double, required): Latitude coordinate
- `longitude` (double, required): Longitude coordinate

**Response**:
```dart
String // "Street Name, City Name"
```

### 3. Search Locations

Search for locations using Google Places API.

**Function**: `searchLocation()`

```dart
Future<List<LocationSuggestion>> searchLocation(String query) async {
  try {
    final response = await http.get(
      Uri.parse(
        'https://maps.googleapis.com/maps/api/place/textsearch/json?'
        'query=${Uri.encodeComponent(query)}&'
        'location=36.7538,3.0588&'
        'radius=100000&'
        'region=dz&'
        'key=YOUR_GOOGLE_MAPS_API_KEY'
      ),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final results = data['results'] as List<dynamic>;
      
      return results.map((item) => LocationSuggestion.fromJson(item)).toList();
    } else {
      throw Exception('Failed to search locations');
    }
  } catch (e) {
    throw Exception('Search error: ${e.toString()}');
  }
}
```

**Parameters**:
- `query` (string, required): Search query (minimum 3 characters)

**Response**:
```dart
List<LocationSuggestion> [
  {
    displayName: "Location Name",
    latitude: 36.7538,
    longitude: 3.0588,
    address: "Full Address",
    distance: 1500.0, // meters
    businessStatus: "OPERATIONAL",
    rating: 4.2,
    types: ["restaurant", "food"]
  }
]
```

## Promotions API

### 1. Get Active Promotions

Retrieve list of active promotions.

**Method**: `GET`  
**Endpoint**: `/rest/v1/promotions`

```dart
Future<List<PromotionData>> getActivePromotions() async {
  try {
    final response = await supabase
        .from('promotions')
        .select('*')
        .eq('is_active', true)
        .gte('valid_until', DateTime.now().toIso8601String())
        .order('created_at', ascending: false);
    
    return response.map((promo) => PromotionData.fromJson(promo)).toList();
  } catch (e) {
    throw Exception('Failed to fetch promotions');
  }
}
```

**Response**:
```dart
List<PromotionData> [
  {
    id: "uuid",
    title: "50% OFF First Ride",
    description: "Get 50% discount on your first ride with Rakeb",
    discountPercentage: 50,
    discountAmount: null,
    validFrom: DateTime,
    validUntil: DateTime,
    isActive: true
  }
]
```

## Error Handling

### Error Response Format
```dart
class ApiException implements Exception {
  final String message;
  final String? code;
  final int? statusCode;
  
  ApiException(this.message, {this.code, this.statusCode});
  
  @override
  String toString() => 'ApiException: $message';
}
```

### Common Error Codes

**Authentication Errors**:
- `invalid_phone`: Invalid phone number format
- `invalid_otp`: Invalid or expired OTP code
- `too_many_requests`: Rate limit exceeded
- `unauthorized`: Invalid or expired session

**Location Errors**:
- `location_disabled`: Location services disabled
- `permission_denied`: Location permission denied
- `location_timeout`: Location request timeout

**Network Errors**:
- `network_error`: Network connectivity issues
- `server_error`: Internal server error
- `timeout`: Request timeout

### Error Handling Example
```dart
try {
  final riders = await riderService.getNearbyRiders(
    userLocation: currentLocation,
    radiusKm: 50.0,
  );
} on ApiException catch (e) {
  // Handle API-specific errors
  print('API Error: ${e.message}');
} on Exception catch (e) {
  // Handle general exceptions
  print('General Error: ${e.toString()}');
}
```

## Rate Limits

### Authentication
- **OTP Requests**: 5 requests per phone number per hour
- **Verification Attempts**: 10 attempts per OTP code

### Location Services
- **Geocoding**: 100 requests per minute
- **Places Search**: 50 requests per minute

### General API
- **Database Queries**: 1000 requests per minute per user
- **Real-time Subscriptions**: 100 concurrent connections

## SDK Versions

### Required Dependencies
```yaml
dependencies:
  flutter: sdk: flutter
  supabase_flutter: ^2.0.0
  google_maps_flutter: ^2.5.0
  geolocator: ^10.1.0
  geocoding: ^2.1.1
  http: ^1.1.0
  provider: ^6.1.1
  pin_code_fields: ^8.0.1
```

### Minimum Platform Versions
- **Android**: API level 21 (Android 5.0)
- **iOS**: iOS 11.0
- **Flutter**: 3.8.1
- **Dart**: 3.0.0

---

**API Version**: 1.0.0  
**Last Updated**: December 2024  
**Base URL**: https://hatscaabqgcrvrxxszco.supabase.co