const { body, param, query, validationResult } = require('express-validator');

const handleValidationErrors = (req, res, next) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({
      error: 'Validation failed',
      details: errors.array()
    });
  }
  next();
};

// Phone number validation for Algeria
const validateAlgerianPhone = (phone) => {
  const cleanPhone = phone.replace(/[\s\-\(\)]/g, '');
  
  // Check various valid formats
  const patterns = [
    /^0[567]\d{8}$/, // 0512345678
    /^[567]\d{8}$/, // 512345678
    /^\+213[567]\d{8}$/ // +213512345678
  ];
  
  return patterns.some(pattern => pattern.test(cleanPhone));
};

const authValidation = {
  requestOTP: [
    body('phoneNumber')
      .notEmpty()
      .withMessage('Phone number is required')
      .custom(validateAlgerianPhone)
      .withMessage('Invalid Algerian phone number format'),
    handleValidationErrors
  ],
  
  verifyOTP: [
    body('phoneNumber')
      .notEmpty()
      .withMessage('Phone number is required')
      .custom(validateAlgerianPhone)
      .withMessage('Invalid Algerian phone number format'),
    body('otpCode')
      .isLength({ min: 6, max: 6 })
      .withMessage('OTP code must be 6 digits')
      .isNumeric()
      .withMessage('OTP code must contain only numbers'),
    handleValidationErrors
  ],
  
  updateProfile: [
    body('displayName')
      .notEmpty()
      .withMessage('Display name is required')
      .isLength({ min: 2, max: 50 })
      .withMessage('Display name must be between 2 and 50 characters'),
    handleValidationErrors
  ]
};

const locationValidation = {
  coordinates: [
    body('latitude')
      .isFloat({ min: -90, max: 90 })
      .withMessage('Invalid latitude'),
    body('longitude')
      .isFloat({ min: -180, max: 180 })
      .withMessage('Invalid longitude'),
    handleValidationErrors
  ],
  
  search: [
    query('query')
      .notEmpty()
      .withMessage('Search query is required')
      .isLength({ min: 3 })
      .withMessage('Search query must be at least 3 characters'),
    handleValidationErrors
  ]
};

const tripValidation = {
  create: [
    body('pickupLocation.latitude')
      .isFloat({ min: -90, max: 90 })
      .withMessage('Invalid pickup latitude'),
    body('pickupLocation.longitude')
      .isFloat({ min: -180, max: 180 })
      .withMessage('Invalid pickup longitude'),
    body('destinationLocation.latitude')
      .isFloat({ min: -90, max: 90 })
      .withMessage('Invalid destination latitude'),
    body('destinationLocation.longitude')
      .isFloat({ min: -180, max: 180 })
      .withMessage('Invalid destination longitude'),
    body('pickupAddress')
      .notEmpty()
      .withMessage('Pickup address is required'),
    body('destinationAddress')
      .notEmpty()
      .withMessage('Destination address is required'),
    handleValidationErrors
  ]
};

const riderValidation = {
  nearby: [
    query('latitude')
      .isFloat({ min: -90, max: 90 })
      .withMessage('Invalid latitude'),
    query('longitude')
      .isFloat({ min: -180, max: 180 })
      .withMessage('Invalid longitude'),
    query('radius')
      .optional()
      .isFloat({ min: 1, max: 100 })
      .withMessage('Radius must be between 1 and 100 km'),
    handleValidationErrors
  ]
};

module.exports = {
  authValidation,
  locationValidation,
  tripValidation,
  riderValidation,
  handleValidationErrors
};