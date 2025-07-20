const express = require('express');
const { supabase } = require('../config/database');
const { riderValidation } = require('../middleware/validation');

const router = express.Router();

// Calculate distance between two points using Haversine formula
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

// Parse PostGIS POINT format
const parseLocation = (locationStr) => {
  if (!locationStr) return null;
  
  if (locationStr.startsWith('POINT(')) {
    const coords = locationStr.substring(6, locationStr.length - 1);
    const [lng, lat] = coords.split(' ').map(Number);
    return { latitude: lat, longitude: lng };
  }
  
  return null;
};

// Get nearby riders
router.get('/nearby', riderValidation.nearby, async (req, res) => {
  try {
    const { latitude, longitude, radius = 50 } = req.query;
    const userLat = parseFloat(latitude);
    const userLng = parseFloat(longitude);
    const radiusKm = parseFloat(radius);

    // Get online riders from database
    const { data: riders, error } = await supabase
      .from('motards')
      .select('*')
      .eq('status', 'online')
      .limit(50);

    if (error) {
      return res.status(500).json({
        error: 'Database error',
        message: error.message
      });
    }

    // Process riders and calculate distances
    const nearbyRiders = riders
      .map(rider => {
        const location = parseLocation(rider.current_location);
        
        if (!location) {
          // Default location near Lakhdaria with some offset
          const offset = Math.random() * 0.02 - 0.01;
          location = {
            latitude: 36.5644 + offset,
            longitude: 3.5892 + offset
          };
        }

        const distance = calculateDistance(
          userLat, userLng,
          location.latitude, location.longitude
        );

        return {
          id: rider.id,
          nomComplet: rider.nom_complet,
          numTel: rider.num_tel,
          ratingAverage: rider.rating_average || 4.5,
          currentLocation: location,
          distanceKm: Math.round(distance * 100) / 100,
          status: rider.status,
          vehicleType: rider.vehicle_type || 'motorcycle',
          licensePlate: rider.license_plate
        };
      })
      .filter(rider => rider.distanceKm <= radiusKm)
      .sort((a, b) => a.distanceKm - b.distanceKm);

    res.status(200).json({
      success: true,
      riders: nearbyRiders,
      count: nearbyRiders.length,
      searchRadius: radiusKm,
      userLocation: { latitude: userLat, longitude: userLng }
    });
  } catch (error) {
    console.error('Get nearby riders error:', error);
    res.status(500).json({
      error: 'Internal server error',
      message: 'Failed to fetch nearby riders'
    });
  }
});

// Get rider by ID
router.get('/:riderId', async (req, res) => {
  try {
    const { riderId } = req.params;

    const { data: rider, error } = await supabase
      .from('motards')
      .select('*')
      .eq('id', riderId)
      .single();

    if (error) {
      if (error.code === 'PGRST116') {
        return res.status(404).json({
          error: 'Rider not found',
          message: 'The specified rider does not exist'
        });
      }
      return res.status(500).json({
        error: 'Database error',
        message: error.message
      });
    }

    const location = parseLocation(rider.current_location) || {
      latitude: 36.5644,
      longitude: 3.5892
    };

    res.status(200).json({
      success: true,
      rider: {
        id: rider.id,
        nomComplet: rider.nom_complet,
        numTel: rider.num_tel,
        ratingAverage: rider.rating_average || 4.5,
        currentLocation: location,
        status: rider.status,
        vehicleType: rider.vehicle_type || 'motorcycle',
        licensePlate: rider.license_plate,
        createdAt: rider.created_at
      }
    });
  } catch (error) {
    console.error('Get rider error:', error);
    res.status(500).json({
      error: 'Internal server error',
      message: 'Failed to fetch rider details'
    });
  }
});

// Update rider location (for testing)
router.patch('/:riderId/location', async (req, res) => {
  try {
    const { riderId } = req.params;
    const { latitude, longitude } = req.body;

    if (!latitude || !longitude) {
      return res.status(400).json({
        error: 'Invalid coordinates',
        message: 'Latitude and longitude are required'
      });
    }

    const { error } = await supabase
      .from('motards')
      .update({
        current_location: `POINT(${longitude} ${latitude})`,
        updated_at: new Date().toISOString()
      })
      .eq('id', riderId);

    if (error) {
      return res.status(500).json({
        error: 'Database error',
        message: error.message
      });
    }

    res.status(200).json({
      success: true,
      message: 'Rider location updated successfully',
      location: { latitude, longitude }
    });
  } catch (error) {
    console.error('Update rider location error:', error);
    res.status(500).json({
      error: 'Internal server error',
      message: 'Failed to update rider location'
    });
  }
});

// Get rider ratings
router.get('/:riderId/ratings', async (req, res) => {
  try {
    const { riderId } = req.params;
    const { limit = 10 } = req.query;

    const { data: ratings, error } = await supabase
      .from('ratings')
      .select('rating, comment, created_at')
      .eq('rider_id', riderId)
      .order('created_at', { ascending: false })
      .limit(parseInt(limit));

    if (error) {
      return res.status(500).json({
        error: 'Database error',
        message: error.message
      });
    }

    const averageRating = ratings.length > 0 
      ? ratings.reduce((sum, r) => sum + r.rating, 0) / ratings.length
      : 0;

    res.status(200).json({
      success: true,
      ratings,
      averageRating: Math.round(averageRating * 10) / 10,
      totalRatings: ratings.length
    });
  } catch (error) {
    console.error('Get rider ratings error:', error);
    res.status(500).json({
      error: 'Internal server error',
      message: 'Failed to fetch rider ratings'
    });
  }
});

module.exports = router;