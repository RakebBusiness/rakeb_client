const express = require('express');
const { supabase } = require('../config/database');

const router = express.Router();

// Get active promotions
router.get('/', async (req, res) => {
  try {
    const { data: promotions, error } = await supabase
      .from('promotions')
      .select('*')
      .eq('is_active', true)
      .gte('valid_until', new Date().toISOString())
      .order('created_at', { ascending: false });

    if (error) {
      return res.status(500).json({
        error: 'Database error',
        message: error.message
      });
    }

    const formattedPromotions = promotions.map(promo => ({
      id: promo.id,
      title: promo.title,
      description: promo.description,
      discountPercentage: promo.discount_percentage,
      discountAmount: promo.discount_amount,
      validFrom: promo.valid_from,
      validUntil: promo.valid_until,
      isActive: promo.is_active,
      createdAt: promo.created_at
    }));

    res.status(200).json({
      success: true,
      promotions: formattedPromotions,
      count: formattedPromotions.length
    });
  } catch (error) {
    console.error('Get promotions error:', error);
    res.status(500).json({
      error: 'Internal server error',
      message: 'Failed to fetch promotions'
    });
  }
});

// Get promotion by ID
router.get('/:promotionId', async (req, res) => {
  try {
    const { promotionId } = req.params;

    const { data: promotion, error } = await supabase
      .from('promotions')
      .select('*')
      .eq('id', promotionId)
      .single();

    if (error) {
      if (error.code === 'PGRST116') {
        return res.status(404).json({
          error: 'Promotion not found',
          message: 'The specified promotion does not exist'
        });
      }
      return res.status(500).json({
        error: 'Database error',
        message: error.message
      });
    }

    res.status(200).json({
      success: true,
      promotion: {
        id: promotion.id,
        title: promotion.title,
        description: promotion.description,
        discountPercentage: promotion.discount_percentage,
        discountAmount: promotion.discount_amount,
        validFrom: promotion.valid_from,
        validUntil: promotion.valid_until,
        isActive: promotion.is_active,
        createdAt: promotion.created_at
      }
    });
  } catch (error) {
    console.error('Get promotion error:', error);
    res.status(500).json({
      error: 'Internal server error',
      message: 'Failed to fetch promotion details'
    });
  }
});

// Check if user is eligible for a promotion
router.get('/:promotionId/eligibility', async (req, res) => {
  try {
    const { promotionId } = req.params;
    const userId = req.user.id;

    // Get promotion details
    const { data: promotion, error: promoError } = await supabase
      .from('promotions')
      .select('*')
      .eq('id', promotionId)
      .single();

    if (promoError || !promotion) {
      return res.status(404).json({
        error: 'Promotion not found',
        message: 'The specified promotion does not exist'
      });
    }

    // Check if promotion is active and valid
    const now = new Date();
    const validFrom = new Date(promotion.valid_from);
    const validUntil = new Date(promotion.valid_until);

    if (!promotion.is_active || now < validFrom || now > validUntil) {
      return res.status(200).json({
        success: true,
        eligible: false,
        reason: 'Promotion is not currently active'
      });
    }

    // Check user's trip history for specific promotion rules
    const { data: userTrips, error: tripsError } = await supabase
      .from('trips')
      .select('id, status')
      .eq('user_id', userId);

    if (tripsError) {
      return res.status(500).json({
        error: 'Database error',
        message: tripsError.message
      });
    }

    let eligible = true;
    let reason = '';

    // Example: First ride promotion - user should have no completed trips
    if (promotion.title.toLowerCase().includes('first ride')) {
      const completedTrips = userTrips.filter(trip => trip.status === 'completed');
      if (completedTrips.length > 0) {
        eligible = false;
        reason = 'This promotion is only for first-time users';
      }
    }

    // Example: Loyalty bonus - user should have completed at least 10 trips
    if (promotion.title.toLowerCase().includes('loyalty')) {
      const completedTrips = userTrips.filter(trip => trip.status === 'completed');
      if (completedTrips.length < 10) {
        eligible = false;
        reason = `Complete ${10 - completedTrips.length} more trips to unlock this promotion`;
      }
    }

    res.status(200).json({
      success: true,
      eligible,
      reason: eligible ? 'You are eligible for this promotion' : reason,
      promotion: {
        id: promotion.id,
        title: promotion.title,
        discountPercentage: promotion.discount_percentage,
        discountAmount: promotion.discount_amount
      }
    });
  } catch (error) {
    console.error('Check promotion eligibility error:', error);
    res.status(500).json({
      error: 'Internal server error',
      message: 'Failed to check promotion eligibility'
    });
  }
});

// Apply promotion to a trip (calculate discount)
router.post('/:promotionId/apply', async (req, res) => {
  try {
    const { promotionId } = req.params;
    const { tripPrice } = req.body;
    const userId = req.user.id;

    if (!tripPrice || tripPrice <= 0) {
      return res.status(400).json({
        error: 'Invalid trip price',
        message: 'Trip price must be a positive number'
      });
    }

    // Get promotion details
    const { data: promotion, error: promoError } = await supabase
      .from('promotions')
      .select('*')
      .eq('id', promotionId)
      .single();

    if (promoError || !promotion) {
      return res.status(404).json({
        error: 'Promotion not found',
        message: 'The specified promotion does not exist'
      });
    }

    // Check eligibility (reuse logic from eligibility endpoint)
    const now = new Date();
    const validFrom = new Date(promotion.valid_from);
    const validUntil = new Date(promotion.valid_until);

    if (!promotion.is_active || now < validFrom || now > validUntil) {
      return res.status(400).json({
        error: 'Promotion not valid',
        message: 'This promotion is not currently active'
      });
    }

    // Calculate discount
    let discountAmount = 0;
    
    if (promotion.discount_percentage) {
      discountAmount = Math.round((tripPrice * promotion.discount_percentage) / 100);
    } else if (promotion.discount_amount) {
      discountAmount = Math.min(promotion.discount_amount, tripPrice);
    }

    const finalPrice = Math.max(0, tripPrice - discountAmount);

    res.status(200).json({
      success: true,
      discount: {
        promotionId: promotion.id,
        promotionTitle: promotion.title,
        originalPrice: tripPrice,
        discountAmount,
        finalPrice,
        savings: discountAmount
      }
    });
  } catch (error) {
    console.error('Apply promotion error:', error);
    res.status(500).json({
      error: 'Internal server error',
      message: 'Failed to apply promotion'
    });
  }
});

module.exports = router;