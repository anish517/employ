const express = require('express');
const router = express.Router();
const payroll = require('../services/payroll.service');
const Salary = require('../models/salary.model');

// POST /api/salary/generate
router.post('/generate', async (req, res, next) => {
  try {
    const { employeeId, month } = req.body;
    if (!employeeId || !month) return res.status(400).json({ success: false, error: { code: 'VALIDATION_ERROR', message: 'employeeId and month are required' } });
    const adminId = req.admin ? req.admin._id : null;
    const salary = await payroll.generateSalary(employeeId, month, adminId);
    res.status(201).json({
      success: true,
      data: {
        salaryId: salary._id,
        netSalary: salary.netSalary,
        grossSalary: salary.grossSalary,
        payslipUrl: `/api/salary/${salary._id}/payslip`
      },
      warnings: []
    });
  } catch (err) {
    next(err);
  }
});

// GET /api/salary?month=&employeeId=
router.get('/', async (req, res, next) => {
  try {
    const { month, employeeId, page = 1, limit = 20 } = req.query;
    const q = {};
    if (month) q.month = month;
    if (employeeId) q.employeeId = employeeId;
    const skip = (page - 1) * limit;
    const docs = await Salary.find(q).sort({ month: -1 }).skip(skip).limit(Number(limit));
    const total = await Salary.countDocuments(q);
    res.json({ success: true, data: docs, meta: { total, page: Number(page), totalPages: Math.ceil(total / limit) } });
  } catch (err) { next(err); }
});

// GET /api/salary/:id
router.get('/:id', async (req, res, next) => {
  try {
    const doc = await Salary.findById(req.params.id);
    if (!doc) return res.status(404).json({ success: false, error: { code: 'NOT_FOUND', message: 'Salary record not found' } });
    res.json({ success: true, data: doc });
  } catch (err) { next(err); }
});

// Mount payslip route
router.use('/', require('./salary_payslip'));

module.exports = router;
