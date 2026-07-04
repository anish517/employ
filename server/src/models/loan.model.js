const mongoose = require('mongoose');

const LoanSchema = new mongoose.Schema({
  employeeId: { type: mongoose.Schema.Types.ObjectId, ref: 'Employee', required: true },
  totalAmount: { type: Number, required: true },
  emiAmount: { type: Number, required: true },
  status: { type: String, default: 'Active' },
  startDate: Date,
  createdAt: { type: Date, default: Date.now }
});

module.exports = mongoose.model('Loan', LoanSchema);
