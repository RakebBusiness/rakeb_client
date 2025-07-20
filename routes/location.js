const express = require('express');
const axios = require('axios');
const { locationValidation } = require('../middleware/validation');

const router = express.Router();

// Calculate distance between two points
const calculateDistance = (lat1, lon1, lat2, lon2) => {
  const R = 6371; // Earth's radius in kilometers
  const dLat = (lat2 - lat1) * Math.PI / 180;
  const dLon = (lon2 - lon1) * Math.PI / 180;
  const a = 
    Math.sin(dLat/2) * Math.sin(dLat/2) +
    Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) * 
    Math.sin(dLon/2) * Math.sin(dLon/2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));
  return R * c;
};

// Get location icon based on place types
const getLocationIcon = (types) => {
  if (types.includes('restaurant') || types.includes('food')) {
    return 'restaurant';
  } else if (types.includes('hospital') || types.includes('pharmacy')) {
    return 'hospital';
  } else if (types.includes('school') || types.includes('university')) {
    return 'school';
  } else if (types.includes('shopping_mall') || types.includes('store')) {
    return 'shopping';
  } else if (types.includes('gas_station')) {
    return 'gas_station';
  } else if (types.includes('bank') || types.includes('atm')) {
    return 'bank';
  } else if (types.includes('mosque') || types.includes('church')) {
    return 'place_of_worship';
  } else if (types.includes('airport')) {
    return 'airport';
  } else if (types.includes('bus_station') || types.includes('transit_station')) {
    return 'transit';
  } else {
    return 'location';
  }
};

// Search locations using Google Places API
router.get('/search', locationValidation.search, async (req, res) => {
  try {
    const { query, latitude, longitude } = req.query;
    const userLat = latitude ? parseFloat(latitude) : 36.7538; // Default to Algiers
    const userLng = longitude ? parseFloat(longitude) : 3.0588;

    if (!process.env.GOOGLE_MAPS_API_KEY) {
      return res.status(500).json({
        error: 'Configuration error',
        message: 'Google Maps API key not configured'
      });
    }

    // Search using Google Places Text Search API
    const response = await axios.get('https://maps.googleapis.com/maps/api/place/textsearch/json', {
      params: {
        query: query,
        location: `${userLat},${userLng}`,
        radius: 100000, // 100km radius
        region: 'dz', // Algeria
        key: process.env.GOOGLE_MAPS_API_KEY
      }
    });

    if (response.data.status !== 'OK' && response.data.status !== 'ZERO_RESULTS') {
      return res.status(500).json({
        error: 'Google Places API error',
        message: response.data.error_message || 'Failed to search locations'
      });
    }

    const results = response.data.results || [];
    
    // Process and format results
    const suggestions = results.slice(0, 8).map(place => {
      const lat = place.geometry.location.lat;
      const lng = place.geometry.location.lng;
      
      // Calculate distance from user location
      const distance = calculateDistance(userLat, userLng, lat, lng) * 1000; // Convert to meters

      return {
        displayName: place.name,
        latitude: lat,
        longitude: lng,
        address: place.formatted_address,
        distance: Math.round(distance),
        businessStatus: place.business_status || '',
        rating: place.rating || null,
        types: place.types || [],
        icon: getLocationIcon(place.types || []),
        placeId: place.place_id
      };
    });

    // Sort by distance
    suggestions.sort((a, b) => a.distance - b.distance);

    res.status(200).json({
      success: true,
      suggestions,
      count: suggestions.length,
      query,
      userLocation: { latitude: userLat, longitude: userLng }
    });
  } catch (error) {
    console.error('Location search error:', error);
    
    if (error.response?.status === 403) {
      return res.status(403).json({
        error: 'API key error',
        message: 'Invalid or restricted Google Maps API key'
      });
    }

    res.status(500).json({
      error: 'Internal server error',
      message: 'Failed to search locations'
    });
  }
});

