/**
 * Seed script: creates an initial admin account and company settings if none exist.
 * Run with: node src/scripts/seed.js
 */
require('dotenv').config({ path: require('path').resolve(__dirname, '../../.env') });
const mongoose = require('mongoose');
const bcrypt = require('bcrypt');

async function seed() {
  const MONGO_URI = process.env.MONGO_URI || 'mongodb://localhost:27017/ems';
  await mongoose.connect(MONGO_URI);
  console.log('Connected to MongoDB');

  const Admin = require('../models/admin.model');
  const CompanySettings = require('../models/companySettings.model');
  const LeaveType = require('../models/leaveType.model');

  // Create admin if none exists
  const adminCount = await Admin.countDocuments();
  if (adminCount === 0) {
    const passwordHash = await bcrypt.hash('admin123', 10);
    await Admin.create({
      fullName: 'System Admin',
      email: 'admin@company.com',
      passwordHash,
    });
    console.log('Admin created: admin@company.com / admin123');
  } else {
    console.log('Admin already exists, skipping.');
  }

  // Create company settings if none exist
  const settingsCount = await CompanySettings.countDocuments();
  if (settingsCount === 0) {
    await CompanySettings.create({
      companyName: 'My Company Pvt. Ltd.',
      address: 'Kathmandu, Nepal',
      phone: '01-4000000',
      email: 'info@company.com',
      currency: 'NPR',
      workingHours: { start: '09:00', end: '17:00' },
      taxPercentage: 0,
      overtimeMultiplier: 1.5,
      gracePeriodMinutes: 10,
    });
    console.log('Company settings created');
  } else {
    console.log('Company settings already exist, skipping.');
  }

  // Create default leave types if none exist
  const leaveTypeCount = await LeaveType.countDocuments();
  if (leaveTypeCount === 0) {
    await LeaveType.insertMany([
      { name: 'Annual', maxDaysPerYear: 18, isPaid: true },
      { name: 'Sick', maxDaysPerYear: 12, isPaid: true },
      { name: 'Casual', maxDaysPerYear: 6, isPaid: false },
      { name: 'Emergency', maxDaysPerYear: 3, isPaid: false },
    ]);
    console.log('Default leave types created');
  } else {
    console.log('Leave types already exist, skipping.');
  }

  await mongoose.disconnect();
  console.log('Done.');
}

seed().catch(err => {
  console.error('Seed failed:', err);
  process.exit(1);
});
