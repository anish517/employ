const mongoose = require('mongoose');

const AttendanceSchema = new mongoose.Schema({
  employeeId: { type: mongoose.Schema.Types.ObjectId, ref: 'Employee', required: true },
  date: { type: Date, required: true },
  status: String,
  checkIn: Date,
  checkOut: Date,
  workingHours: { type: Number, default: 0 },
  overtimeHours: { type: Number, default: 0 },
  isLate: { type: Boolean, default: false },
  createdAt: { type: Date, default: Date.now }
});

AttendanceSchema.index({ employeeId: 1, date: 1 }, { unique: true });

module.exports = mongoose.model('Attendance', AttendanceSchema);
