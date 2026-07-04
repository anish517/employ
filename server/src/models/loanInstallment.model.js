const mongoose = require('mongoose');

const LoanInstallmentSchema = new mongoose.Schema({
  loanId: { type: mongoose.Schema.Types.ObjectId, ref: 'Loan', required: true },
  month: { type: String, required: true },
  amountPaid: { type: Number, required: true },
  paidOn: { type: Date, default: Date.now }
});

module.exports = mongoose.model('LoanInstallment', LoanInstallmentSchema);
