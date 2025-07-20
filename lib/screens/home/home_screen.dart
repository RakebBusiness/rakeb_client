import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:async';
import '../../services/api_service.dart';
import '../profile/profile_screen.dart';
import '../trips/trips_screen.dart';
import '../promotions/promotions_screen.dart';
import '../booking/ride_booking_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final Completer<GoogleMapController> _controller = Completer();
  
  // Default location (Lakhdaria, Bouira)
  static const CameraPosition _kLakhdaria = CameraPosition(
    target: LatLng(36.5644, 3.5892),
    zoom: 14.0,
  );
  
  LatLng _userLocation = const LatLng(36.5644, 3.5892); // Lakhdaria coordinates
  bool _locationLoaded = false;
  bool _isLoadingLocation = false;
  Set<Marker> _markers = {};
  List<Map<String, dynamic>> _nearbyRiders = [];
  bool _isLoadingRiders = false;
  final ApiService _apiService = ApiService();
  
  // Location selection mode
  bool _isLocationSelectionMode = false;
  String _selectionType = ''; // 'pickup' or 'destination'
  LatLng? _selectedPickupLocation;
  LatLng? _selectedDestinationLocation;
  String _selectedPickupAddress = '';
  String _selectedDestinationAddress = '';

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _loadNearbyRiders();
    
    // Listen for location selection requests
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForLocationSelectionRequest();
    });
  }

  Future<void> _loadNearbyRiders() async {
    if (!_locationLoaded) return;
    
    setState(() {
      _isLoadingRiders = true;
    });

    try {
      final response = await _apiService.getNearbyRiders(
        userLocation: _userLocation,
        radius: 50.0,
      );
      
      if (response['success'] == true && response['riders'] != null) {
        setState(() {
          _nearbyRiders = List<Map<String, dynamic>>.from(response['riders']);
        _isLoadingRiders = false;
      });
      
      _updateMarkersWithRiders();
      } else {
        setState(() {
          _nearbyRiders = [];
          _isLoadingRiders = false;
        });
      }
    } catch (e) {
      print('Error loading nearby riders: $e');
      setState(() {
        _nearbyRiders = [];
        _isLoadingRiders = false;
      });
    }
  }

  void _checkForLocationSelectionRequest() {
    // Check if we're returning from booking screen for location selection
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null && args['selectLocation'] == true) {
      setState(() {
        _isLocationSelectionMode = true;
        _selectionType = args['selectionType'] ?? 'pickup';
        _selectedPickupLocation = args['pickupLocation'];
        _selectedDestinationLocation = args['destinationLocation'];
        _selectedPickupAddress = args['pickupAddress'] ?? '';
        _selectedDestinationAddress = args['destinationAddress'] ?? '';
      });
      _updateMarkersForSelection();
      _showLocationSelectionInstructions();
    }
  }

  void _updateMarkersForSelection() {
    Set<Marker> markers = {};
    
    // Add user location marker
    markers.add(
      Marker(
        markerId: const MarkerId('user_location'),
        position: _userLocation,
        infoWindow: const InfoWindow(title: 'Your Location'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      ),
    );
    
    // Add pickup marker if exists
    if (_selectedPickupLocation != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('pickup'),
          position: _selectedPickupLocation!,
          infoWindow: InfoWindow(title: 'Pickup Location', snippet: _selectedPickupAddress),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        ),
      );
    }
    
    // Add destination marker if exists
    if (_selectedDestinationLocation != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('destination'),
          position: _selectedDestinationLocation!,
          infoWindow: InfoWindow(title: 'Destination', snippet: _selectedDestinationAddress),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      );
    }
    
    setState(() {
      _markers = markers;
    });
  }

  void _showLocationSelectionInstructions() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _selectionType == 'pickup' 
            ? 'Tap on the map to select pickup location'
            : 'Tap on the map to select destination',
        ),
        backgroundColor: const Color(0xFF32C156),
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'Cancel',
          textColor: Colors.white,
          onPressed: _cancelLocationSelection,
        ),
      ),
    );
  }

  void _cancelLocationSelection() {
    setState(() {
      _isLocationSelectionMode = false;
      _selectionType = '';
    });
    _updateMarkers();
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
  }

  void _updateMarkersWithRiders() {
    if (_isLocationSelectionMode) {
      _updateMarkersForSelection();
      return;
    }
    
    Set<Marker> markers = {};
    
    // Add user location marker
    markers.add(
      Marker(
        markerId: const MarkerId('user_location'),
        position: _userLocation,
        infoWindow: const InfoWindow(title: 'Your Location'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      ),
    );
    
    // Add rider markers
    for (var rider in _nearbyRiders) {
      markers.add(
        Marker(
          markerId: MarkerId('rider_${rider['id']}'),
          position: LatLng(
            rider['currentLocation']['latitude'],
            rider['currentLocation']['longitude'],
          ),
          infoWindow: InfoWindow(
            title: rider['nomComplet'],
            snippet: '⭐ ${rider['ratingAverage'].toStringAsFixed(1)} • ${rider['distanceKm'].toStringAsFixed(1)}km away',
          ),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
          onTap: () => _showRiderDetails(rider),
        ),
      );
    }
    
    setState(() {
      _markers = markers;
    });
  }

  void _showRiderDetails(Map<String, dynamic> rider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: const Color(0xFF32C156).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Icon(
                    Icons.motorcycle,
                    size: 30,
                    color: Color(0xFF32C156),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rider['nomComplet'],
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.orange, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            rider['ratingAverage'].toStringAsFixed(1),
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(width: 16),
                          const Icon(Icons.location_on, color: Colors.grey, size: 16),
                          const SizedBox(width: 4),
                          Text('${rider['distanceKm'].toStringAsFixed(1)} km away'),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  // Here you could implement booking with specific rider
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Requesting ride from ${rider['nomComplet']}...'),
                      backgroundColor: const Color(0xFF32C156),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF32C156),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Request Ride',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onMapTap(LatLng position) async {
    if (!_isLocationSelectionMode) return;

    try {
      // Use API service for reverse geocoding
      final response = await _apiService.reverseGeocode(position);
      
      String address = 'Selected Location';
      if (response['success'] == true && response['address'] != null) {
        address = response['address']['short'] ?? response['address']['formatted'] ?? 'Selected Location';
      } else {
        // Fallback to local geocoding
        try {
          List<Placemark> placemarks = await placemarkFromCoordinates(
            position.latitude,
            position.longitude,
          );
          
          if (placemarks.isNotEmpty) {
            final placemark = placemarks.first;
            address = '${placemark.street ?? ''}, ${placemark.locality ?? ''}'.trim();
            if (address == ', ') {
              address = placemark.name ?? 'Selected Location';
            }
          }
        } catch (e) {
          print('Fallback geocoding error: $e');
        }
      }

      setState(() {
        if (_selectionType == 'pickup') {
          _selectedPickupLocation = position;
          _selectedPickupAddress = address;
        } else {
          _selectedDestinationLocation = position;
          _selectedDestinationAddress = address;
        }
      });
      
      _updateMarkersForSelection();
      
      // Show confirmation and navigate back
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _selectionType == 'pickup' 
              ? 'Pickup location selected!'
              : 'Destination selected!',
          ),
          backgroundColor: const Color(0xFF32C156),
          duration: const Duration(seconds: 2),
        ),
      );
      
      // Wait a moment then navigate back to booking
      await Future.delayed(const Duration(milliseconds: 1500));
      _returnToBooking();
      
    } on ApiException catch (e) {
      print('API error getting address: ${e.message}');
      // Continue with default address
    } catch (e) {
      print('Error getting address: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to get address for selected location'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _returnToBooking() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => RideBookingScreen(
          currentLocation: _userLocation,
          selectedPickupLocation: _selectedPickupLocation,
          selectedDestinationLocation: _selectedDestinationLocation,
          selectedPickupAddress: _selectedPickupAddress,
          selectedDestinationAddress: _selectedDestinationAddress,
        ),
      ),
    );
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showLocationDialog('Location services are disabled. Please enable location services.');
        setState(() {
          _isLoadingLocation = false;
        });
        return;
      }

      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showLocationDialog('Location permissions are denied. Please grant location access.');
          setState(() {
            _isLoadingLocation = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showLocationDialog('Location permissions are permanently denied. Please enable them in settings.');
        setState(() {
          _isLoadingLocation = false;
        });
        return;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      setState(() {
        _userLocation = LatLng(position.latitude, position.longitude);
        _locationLoaded = true;
        _isLoadingLocation = false;
      });

      _updateMarkersWithRiders();
      
      // Load nearby riders after getting location
      _loadNearbyRiders();

      // Move map to user location
      final GoogleMapController controller = await _controller.future;
      controller.animateCamera(CameraUpdate.newLatLng(_userLocation));

    } catch (e) {
      print('Error getting location: $e');
      _showLocationDialog('Failed to get your location. Using Lakhdaria as default location.');
      setState(() {
        _isLoadingLocation = false;
        _locationLoaded = true; // Set to true so we can still load riders
      });
      // Load riders with default location
      _loadNearbyRiders();
    }
  }

  void _updateMarkers() {
    if (_isLocationSelectionMode) {
      _updateMarkersForSelection();
      return;
    }
    
    _updateMarkersWithRiders();
  }
  
  void _showLocationDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Location'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
            if (message.contains('settings'))
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Geolocator.openAppSettings();
                },
                child: const Text('Open Settings'),
              ),
          ],
        );
      },
    );
  }

  Future<void> _moveToCurrentLocation() async {
    if (_locationLoaded) {
      final GoogleMapController controller = await _controller.future;
      controller.animateCamera(CameraUpdate.newLatLng(_userLocation));
      // Refresh riders when moving to current location
      _loadNearbyRiders();
    } else {
      await _getCurrentLocation();
    }
  }

  void _showNavigationMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.person, color: Color(0xFF32C156)),
              title: const Text('My Profile'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProfileScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.directions_car, color: Color(0xFF32C156)),
              title: const Text('My Trips'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const TripsScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.local_offer, color: Color(0xFF32C156)),
              title: const Text('Promotions'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const PromotionsScreen()),
                );
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Google Maps
          GoogleMap(
            mapType: MapType.normal,
            initialCameraPosition: _kLakhdaria,
            onMapCreated: (GoogleMapController controller) {
              _controller.complete(controller);
            },
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            compassEnabled: true,
            trafficEnabled: false,
            buildingsEnabled: true,
            indoorViewEnabled: true,
            onTap: _onMapTap,
          ),
          
          // Top overlay with menu button
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                icon: Icon(
                  _isLocationSelectionMode ? Icons.close : Icons.more_vert, 
                  color: const Color(0xFF32C156)
                ),
                onPressed: _isLocationSelectionMode ? _cancelLocationSelection : _showNavigationMenu,
                iconSize: 24,
              ),
            ),
          ),

          // Riders count indicator
          if (!_isLocationSelectionMode && _nearbyRiders.isNotEmpty)
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF32C156),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.motorcycle, color: Colors.white, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '${_nearbyRiders.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // App title
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  _isLocationSelectionMode 
                    ? (_selectionType == 'pickup' ? 'Select Pickup' : 'Select Destination')
                    : 'Rakeb',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF32C156),
                  ),
                ),
              ),
            ),
          ),

          // Zoom controls
          if (!_isLocationSelectionMode) Positioned(
            right: 16,
            top: MediaQuery.of(context).padding.top + 80,
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.add, color: Color(0xFF32C156)),
                    onPressed: () async {
                      final GoogleMapController controller = await _controller.future;
                      controller.animateCamera(CameraUpdate.zoomIn());
                    },
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.remove, color: Color(0xFF32C156)),
                    onPressed: () async {
                      final GoogleMapController controller = await _controller.future;
                      controller.animateCamera(CameraUpdate.zoomOut());
                    },
                  ),
                ),
              ],
            ),
          ),

          // My location button
          if (!_isLocationSelectionMode) Positioned(
            right: 16,
            bottom: 180,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(Icons.my_location, color: Color(0xFF32C156)),
                onPressed: () {
                  _moveToCurrentLocation();
                },
                iconSize: 24,
              ),
            ),
          ),

          // Refresh riders button
          if (!_isLocationSelectionMode) Positioned(
            right: 16,
            bottom: 120,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                icon: _isLoadingRiders 
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF32C156),
                        ),
                      )
                    : const Icon(Icons.refresh, color: Color(0xFF32C156)),
                onPressed: _isLoadingRiders ? null : _loadNearbyRiders,
                iconSize: 24,
              ),
            ),
          ),

          // Bottom action buttons
          if (!_isLocationSelectionMode) Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 56,
                    decoration: BoxDecoration(
                      color: const Color(0xFF32C156),
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => RideBookingScreen(
                              currentLocation: _userLocation,
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.directions_car, color: Colors.white),
                          SizedBox(width: 8),
                          Text(
                            'Book a Ride',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Location selection confirmation button
          if (_isLocationSelectionMode) Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _cancelLocationSelection,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.close, color: Colors.white),
                          SizedBox(width: 8),
                          Text(
                            'Cancel Selection',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    height: 56,
                    decoration: BoxDecoration(
                      color: const Color(0xFF32C156),
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _returnToBooking,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check, color: Colors.white),
                          SizedBox(width: 8),
                          Text(
                            'Continue',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}