const mongoose = require('mongoose');

const EmployeeSchema = new mongoose.Schema({
  employeeId: { type: String, unique: true },
  fullName: { type: String, required: true },
  profilePhoto: String,
  gender: String,
  dateOfBirth: Date,
  phone: { type: String, required: true },
  email: { type: String },
  address: String,
  emergencyContact: {
    name: String, phone: String, relation: String
  },
  departmentId: { type: mongoose.Schema.Types.ObjectId, ref: 'Department' },
  designationId: { type: mongoose.Schema.Types.ObjectId, ref: 'Designation' },
  joiningDate: Date,
  employmentType: String,
  hourlyRate: { type: Number, required: true },
  status: { type: String, default: 'Active' },
  createdAt: { type: Date, default: Date.now },
  updatedAt: { type: Date, default: Date.now }
});

module.exports = mongoose.model('Employee', EmployeeSchema);
