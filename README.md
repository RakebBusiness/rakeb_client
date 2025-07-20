# Rakib - Ride Sharing App Documentation

## Overview

Rakib is a modern ride-sharing mobile application built with Flutter, designed specifically for the Algerian market. The app connects passengers with motorcycle riders (motards) for quick and efficient transportation within cities.

## Table of Contents

1. [Features](#features)
2. [Architecture](#architecture)
3. [Authentication System](#authentication-system)
4. [Core Functionalities](#core-functionalities)
5. [User Interface](#user-interface)
6. [Backend Integration](#backend-integration)
7. [Location Services](#location-services)
8. [Installation & Setup](#installation--setup)
9. [API Documentation](#api-documentation)
10. [Troubleshooting](#troubleshooting)

## Features

### 🔐 Authentication
- **Phone Number Authentication**: Secure OTP-based login using Algerian phone numbers
- **Multiple Phone Formats**: Supports various Algerian number formats (05XX, 06XX, 07XX, +213)
- **User Profile Management**: Complete profile setup with display name
- **Session Management**: Persistent login sessions with automatic token refresh

### 🗺️ Maps & Location
- **Google Maps Integration**: Real-time map display with custom markers
- **Current Location Detection**: Automatic GPS location detection
- **Location Selection**: Interactive map-based location picking
- **Address Geocoding**: Convert coordinates to readable addresses
- **Zoom Controls**: Custom zoom in/out controls

### 🚗 Ride Booking
- **Smart Location Search**: Search for pickup and destination locations
- **Map-based Selection**: Choose locations directly from the map
- **Distance Calculation**: Real-time distance and time estimation
- **Price Estimation**: Dynamic pricing based on distance
- **Ride Confirmation**: Detailed trip summary before booking

### 👥 Rider Management
- **Nearby Riders**: Display available riders within specified radius
- **Rider Profiles**: View rider details, ratings, and distance
- **Real-time Tracking**: Live rider location updates
- **Rating System**: 5-star rating system for riders

### 📱 User Experience
- **Intuitive Navigation**: Bottom sheet menus and smooth transitions
- **Loading States**: Visual feedback during operations
- **Error Handling**: User-friendly error messages
- **Responsive Design**: Optimized for various screen sizes

## Architecture

### Project Structure
```
lib/
├── core/
│   └── routes.dart              # App routing configuration
├── models/
│   └── auth_state.dart          # Authentication state models
├── screens/
│   ├── auth/                    # Authentication screens
│   ├── booking/                 # Ride booking screens
│   ├── home/                    # Main home screen
│   ├── otp/                     # OTP verification
│   ├── profile/                 # User profile
│   ├── promotions/              # Promotions and offers
│   └── trips/                   # Trip history
├── services/
│   ├── auth_service.dart        # Authentication logic
│   ├── rider_service.dart       # Rider management
│   └── test_data_service.dart   # Test data utilities
└── widgets/
    ├── App.header.dart          # Custom header widget
    ├── code_input_field.dart    # OTP input field
    └── welcome_header_clipper.dart # Custom clipper
```

### Design Patterns
- **Provider Pattern**: State management using Provider package
- **Service Layer**: Separation of business logic from UI
- **Repository Pattern**: Data access abstraction
- **Observer Pattern**: Real-time updates and notifications

## Authentication System

### Phone Number Validation
The app supports multiple Algerian phone number formats:
- `05XXXXXXXX` (10 digits with leading 0)
- `5XXXXXXXX` (9 digits without leading 0)
- `+213XXXXXXXXX` (international format)

### OTP Flow
1. **Phone Input**: User enters phone number
2. **Format Validation**: Number is validated and formatted
3. **OTP Request**: SMS code sent via Supabase Auth
4. **Code Verification**: 6-digit code verification
5. **Profile Setup**: New users complete profile
6. **Session Creation**: Persistent authentication session

### Security Features
- **Token-based Authentication**: JWT tokens for secure API calls
- **Session Management**: Automatic token refresh
- **Input Validation**: Client-side and server-side validation
- **Rate Limiting**: Protection against spam requests

## Core Functionalities

### 1. Home Screen (`HomeScreen`)
**Purpose**: Main interface for map interaction and ride booking

**Features**:
- Interactive Google Maps with custom markers
- Current location detection and display
- Nearby rider visualization
- Location selection mode for pickup/destination
- Quick access to booking, profile, and trip history

**Key Components**:
- `GoogleMap` widget with custom styling
- Floating action buttons for map controls
- Bottom sheet navigation menu
- Real-time rider markers with info windows

### 2. Ride Booking (`RideBookingScreen`)
**Purpose**: Complete ride booking workflow

**Features**:
- Dual location input (pickup and destination)
- Smart location search with suggestions
- Map-based location selection
- Trip summary with distance, time, and price
- Booking confirmation dialog

**Search Algorithm**:
- Google Places API integration
- Distance-based result sorting
- Business type categorization
- Rating and review display

### 3. Authentication Screens
**Login Screen** (`LoginScreen`):
- Phone number input with country code
- Terms and conditions acceptance
- Channel selection (WhatsApp/SMS)
- Input validation and error handling

**Signup Screen** (`SignupScreen`):
- Similar to login with registration flow
- Enhanced validation for new users
- Profile creation workflow

**OTP Screen** (`OtpScreen`):
- 6-digit PIN code input
- Countdown timer for resend
- Automatic verification on completion
- Error handling for invalid codes

**Username Screen** (`UsernameScreen`):
- Profile completion for new users
- Display name input and validation
- Automatic navigation to home screen

### 4. Profile Management (`ProfileScreen`)
**Features**:
- User information display
- Profile editing options
- Payment method management
- Settings and preferences
- Help and support access

### 5. Trip History (`TripsScreen`)
**Features**:
- Trip filtering (Recent, Completed, Cancelled)
- Detailed trip cards with route information
- Status indicators and pricing
- Date and time stamps

### 6. Promotions (`PromotionsScreen`)
**Features**:
- Available offers and discounts
- Promotional cards with gradient designs
- Validity periods and terms
- Special offers for students and loyalty programs

## User Interface

### Design System
**Color Palette**:
- Primary: `#32C156` (Green)
- Secondary: Various accent colors
- Background: White and light grays
- Text: Dark grays and black

**Typography**:
- Headers: Bold, 18-24px
- Body: Regular, 14-16px
- Captions: Light, 12-14px

**Components**:
- **Custom Header**: Curved header with app branding
- **Input Fields**: Rounded containers with validation
- **Buttons**: Rounded corners with elevation
- **Cards**: Shadow-based elevation with rounded corners
- **Bottom Sheets**: Smooth slide-up modals

### Responsive Design
- Adaptive layouts for different screen sizes
- Proper padding and margins
- Scalable text and icons
- Touch-friendly button sizes

## Backend Integration

### Supabase Configuration
```dart
await Supabase.initialize(
  url: 'https://hatscaabqgcrvrxxszco.supabase.co',
  anonKey: 'your-anon-key',
);
```

### Database Schema
**Users Table** (`auth.users`):
- Managed by Supabase Auth
- Phone number authentication
- User metadata for display names

**Riders Table** (`motards`):
```sql
CREATE TABLE motards (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  nom_complet TEXT NOT NULL,
  num_tel TEXT UNIQUE NOT NULL,
  rating_average DECIMAL(3,2) DEFAULT 4.5,
  current_location POINT,
  status TEXT DEFAULT 'offline',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

### API Services

**AuthService** (`auth_service.dart`):
- Phone number formatting and validation
- OTP request and verification
- User profile management
- Session handling

**RiderService** (`rider_service.dart`):
- Nearby rider queries
- Distance calculations
- Rider profile retrieval
- Location updates

## Location Services

### Google Maps Integration
**Required Permissions**:
- Location access (fine and coarse)
- Internet connectivity

**Features**:
- Real-time location tracking
- Custom marker icons
- Info windows with rider details
- Zoom and pan controls
- Location selection callbacks

### Geocoding Services
**Address Resolution**:
- Coordinate to address conversion
- Place name suggestions
- Business location search
- Distance calculations

**Search Implementation**:
```dart
Future<List<LocationSuggestion>> searchLocation(String query) async {
  // Google Places API integration
  // Distance-based sorting
  // Business type categorization
}
```

## Installation & Setup

### Prerequisites
- Flutter SDK (3.8.1 or higher)
- Android Studio / VS Code
- Google Maps API key
- Supabase project

### Environment Setup
1. **Clone Repository**:
```bash
git clone <repository-url>
cd rakib-app
```

2. **Install Dependencies**:
```bash
flutter pub get
```

3. **Configure Google Maps**:
   - Add API key to `android/app/src/main/AndroidManifest.xml`
   - Enable Maps SDK and Places API

4. **Configure Supabase**:
   - Update URL and keys in `main.dart`
   - Set up database tables
   - Configure authentication settings

5. **Run Application**:
```bash
flutter run
```

### Build Configuration
**Android**:
- Minimum SDK: 21
- Target SDK: 34
- Permissions: Location, Internet

**Dependencies**:
```yaml
dependencies:
  flutter: sdk: flutter
  google_maps_flutter: ^2.5.0
  geolocator: ^10.1.0
  geocoding: ^2.1.1
  http: ^1.1.0
  provider: ^6.1.1
  supabase_flutter: ^2.0.0
  pin_code_fields: ^8.0.1
```

## API Documentation

### Authentication Endpoints
**Request OTP**:
```dart
await supabase.auth.signInWithOtp(phone: formattedPhone);
```

**Verify OTP**:
```dart
await supabase.auth.verifyOTP(
  type: OtpType.sms,
  token: smsCode,
  phone: phoneNumber,
);
```

### Rider Queries
**Get Nearby Riders**:
```dart
final riders = await riderService.getNearbyRiders(
  userLocation: currentLocation,
  radiusKm: 50.0,
);
```

**Update Rider Location**:
```dart
await riderService.updateRiderLocation(riderId, newLocation);
```

### Location Services
**Get Current Location**:
```dart
Position position = await Geolocator.getCurrentPosition(
  desiredAccuracy: LocationAccuracy.high,
);
```

**Geocode Address**:
```dart
List<Placemark> placemarks = await placemarkFromCoordinates(
  latitude, longitude,
);
```

## Troubleshooting

### Common Issues

**1. Location Permission Denied**:
- Check app permissions in device settings
- Ensure location services are enabled
- Request permissions at runtime

**2. Google Maps Not Loading**:
- Verify API key configuration
- Check internet connectivity
- Ensure Maps SDK is enabled

**3. OTP Not Received**:
- Verify phone number format
- Check Supabase authentication settings
- Ensure SMS service is configured

**4. Rider Data Not Loading**:
- Check database connection
- Verify table permissions
- Review query syntax

### Debug Commands
```bash
# Check Flutter doctor
flutter doctor

# Clear cache
flutter clean
flutter pub get

# Run with verbose logging
flutter run --verbose

# Check device logs
flutter logs
```

### Performance Optimization
- **Image Optimization**: Use appropriate image sizes
- **Map Rendering**: Limit marker count for performance
- **Network Calls**: Implement caching and retry logic
- **Memory Management**: Dispose controllers and listeners

## Contributing

### Code Style
- Follow Dart/Flutter conventions
- Use meaningful variable names
- Add comments for complex logic
- Implement proper error handling

### Testing
- Unit tests for services
- Widget tests for UI components
- Integration tests for user flows

### Version Control
- Feature branch workflow
- Descriptive commit messages
- Pull request reviews

## License

This project is licensed under the MIT License. See LICENSE file for details.

## Support

For technical support or questions:
- Create an issue in the repository
- Contact the development team
- Check the troubleshooting section

---

**Last Updated**: December 2024
**Version**: 1.0.0
**Flutter Version**: 3.8.1