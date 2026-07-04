const mongoose = require('mongoose');

const BonusSchema = new mongoose.Schema({
  employeeId: { type: mongoose.Schema.Types.ObjectId, ref: 'Employee', required: true },
  type: String,
  amount: { type: Number, required: true },
  reason: String,
  month: { type: String, required: true },
  createdAt: { type: Date, default: Date.now }
});

module.exports = mongoose.model('Bonus', BonusSchema);