// Reverse geocoding - get address from coordinates
router.get('/reverse', locationValidation.coordinates, async (req, res) => {
  try {
    const { latitude, longitude } = req.query;

    if (!process.env.GOOGLE_MAPS_API_KEY) {
      return res.status(500).json({
        error: 'Configuration error',
        message: 'Google Maps API key not configured'
      });
    }

    const response = await axios.get('https://maps.googleapis.com/maps/api/geocode/json', {
      params: {
        latlng: `${latitude},${longitude}`,
        key: process.env.GOOGLE_MAPS_API_KEY,
        language: 'en' // You can change this to 'ar' for Arabic or 'fr' for French
      }
    });

    if (response.data.status !== 'OK') {
      return res.status(500).json({
        error: 'Geocoding error',
        message: response.data.error_message || 'Failed to get address'
      });
    }

    const results = response.data.results;
    if (results.length === 0) {
      return res.status(404).json({
        error: 'No address found',
        message: 'No address found for the given coordinates'
      });
    }

    const primaryResult = results[0];
    
    // Extract address components
    const addressComponents = primaryResult.address_components;
    let streetNumber = '';
    let route = '';
    let locality = '';
    let administrativeArea = '';
    let country = '';

    addressComponents.forEach(component => {
      const types = component.types;
      if (types.includes('street_number')) {
        streetNumber = component.long_name;
      } else if (types.includes('route')) {
        route = component.long_name;
      } else if (types.includes('locality')) {
        locality = component.long_name;
      } else if (types.includes('administrative_area_level_1')) {
        administrativeArea = component.long_name;
      } else if (types.includes('country')) {
        country = component.long_name;
      }
    });

    const shortAddress = `${streetNumber} ${route}`.trim() || locality || 'Unknown Location';
    
    res.status(200).json({
      success: true,
      address: {
        formatted: primaryResult.formatted_address,
        short: shortAddress,
        components: {
          streetNumber,
          route,
          locality,
          administrativeArea,
          country
        }
      },
      location: {
        latitude: parseFloat(latitude),
        longitude: parseFloat(longitude)
      },
      placeId: primaryResult.place_id
    });
  } catch (error) {
    console.error('Reverse geocoding error:', error);
    res.status(500).json({
      error: 'Internal server error',
      message: 'Failed to get address from coordinates'
    });
  }
});

// Get place details by place ID
router.get('/place/:placeId', async (req, res) => {
  try {
    const { placeId } = req.params;

    if (!process.env.GOOGLE_MAPS_API_KEY) {
      return res.status(500).json({
        error: 'Configuration error',
        message: 'Google Maps API key not configured'
      });
    }

    const response = await axios.get('https://maps.googleapis.com/maps/api/place/details/json', {
      params: {
        place_id: placeId,
        fields: 'name,formatted_address,geometry,rating,opening_hours,formatted_phone_number,website,types',
        key: process.env.GOOGLE_MAPS_API_KEY
      }
    });

    if (response.data.status !== 'OK') {
      return res.status(500).json({
        error: 'Place details error',
        message: response.data.error_message || 'Failed to get place details'
      });
    }

    const place = response.data.result;
    
    res.status(200).json({
      success: true,
      place: {
        name: place.name,
        address: place.formatted_address,
        location: {
          latitude: place.geometry.location.lat,
          longitude: place.geometry.location.lng
        },
        rating: place.rating || null,
        phone: place.formatted_phone_number || null,
        website: place.website || null,
        types: place.types || [],
        openingHours: place.opening_hours?.weekday_text || null,
        isOpen: place.opening_hours?.open_now || null,
        icon: getLocationIcon(place.types || [])
      }
    });
  } catch (error) {
    console.error('Place details error:', error);
    res.status(500).json({
      error: 'Internal server error',
      message: 'Failed to get place details'
    });
  }
});

// Calculate route between two points
router.post('/route', async (req, res) => {
  try {
    const { origin, destination } = req.body;

    if (!origin || !destination) {
      return res.status(400).json({
        error: 'Missing coordinates',
        message: 'Origin and destination coordinates are required'
      });
    }

    if (!process.env.GOOGLE_MAPS_API_KEY) {
      return res.status(500).json({
        error: 'Configuration error',
        message: 'Google Maps API key not configured'
      });
    }

    const response = await axios.get('https://maps.googleapis.com/maps/api/directions/json', {
      params: {
        origin: `${origin.latitude},${origin.longitude}`,
        destination: `${destination.latitude},${destination.longitude}`,
        mode: 'driving', // or 'walking', 'bicycling', 'transit'
        key: process.env.GOOGLE_MAPS_API_KEY
      }
    });

    if (response.data.status !== 'OK') {
      return res.status(500).json({
        error: 'Directions error',
        message: response.data.error_message || 'Failed to calculate route'
      });
    }

    const route = response.data.routes[0];
    const leg = route.legs[0];

    res.status(200).json({
      success: true,
      route: {
        distance: {
          text: leg.distance.text,
          value: leg.distance.value // in meters
        },
        duration: {
          text: leg.duration.text,
          value: leg.duration.value // in seconds
        },
        startAddress: leg.start_address,
        endAddress: leg.end_address,
        steps: leg.steps.map(step => ({
          instruction: step.html_instructions.replace(/<[^>]*>/g, ''), // Remove HTML tags
          distance: step.distance.text,
          duration: step.duration.text,
          startLocation: step.start_location,
          endLocation: step.end_location
        })),
        polyline: route.overview_polyline.points
      }
    });
  } catch (error) {
    console.error('Route calculation error:', error);
    res.status(500).json({
      error: 'Internal server error',
      message: 'Failed to calculate route'
    });
  }
});

module.exports = router;