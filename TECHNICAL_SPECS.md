# Rakib App - Technical Specifications

## System Architecture

### Frontend Architecture
- **Framework**: Flutter 3.8.1
- **Language**: Dart
- **State Management**: Provider Pattern
- **Navigation**: Named Routes with MaterialApp
- **UI Framework**: Material Design 3

### Backend Architecture
- **Backend-as-a-Service**: Supabase
- **Database**: PostgreSQL with PostGIS extension
- **Authentication**: Supabase Auth with OTP
- **Real-time**: Supabase Realtime subscriptions

### External Services
- **Maps**: Google Maps Platform
  - Maps SDK for Android
  - Places API
  - Geocoding API
- **Location**: Geolocator package
- **HTTP Client**: Dart HTTP package

## Database Schema

### Authentication Tables (Supabase Auth)
```sql
-- Users table (managed by Supabase Auth)
auth.users (
  id UUID PRIMARY KEY,
  phone TEXT UNIQUE,
  email TEXT,
  created_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ,
  user_metadata JSONB
)
```

### Application Tables
```sql
-- Riders/Motards table
CREATE TABLE public.motards (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  nom_complet TEXT NOT NULL,
  num_tel TEXT UNIQUE NOT NULL,
  rating_average DECIMAL(3,2) DEFAULT 4.5 CHECK (rating_average >= 0 AND rating_average <= 5),
  current_location POINT,
  status TEXT DEFAULT 'offline' CHECK (status IN ('online', 'offline', 'busy')),
  vehicle_type TEXT DEFAULT 'motorcycle',
  license_plate TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Trips table
CREATE TABLE public.trips (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id),
  rider_id UUID REFERENCES public.motards(id),
  pickup_location POINT NOT NULL,
  pickup_address TEXT NOT NULL,
  destination_location POINT NOT NULL,
  destination_address TEXT NOT NULL,
  distance_km DECIMAL(8,2),
  estimated_duration_minutes INTEGER,
  price_da INTEGER, -- Price in Algerian Dinars
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'in_progress', 'completed', 'cancelled')),
  requested_at TIMESTAMPTZ DEFAULT NOW(),
  started_at TIMESTAMPTZ,
  completed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Ratings table
CREATE TABLE public.ratings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  trip_id UUID REFERENCES public.trips(id),
  user_id UUID REFERENCES auth.users(id),
  rider_id UUID REFERENCES public.motards(id),
  rating INTEGER CHECK (rating >= 1 AND rating <= 5),
  comment TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Promotions table
CREATE TABLE public.promotions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  discount_percentage INTEGER CHECK (discount_percentage >= 0 AND discount_percentage <= 100),
  discount_amount INTEGER, -- Fixed amount discount in DA
  valid_from TIMESTAMPTZ DEFAULT NOW(),
  valid_until TIMESTAMPTZ,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

### Indexes and Performance
```sql
-- Spatial index for location queries
CREATE INDEX idx_motards_location ON public.motards USING GIST (current_location);

-- Status index for active riders
CREATE INDEX idx_motards_status ON public.motards (status) WHERE status = 'online';

-- Trip status index
CREATE INDEX idx_trips_status ON public.trips (status);

-- User trips index
CREATE INDEX idx_trips_user_id ON public.trips (user_id);

-- Rider trips index
CREATE INDEX idx_trips_rider_id ON public.trips (rider_id);
```

### Row Level Security (RLS)
```sql
-- Enable RLS on all tables
ALTER TABLE public.motards ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.trips ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ratings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.promotions ENABLE ROW LEVEL SECURITY;

-- Policies for motards table
CREATE POLICY "Public can view online riders" ON public.motards
  FOR SELECT USING (status = 'online');

CREATE POLICY "Riders can update own profile" ON public.motards
  FOR UPDATE USING (auth.uid()::text = id::text);

-- Policies for trips table
CREATE POLICY "Users can view own trips" ON public.trips
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can create trips" ON public.trips
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Policies for ratings table
CREATE POLICY "Users can view all ratings" ON public.ratings
  FOR SELECT TO authenticated;

