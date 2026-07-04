const mongoose = require('mongoose');

const SalaryHistorySchema = new mongoose.Schema({
  salaryId: { type: mongoose.Schema.Types.ObjectId, ref: 'Salary', required: true },
  employeeId: { type: mongoose.Schema.Types.ObjectId, ref: 'Employee', required: true },
  month: { type: String, required: true },
  snapshot: { type: Object, required: true },
  payslipUrl: String,
  createdAt: { type: Date, default: Date.now }
});

module.exports = mongoose.model('SalaryHistory', SalaryHistorySchema);
