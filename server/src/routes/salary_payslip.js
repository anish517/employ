const express = require('express');
const router = express.Router();
const Salary = require('../models/salary.model');
const SalaryHistory = require('../models/salaryHistory.model');
const PDFDocument = require('pdfkit');

// GET /api/salary/:id/payslip
router.get('/:id/payslip', async (req,res,next)=>{
  try{
    const salary = await Salary.findById(req.params.id).populate('employeeId');
    if(!salary) return res.status(404).json({ success:false, error:{ code:'NOT_FOUND', message:'Salary not found' } });

    res.setHeader('Content-Type', 'application/pdf');
    res.setHeader('Content-Disposition', `attachment; filename="payslip_${salary.employeeId._id}_${salary.month}.pdf"`);

    const doc = new PDFDocument();
    doc.pipe(res);
    doc.fontSize(18).text('Payslip', { align: 'center' });
    doc.moveDown();
    doc.fontSize(12).text(`Employee: ${salary.employeeId.fullName}`);
    doc.text(`Month: ${salary.month}`);
    doc.text(`Net Salary: ${salary.netSalary}`);
    doc.moveDown();
    doc.text('Breakdown:');
    doc.text(`Regular Hours: ${salary.regularHours}`);
    doc.text(`Overtime Hours: ${salary.overtimeHours}`);
    doc.text(`Regular Pay: ${salary.regularPay}`);
    doc.text(`Overtime Pay: ${salary.overtimePay}`);
    doc.text(`Gross: ${salary.grossSalary}`);
    doc.text(`Deductions: ${JSON.stringify(salary.deductions)}`);
    doc.end();
  }catch(err){ next(err); }
});

module.exports = router;