CREATE POLICY "Users can create ratings for own trips" ON public.ratings
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Policies for promotions table
CREATE POLICY "Public can view active promotions" ON public.promotions
  FOR SELECT USING (is_active = true AND valid_until > NOW());
```

## API Specifications

### Authentication API

#### Request OTP
```dart
// Method: POST
// Endpoint: Supabase Auth
await supabase.auth.signInWithOtp(
  phone: '+213XXXXXXXXX'
);

// Response: Success/Error
// Success: OTP sent to phone
// Error: Invalid phone number, rate limit exceeded
```

#### Verify OTP
```dart
// Method: POST
// Endpoint: Supabase Auth
await supabase.auth.verifyOTP(
  type: OtpType.sms,
  token: '123456',
  phone: '+213XXXXXXXXX'
);

// Response: AuthResponse
// Success: User session created
// Error: Invalid OTP, expired token
```

### Rider API

#### Get Nearby Riders
```dart
// Method: GET
// Endpoint: /rest/v1/motards
final response = await supabase
  .from('motards')
  .select('*')
  .eq('status', 'online')
  .limit(20);

// Response: List<RiderData>
// Includes: id, nom_complet, rating_average, current_location, distance
```

#### Update Rider Location
```dart
// Method: PATCH
// Endpoint: /rest/v1/motards
await supabase
  .from('motards')
  .update({
    'current_location': 'POINT(longitude latitude)',
    'updated_at': DateTime.now().toIso8601String(),
  })
  .eq('id', riderId);
```

### Trip API

#### Create Trip
```dart
// Method: POST
// Endpoint: /rest/v1/trips
await supabase.from('trips').insert({
  'user_id': userId,
  'pickup_location': 'POINT(lng lat)',
  'pickup_address': 'Address string',
  'destination_location': 'POINT(lng lat)',
  'destination_address': 'Address string',
  'distance_km': 5.2,
  'estimated_duration_minutes': 15,
  'price_da': 350,
});
```

#### Get User Trips
```dart
// Method: GET
// Endpoint: /rest/v1/trips
final trips = await supabase
  .from('trips')
  .select('*')
  .eq('user_id', userId)
  .order('created_at', ascending: false);
```

## Location Services

### Google Maps Configuration
```xml
<!-- android/app/src/main/AndroidManifest.xml -->
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="YOUR_GOOGLE_MAPS_API_KEY" />
```

### Location Permissions
```xml
<!-- android/app/src/main/AndroidManifest.xml -->
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.INTERNET" />
```

### Location Service Implementation
```dart
class LocationService {
  static Future<Position> getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
      timeLimit: Duration(seconds: 10),
    );
  }
}
```

## State Management

### Provider Architecture
```dart
// Main app with providers
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => AuthService()),
    ChangeNotifierProvider(create: (_) => RiderService()),
    ChangeNotifierProvider(create: (_) => TripService()),
  ],
  child: MyApp(),
)
```

### Auth State Management
```dart
class AuthService extends ChangeNotifier {
  AppAuthState _state = const AppAuthState();
  
  AppAuthState get state => _state;
  User? get currentUser => _supabase.auth.currentUser;
  bool get isAuthenticated => currentUser != null;
  
  void _updateState(AppAuthState newState) {
    _state = newState;
    notifyListeners();
  }
}
```

### State Models
```dart
enum AppAuthStatus {
  initial,
  loading,
  codeSent,
  verified,
  error,
  authenticated,
  unauthenticated
}

class AppAuthState {
  final AppAuthStatus status;
  final String? error;
  final String? phoneNumber;
  final String? userId;
  
