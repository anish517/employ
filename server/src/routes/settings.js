const express = require('express');
const router = express.Router();
const CompanySettings = require('../models/companySettings.model');
const Admin = require('../models/admin.model');
const bcrypt = require('bcrypt');

// GET /api/settings
router.get('/', async (req, res, next) => {
  try {
    let settings = await CompanySettings.findOne();
    if (!settings) {
      settings = await CompanySettings.create({
        companyName: 'My Company',
        currency: 'NPR',
        workingHours: { start: '09:00', end: '17:00' },
        taxPercentage: 0,
        overtimeMultiplier: 1.5,
        gracePeriodMinutes: 10
      });
    }
    res.json({ success: true, data: settings });
  } catch (err) { next(err); }
});

// PUT /api/settings
router.put('/', async (req, res, next) => {
  try {
    let settings = await CompanySettings.findOne();
    if (!settings) {
      settings = await CompanySettings.create(req.body);
    } else {
      Object.assign(settings, req.body);
      await settings.save();
    }
    res.json({ success: true, data: settings });
  } catch (err) { next(err); }
});

// GET /api/settings/profile — admin profile
router.get('/profile', async (req, res, next) => {
  try {
    const admin = await Admin.findById(req.admin._id).select('-passwordHash');
    res.json({ success: true, data: admin });
  } catch (err) { next(err); }
});

// PUT /api/settings/profile
router.put('/profile', async (req, res, next) => {
  try {
    const { fullName, email, profilePhoto } = req.body;
    const admin = await Admin.findByIdAndUpdate(
      req.admin._id,
      { fullName, email, profilePhoto },
      { new: true }
    ).select('-passwordHash');
    res.json({ success: true, data: admin });
  } catch (err) { next(err); }
});

module.exports = router;
