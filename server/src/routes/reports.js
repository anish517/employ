const express = require('express');
const router = express.Router();
const Employee = require('../models/employee.model');
const Attendance = require('../models/attendance.model');
const LeaveRequest = require('../models/leaveRequest.model');
const Salary = require('../models/salary.model');
const Bonus = require('../models/bonus.model');
const Fine = require('../models/fine.model');
const exportService = require('../services/export.service');

async function buildQuery(type, query) {
  const { from, to, employeeId, departmentId } = query;
  const q = {};
  if (employeeId) q.employeeId = employeeId;
  if (departmentId) q.departmentId = departmentId;
  if (from || to) {
    const dateField = type === 'attendance' ? 'date' : type === 'leave' ? 'startDate' : 'createdAt';
    q[dateField] = {};
    if (from) q[dateField].$gte = new Date(from);
    if (to) q[dateField].$lte = new Date(to);
  }
  return q;
}

// GET /api/reports/:type?format=pdf|excel|csv&from=&to=&employeeId=&departmentId=
router.get('/:type', async (req, res, next) => {
  try {
    const { type } = req.params;
    const { format = 'json' } = req.query;
    const q = await buildQuery(type, req.query);

    let data = [];
    let columns = [];
    let rows = [];
    let title = '';

    switch (type) {
      case 'employee':
        title = 'Employee Report';
        data = await Employee.find(q).lean();
        columns = ['Employee ID', 'Full Name', 'Email', 'Phone', 'Department', 'Employment Type', 'Hourly Rate', 'Status', 'Joining Date'];
        rows = data.map(e => [e.employeeId, e.fullName, e.email, e.phone, e.departmentId, e.employmentType, e.hourlyRate, e.status, e.joiningDate ? new Date(e.joiningDate).toLocaleDateString() : '']);
        break;
      case 'attendance':
        title = 'Attendance Report';
        data = await Attendance.find(q).lean();
        columns = ['Employee ID', 'Date', 'Status', 'Check In', 'Check Out', 'Working Hours', 'Overtime Hours', 'Is Late'];
        rows = data.map(a => [a.employeeId, a.date ? new Date(a.date).toLocaleDateString() : '', a.status, a.checkIn ? new Date(a.checkIn).toLocaleTimeString() : '', a.checkOut ? new Date(a.checkOut).toLocaleTimeString() : '', a.workingHours, a.overtimeHours, a.isLate ? 'Yes' : 'No']);
        break;
      case 'leave':
        title = 'Leave Report';
        data = await LeaveRequest.find(q).lean();
        columns = ['Employee ID', 'Leave Type', 'Start Date', 'End Date', 'Total Days', 'Status', 'Reason'];
        rows = data.map(l => [l.employeeId, l.leaveTypeId, l.startDate ? new Date(l.startDate).toLocaleDateString() : '', l.endDate ? new Date(l.endDate).toLocaleDateString() : '', l.totalDays, l.status, l.reason]);
        break;
      case 'payroll':
        title = 'Payroll Report';
        data = await Salary.find(q).lean();
        columns = ['Employee ID', 'Month', 'Hourly Rate', 'Regular Hours', 'Overtime Hours', 'Gross Salary', 'Net Salary', 'Status'];
        rows = data.map(s => [s.employeeId, s.month, s.hourlyRate, s.regularHours, s.overtimeHours, s.grossSalary, s.netSalary, s.status]);
        break;
      case 'bonus':
        title = 'Bonus Report';
        data = await Bonus.find(q).lean();
        columns = ['Employee ID', 'Type', 'Amount', 'Month', 'Reason'];
        rows = data.map(b => [b.employeeId, b.type, b.amount, b.month, b.reason]);
        break;
      case 'fine':
        title = 'Fine Report';
        data = await Fine.find(q).lean();
        columns = ['Employee ID', 'Type', 'Amount', 'Month', 'Reason'];
        rows = data.map(f => [f.employeeId, f.type, f.amount, f.month, f.reason]);
        break;
      default:
        return res.status(400).json({ success: false, error: { code: 'VALIDATION_ERROR', message: 'Unknown report type' } });
    }

    if (format === 'pdf') {
      const buffer = await exportService.generatePDF(title, columns, rows);
      res.setHeader('Content-Type', 'application/pdf');
      res.setHeader('Content-Disposition', `attachment; filename=${type}-report.pdf`);
      return res.send(buffer);
    }

    if (format === 'excel') {
      const buffer = await exportService.generateExcel(title, columns, rows);
      res.setHeader('Content-Type', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
      res.setHeader('Content-Disposition', `attachment; filename=${type}-report.xlsx`);
      return res.send(buffer);
    }

    if (format === 'csv') {
      const csv = exportService.generateCSV(columns, rows);
      res.setHeader('Content-Type', 'text/csv');
      res.setHeader('Content-Disposition', `attachment; filename=${type}-report.csv`);
      return res.send(csv);
    }

    res.json({ success: true, data });
  } catch (err) { next(err); }
});

module.exports = router;