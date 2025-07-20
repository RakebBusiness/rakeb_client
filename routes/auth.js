const express = require('express');
const { supabase } = require('../config/database');
const { authValidation } = require('../middleware/validation');
const { authenticateToken } = require('../middleware/auth');

const router = express.Router();

// Format phone number for Algeria
const formatPhoneNumber = (phone) => {
  const cleanPhone = phone.replace(/[\s\-\(\)]/g, '');
  
  if (cleanPhone.startsWith('+213')) {
    return cleanPhone;
  } else if (cleanPhone.startsWith('213')) {
    return `+${cleanPhone}`;
  } else if (cleanPhone.startsWith('0')) {
    return `+213${cleanPhone.substring(1)}`;
  } else if (cleanPhone.length === 9 && /^[567]/.test(cleanPhone)) {
    return `+213${cleanPhone}`;
  }
  
  return `+213${cleanPhone}`;
};

// Request OTP
router.post('/request-otp', authValidation.requestOTP, async (req, res) => {
  try {
    const { phoneNumber } = req.body;
    const formattedPhone = formatPhoneNumber(phoneNumber);

    const { error } = await supabase.auth.signInWithOtp({
      phone: formattedPhone
    });

    if (error) {
      return res.status(400).json({
        error: 'Failed to send OTP',
        message: error.message
      });
    }

    res.status(200).json({
      success: true,
      message: 'OTP sent successfully',
      phoneNumber: formattedPhone
    });
  } catch (error) {
    console.error('Request OTP error:', error);
    res.status(500).json({
      error: 'Internal server error',
      message: 'Failed to process OTP request'
    });
  }
});

// Verify OTP
router.post('/verify-otp', authValidation.verifyOTP, async (req, res) => {
  try {
    const { phoneNumber, otpCode } = req.body;
    const formattedPhone = formatPhoneNumber(phoneNumber);

    const { data, error } = await supabase.auth.verifyOtp({
      phone: formattedPhone,
      token: otpCode,
      type: 'sms'
    });

    if (error) {
      return res.status(400).json({
        error: 'OTP verification failed',
        message: error.message
      });
    }

    if (!data.user || !data.session) {
      return res.status(400).json({
        error: 'Verification failed',
        message: 'Invalid OTP or phone number'
      });
    }

    res.status(200).json({
      success: true,
      message: 'OTP verified successfully',
      user: {
        id: data.user.id,
        phone: data.user.phone,
        displayName: data.user.user_metadata?.display_name || null
      },
      session: {
        accessToken: data.session.access_token,
        refreshToken: data.session.refresh_token,
        expiresAt: data.session.expires_at
      }
    });
  } catch (error) {
    console.error('Verify OTP error:', error);
    res.status(500).json({
      error: 'Internal server error',
      message: 'Failed to verify OTP'
    });
  }
});

// Update user profile
router.patch('/profile', authenticateToken, authValidation.updateProfile, async (req, res) => {
  try {
    const { displayName } = req.body;
    const userId = req.user.id;

    const { data, error } = await supabase.auth.admin.updateUserById(userId, {
      user_metadata: { display_name: displayName }
    });

    if (error) {
      return res.status(400).json({
        error: 'Profile update failed',
        message: error.message
      });
    }

    res.status(200).json({
      success: true,
      message: 'Profile updated successfully',
      user: {
        id: data.user.id,
        phone: data.user.phone,
        displayName: data.user.user_metadata?.display_name
      }
    });
  } catch (error) {
    console.error('Update profile error:', error);
    res.status(500).json({
      error: 'Internal server error',
      message: 'Failed to update profile'
    });
  }
});

// Get current user
router.get('/me', authenticateToken, async (req, res) => {
  try {
    const user = req.user;

    res.status(200).json({
      success: true,
      user: {
        id: user.id,
        phone: user.phone,
        displayName: user.user_metadata?.display_name || null,
        createdAt: user.created_at
      }
    });
  } catch (error) {
    console.error('Get user error:', error);
    res.status(500).json({
      error: 'Internal server error',
      message: 'Failed to get user information'
    });
  }
});

// Sign out
router.post('/signout', authenticateToken, async (req, res) => {
  try {
    const { error } = await supabase.auth.signOut();

    if (error) {
      return res.status(400).json({
        error: 'Sign out failed',
        message: error.message
      });
    }

    res.status(200).json({
      success: true,
      message: 'Signed out successfully'
    });
  } catch (error) {
    console.error('Sign out error:', error);
    res.status(500).json({
      error: 'Internal server error',
      message: 'Failed to sign out'
    });
  }
});

module.exports = router;