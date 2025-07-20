const express = require('express');
const { supabase } = require('../config/database');
const { tripValidation } = require('../middleware/validation');

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

// Calculate trip price
const calculatePrice = (distanceKm) => {
  const basePrice = 100; // Base price in DA
  const pricePerKm = 50; // Price per km in DA
  return Math.round(basePrice + (distanceKm * pricePerKm));
};

// Calculate estimated duration
const calculateDuration = (distanceKm) => {
  const averageSpeedKmh = 20; // Average speed in km/h
  return Math.round((distanceKm / averageSpeedKmh) * 60); // Duration in minutes
};

// Create a new trip
router.post('/', tripValidation.create, async (req, res) => {
  try {
    const {
      pickupLocation,
      pickupAddress,
      destinationLocation,
      destinationAddress,
      riderId
    } = req.body;

    const userId = req.user.id;

    // Calculate trip details
    const distanceKm = calculateDistance(
      pickupLocation.latitude,
      pickupLocation.longitude,
      destinationLocation.latitude,
      destinationLocation.longitude
    );

    const estimatedDurationMinutes = calculateDuration(distanceKm);
    const priceDA = calculatePrice(distanceKm);

    // Create trip in database
    const { data: trip, error } = await supabase
      .from('trips')
      .insert({
        user_id: userId,
        rider_id: riderId || null,
        pickup_location: `POINT(${pickupLocation.longitude} ${pickupLocation.latitude})`,
        pickup_address: pickupAddress,
        destination_location: `POINT(${destinationLocation.longitude} ${destinationLocation.latitude})`,
        destination_address: destinationAddress,
        distance_km: Math.round(distanceKm * 100) / 100,
        estimated_duration_minutes: estimatedDurationMinutes,
        price_da: priceDA,
        status: 'pending'
      })
      .select()
      .single();

    if (error) {
      return res.status(500).json({
        error: 'Database error',
        message: error.message
      });
    }

    res.status(201).json({
      success: true,
      message: 'Trip created successfully',
      trip: {
        id: trip.id,
        userId: trip.user_id,
        riderId: trip.rider_id,
        pickupLocation,
        pickupAddress: trip.pickup_address,
        destinationLocation,
        destinationAddress: trip.destination_address,
        distanceKm: trip.distance_km,
        estimatedDurationMinutes: trip.estimated_duration_minutes,
        priceDA: trip.price_da,
        status: trip.status,
        requestedAt: trip.requested_at
      }
    });
  } catch (error) {
    console.error('Create trip error:', error);
    res.status(500).json({
      error: 'Internal server error',
      message: 'Failed to create trip'
    });
  }
});

// Get user trips
router.get('/', async (req, res) => {
  try {
    const userId = req.user.id;
    const { status, limit = 50, offset = 0 } = req.query;

    let query = supabase
      .from('trips')
      .select(`
        *,
        motards (
          nom_complet,
          rating_average,
          num_tel
        )
      `)
      .eq('user_id', userId)
      .order('created_at', { ascending: false })
      .range(parseInt(offset), parseInt(offset) + parseInt(limit) - 1);

    if (status) {
      query = query.eq('status', status);
    }

    const { data: trips, error } = await query;

    if (error) {
      return res.status(500).json({
        error: 'Database error',
        message: error.message
      });
    }

    const formattedTrips = trips.map(trip => {
      // Parse locations
      const pickupLocation = trip.pickup_location 
        ? (() => {
            const coords = trip.pickup_location.substring(6, trip.pickup_location.length - 1);
            const [lng, lat] = coords.split(' ').map(Number);
            return { latitude: lat, longitude: lng };
          })()
        : null;

      const destinationLocation = trip.destination_location
        ? (() => {
            const coords = trip.destination_location.substring(6, trip.destination_location.length - 1);
            const [lng, lat] = coords.split(' ').map(Number);
            return { latitude: lat, longitude: lng };
          })()
        : null;

      return {
        id: trip.id,
        pickupLocation,
        pickupAddress: trip.pickup_address,
        destinationLocation,
        destinationAddress: trip.destination_address,
        distanceKm: trip.distance_km,
        estimatedDurationMinutes: trip.estimated_duration_minutes,
        priceDA: trip.price_da,
        status: trip.status,
        requestedAt: trip.requested_at,
        startedAt: trip.started_at,
        completedAt: trip.completed_at,
        rider: trip.motards ? {
          name: trip.motards.nom_complet,
          rating: trip.motards.rating_average,
          phone: trip.motards.num_tel
        } : null
      };
    });

    res.status(200).json({
      success: true,
      trips: formattedTrips,
      count: formattedTrips.length
    });
  } catch (error) {
    console.error('Get trips error:', error);
    res.status(500).json({
      error: 'Internal server error',
      message: 'Failed to fetch trips'
    });
  }
});

