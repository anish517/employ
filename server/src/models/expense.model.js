const mongoose = require('mongoose');

const ExpenseSchema = new mongoose.Schema({
  category: { type: String, required: true },
  description: String,
  amount: { type: Number, required: true },
  date: { type: Date, default: Date.now },
  createdAt: { type: Date, default: Date.now }
});

module.exports = mongoose.model('Expense', ExpenseSchema);
