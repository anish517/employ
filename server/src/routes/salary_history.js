const express = require('express');
const router = express.Router();
const SalaryHistory = require('../models/salaryHistory.model');
const Salary = require('../models/salary.model');

// GET /api/salary-history?employeeId=&year=
router.get('/', async (req, res, next) => {
  try {
    const { employeeId, year } = req.query;
    const q = {};
    if (employeeId) q.employeeId = employeeId;
    if (year) {
      // Filter by year prefix in month field (YYYY-MM)
      q.month = new RegExp(`^${year}-`);
    }
    const docs = await SalaryHistory.find(q).sort({ month: -1 });
    res.json({ success: true, data: docs });
  } catch (err) { next(err); }
});

// GET /api/salary-history/:id
router.get('/:id', async (req, res, next) => {
  try {
    const doc = await SalaryHistory.findById(req.params.id);
    if (!doc) return res.status(404).json({ success: false, error: { code: 'NOT_FOUND', message: 'Record not found' } });
    res.json({ success: true, data: doc });
  } catch (err) { next(err); }
});

// GET /api/salary-history/:id/payslip — re-download payslip from snapshot
router.get('/:id/payslip', async (req, res, next) => {
  try {
    const doc = await SalaryHistory.findById(req.params.id);
    if (!doc) return res.status(404).json({ success: false, error: { code: 'NOT_FOUND', message: 'Record not found' } });

    const PDFDocument = require('pdfkit');
    const Employee = require('../models/employee.model');

    const snapshot = doc.snapshot || {};
    let empName = 'Employee';
    try {
      const emp = await Employee.findById(doc.employeeId);
      if (emp) empName = emp.fullName;
    } catch (e) {}

    res.setHeader('Content-Type', 'application/pdf');
    res.setHeader('Content-Disposition', `attachment; filename=payslip-${doc.month}.pdf`);

    const pdf = new PDFDocument({ margin: 50 });
    pdf.pipe(res);

    pdf.fontSize(20).text('PAYSLIP', { align: 'center' });
    pdf.moveDown(0.5);
    pdf.fontSize(12).text(`Employee: ${empName}`, { align: 'center' });
    pdf.text(`Month: ${doc.month}`, { align: 'center' });
    pdf.moveDown(1);
    pdf.moveTo(50, pdf.y).lineTo(550, pdf.y).stroke();
    pdf.moveDown(0.5);

    const s = snapshot;
    pdf.text(`Hourly Rate: ${s.hourlyRate || 0}`);
    pdf.text(`Regular Hours: ${s.regularHours || 0}`);
    pdf.text(`Overtime Hours: ${s.overtimeHours || 0}`);
    pdf.moveDown(0.5);
    pdf.text(`Regular Pay: ${s.regularPay || 0}`);
    pdf.text(`Overtime Pay: ${s.overtimePay || 0}`);
    pdf.text(`Allowances: ${s.allowances || 0}`);
    pdf.text(`Bonus Total: ${s.bonusTotal || 0}`);
    pdf.text(`Gross Salary: ${s.grossSalary || 0}`);
    pdf.moveDown(0.5);
    pdf.text('--- Deductions ---');
    if (s.deductions) {
      Object.entries(s.deductions).forEach(([k, v]) => {
        pdf.text(`  ${k}: ${v || 0}`);
      });
    }
    pdf.moveDown(0.5);
    pdf.fontSize(14).text(`Net Salary: ${s.netSalary || 0}`, { underline: true });

    pdf.end();
  } catch (err) { next(err); }
});

module.exports = router;
