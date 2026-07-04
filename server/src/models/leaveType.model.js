const mongoose = require('mongoose');

const LeaveTypeSchema = new mongoose.Schema({
  name: { type: String, required: true },
  maxDaysPerYear: Number,
  isPaid: { type: Boolean, default: true }
});

module.exports = mongoose.model('LeaveType', LeaveTypeSchema);
