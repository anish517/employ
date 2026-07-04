const mongoose = require('mongoose');

const SalarySchema = new mongoose.Schema({
  employeeId: { type: mongoose.Schema.Types.ObjectId, ref: 'Employee', required: true },
  month: { type: String, required: true },
  hourlyRate: Number,
  regularHours: Number,
  overtimeHours: Number,
  overtimeMultiplier: Number,
  regularPay: Number,
  overtimePay: Number,
  allowances: Number,
  bonusTotal: Number,
  grossSalary: Number,
  deductions: { type: Object, default: {} },
  netSalary: Number,
  status: { type: String, default: 'Draft' },
  generatedAt: { type: Date, default: Date.now }
});

SalarySchema.index({ employeeId: 1, month: 1 }, { unique: true });

module.exports = mongoose.model('Salary', SalarySchema);