  const AppAuthState({
    this.status = AppAuthStatus.initial,
    this.error,
    this.phoneNumber,
    this.userId,
  });
}
```

## Security Specifications

### Authentication Security
- **OTP Verification**: 6-digit SMS codes with expiration
- **Rate Limiting**: Prevent spam OTP requests
- **Session Management**: JWT tokens with automatic refresh
- **Phone Validation**: Server-side format validation

### Data Security
- **Row Level Security**: Database-level access control
- **API Authentication**: All requests require valid session
- **Input Validation**: Client and server-side validation
- **SQL Injection Prevention**: Parameterized queries

### Privacy Protection
- **Location Data**: Encrypted transmission and storage
- **Personal Information**: Minimal data collection
- **Data Retention**: Automatic cleanup of old data
- **User Consent**: Clear privacy policy and terms

## Performance Specifications

### App Performance
- **Cold Start Time**: < 3 seconds
- **Hot Reload**: < 1 second
- **Memory Usage**: < 150MB average
- **Battery Optimization**: Background location limits

### Network Performance
- **API Response Time**: < 2 seconds average
- **Image Loading**: Progressive loading with caching
- **Offline Support**: Basic functionality without internet
- **Data Usage**: Optimized for mobile networks

### Database Performance
- **Query Response**: < 500ms for rider queries
- **Concurrent Users**: Support for 1000+ simultaneous users
- **Spatial Queries**: Optimized with PostGIS indexes
- **Connection Pooling**: Efficient database connections

## Testing Specifications

### Unit Testing
```dart
// Test authentication service
testWidgets('AuthService should format phone numbers correctly', (tester) async {
  final authService = AuthService();
  final formatted = authService.formatPhoneNumber('0512345678');
  expect(formatted, equals('+213512345678'));
});
```

### Integration Testing
```dart
// Test complete booking flow
testWidgets('Complete ride booking flow', (tester) async {
  await tester.pumpWidget(MyApp());
  
  // Navigate to booking screen
  await tester.tap(find.text('Book a Ride'));
  await tester.pumpAndSettle();
  
  // Enter pickup location
  await tester.enterText(find.byType(TextField).first, 'Algiers Center');
  await tester.pumpAndSettle();
  
  // Verify booking confirmation
  expect(find.text('Confirm Booking'), findsOneWidget);
});
```

### Performance Testing
- **Load Testing**: Simulate multiple concurrent users
- **Stress Testing**: Test system limits and recovery
- **Memory Profiling**: Monitor memory leaks and usage
- **Network Testing**: Test various connection speeds

## Deployment Specifications

### Build Configuration
```yaml
# pubspec.yaml
flutter:
  uses-material-design: true
  
# Build commands
flutter build apk --release
flutter build appbundle --release
```

### Environment Configuration
```dart
// Environment-specific configurations
class Config {
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://your-project.supabase.co'
  );
  
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'your-anon-key'
  );
}
```

### Release Checklist
- [ ] Update version numbers
- [ ] Test on multiple devices
- [ ] Verify API endpoints
- [ ] Check permissions and security
- [ ] Performance testing
- [ ] Code signing and certificates
- [ ] Store listing and metadata

## Monitoring and Analytics

### Error Tracking
- **Crash Reporting**: Automatic crash detection and reporting
- **Error Logging**: Comprehensive error logging system
- **Performance Monitoring**: Real-time performance metrics
- **User Feedback**: In-app feedback collection

### Analytics
- **User Behavior**: Track user interactions and flows
- **Feature Usage**: Monitor feature adoption rates
- **Performance Metrics**: App performance and load times
- **Business Metrics**: Trip completion rates, user retention

### Logging
```dart
// Structured logging implementation
class Logger {
  static void info(String message, {Map<String, dynamic>? data}) {
    print('[INFO] $message ${data != null ? jsonEncode(data) : ''}');
  }
  
  static void error(String message, {dynamic error, StackTrace? stackTrace}) {
    print('[ERROR] $message');
    if (error != null) print('Error: $error');
    if (stackTrace != null) print('Stack: $stackTrace');
  }
}
```

---

**Document Version**: 1.0.0
**Last Updated**: December 2024
**Flutter Version**: 3.8.1
**Supabase Version**: 2.0.0