const mongoose = require('mongoose');

const CompanySettingsSchema = new mongoose.Schema({
  companyName: String,
  logo: String,
  address: String,
  phone: String,
  email: String,
  currency: { type: String, default: 'NPR' },
  workingHours: { start: String, end: String },
  taxPercentage: { type: Number, default: 0 },
  overtimeMultiplier: { type: Number, default: 1.5 }
});

module.exports = mongoose.model('CompanySettings', CompanySettingsSchema);