// Get trip by ID
router.get('/:tripId', async (req, res) => {
  try {
    const { tripId } = req.params;
    const userId = req.user.id;

    const { data: trip, error } = await supabase
      .from('trips')
      .select(`
        *,
        motards (
          nom_complet,
          rating_average,
          num_tel,
          vehicle_type,
          license_plate
        )
      `)
      .eq('id', tripId)
      .eq('user_id', userId)
      .single();

    if (error) {
      if (error.code === 'PGRST116') {
        return res.status(404).json({
          error: 'Trip not found',
          message: 'The specified trip does not exist'
        });
      }
      return res.status(500).json({
        error: 'Database error',
        message: error.message
      });
    }

    // Parse locations
    const pickupLocation = trip.pickup_location 
      ? (() => {
          const coords = trip.pickup_location.substring(6, trip.pickup_location.length - 1);
          const [lng, lat] = coords.split(' ').map(Number);
          return { latitude: lat, longitude: lng };
        })()
      : null;

    const destinationLocation = trip.destination_location
      ? (() => {
          const coords = trip.destination_location.substring(6, trip.destination_location.length - 1);
          const [lng, lat] = coords.split(' ').map(Number);
          return { latitude: lat, longitude: lng };
        })()
      : null;

    res.status(200).json({
      success: true,
      trip: {
        id: trip.id,
        pickupLocation,
        pickupAddress: trip.pickup_address,
        destinationLocation,
        destinationAddress: trip.destination_address,
        distanceKm: trip.distance_km,
        estimatedDurationMinutes: trip.estimated_duration_minutes,
        priceDA: trip.price_da,
        status: trip.status,
        requestedAt: trip.requested_at,
        startedAt: trip.started_at,
        completedAt: trip.completed_at,
        rider: trip.motards ? {
          name: trip.motards.nom_complet,
          rating: trip.motards.rating_average,
          phone: trip.motards.num_tel,
          vehicleType: trip.motards.vehicle_type,
          licensePlate: trip.motards.license_plate
        } : null
      }
    });
  } catch (error) {
    console.error('Get trip error:', error);
    res.status(500).json({
      error: 'Internal server error',
      message: 'Failed to fetch trip details'
    });
  }
});

// Update trip status
router.patch('/:tripId/status', async (req, res) => {
  try {
    const { tripId } = req.params;
    const { status } = req.body;
    const userId = req.user.id;

    const validStatuses = ['pending', 'accepted', 'in_progress', 'completed', 'cancelled'];
    if (!validStatuses.includes(status)) {
      return res.status(400).json({
        error: 'Invalid status',
        message: 'Status must be one of: ' + validStatuses.join(', ')
      });
    }

    const updateData = {
      status,
      updated_at: new Date().toISOString()
    };

    // Add timestamps based on status
    if (status === 'in_progress') {
      updateData.started_at = new Date().toISOString();
    } else if (status === 'completed') {
      updateData.completed_at = new Date().toISOString();
    }

    const { data: trip, error } = await supabase
      .from('trips')
      .update(updateData)
      .eq('id', tripId)
      .eq('user_id', userId)
      .select()
      .single();

    if (error) {
      return res.status(500).json({
        error: 'Database error',
        message: error.message
      });
    }

    res.status(200).json({
      success: true,
      message: 'Trip status updated successfully',
      trip: {
        id: trip.id,
        status: trip.status,
        updatedAt: trip.updated_at,
        startedAt: trip.started_at,
        completedAt: trip.completed_at
      }
    });
  } catch (error) {
    console.error('Update trip status error:', error);
    res.status(500).json({
      error: 'Internal server error',
      message: 'Failed to update trip status'
    });
  }
});

// Cancel trip
router.delete('/:tripId', async (req, res) => {
  try {
    const { tripId } = req.params;
    const userId = req.user.id;

    const { data: trip, error } = await supabase
      .from('trips')
      .update({
        status: 'cancelled',
        updated_at: new Date().toISOString()
      })
      .eq('id', tripId)
      .eq('user_id', userId)
      .select()
      .single();

    if (error) {
      return res.status(500).json({
        error: 'Database error',
        message: error.message
      });
    }

    res.status(200).json({
      success: true,
      message: 'Trip cancelled successfully',
      trip: {
        id: trip.id,
        status: trip.status,
        updatedAt: trip.updated_at
      }
    });
  } catch (error) {
    console.error('Cancel trip error:', error);
    res.status(500).json({
      error: 'Internal server error',
      message: 'Failed to cancel trip'
    });
  }
});

// Rate a completed trip
router.post('/:tripId/rating', async (req, res) => {
  try {
    const { tripId } = req.params;
    const { rating, comment } = req.body;
    const userId = req.user.id;

    if (!rating || rating < 1 || rating > 5) {
      return res.status(400).json({
        error: 'Invalid rating',
        message: 'Rating must be between 1 and 5'
      });
    }

    // Check if trip exists and is completed
    const { data: trip, error: tripError } = await supabase
      .from('trips')
      .select('rider_id, status')
      .eq('id', tripId)
      .eq('user_id', userId)
      .single();

    if (tripError || !trip) {
      return res.status(404).json({
        error: 'Trip not found',
        message: 'The specified trip does not exist'
      });
    }

    if (trip.status !== 'completed') {
      return res.status(400).json({
        error: 'Trip not completed',
        message: 'You can only rate completed trips'
      });
    }

    // Create rating
    const { data: ratingData, error: ratingError } = await supabase
      .from('ratings')
      .insert({
        trip_id: tripId,
        user_id: userId,
        rider_id: trip.rider_id,
        rating: parseInt(rating),
        comment: comment || null
      })
      .select()
      .single();

    if (ratingError) {
      return res.status(500).json({
        error: 'Database error',
        message: ratingError.message
      });
    }

    res.status(201).json({
      success: true,
      message: 'Rating submitted successfully',
      rating: {
        id: ratingData.id,
        rating: ratingData.rating,
        comment: ratingData.comment,
        createdAt: ratingData.created_at
      }
    });
  } catch (error) {
    console.error('Rate trip error:', error);
    res.status(500).json({
      error: 'Internal server error',
      message: 'Failed to submit rating'
    });
  }
});

module.exports = router;