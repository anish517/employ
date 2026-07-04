const express = require('express');
const router = express.Router();
const Employee = require('../models/employee.model');
const Attendance = require('../models/attendance.model');
const LeaveRequest = require('../models/leaveRequest.model');
const Salary = require('../models/salary.model');

// GET /api/dashboard/summary
router.get('/summary', async (req, res, next) => {
  try {
    const today = new Date();
    const todayStart = new Date(today.getFullYear(), today.getMonth(), today.getDate());
    const todayEnd = new Date(todayStart.getTime() + 24 * 60 * 60 * 1000);

    const currentMonth = `${today.getFullYear()}-${String(today.getMonth() + 1).padStart(2, '0')}`;

    // Total active employees
    const totalEmployees = await Employee.countDocuments({ status: 'Active' });

    // Present today
    const presentToday = await Attendance.countDocuments({
      date: { $gte: todayStart, $lt: todayEnd },
      status: { $in: ['Present', 'Half Day'] }
    });

    // Absent today
    const absentToday = await Attendance.countDocuments({
      date: { $gte: todayStart, $lt: todayEnd },
      status: 'Absent'
    });

    // Late today
    const lateToday = await Attendance.countDocuments({
      date: { $gte: todayStart, $lt: todayEnd },
      isLate: true
    });

    // Pending leave requests
    const pendingLeaves = await LeaveRequest.countDocuments({ status: 'Pending' });

    // Total salary this month
    const salarySummary = await Salary.aggregate([
      { $match: { month: currentMonth } },
      { $group: { _id: null, total: { $sum: '$netSalary' }, count: { $sum: 1 } } }
    ]);
    const totalSalaryThisMonth = salarySummary[0]?.total || 0;
    const salaryCount = salarySummary[0]?.count || 0;

    // New employees this month
    const monthStart = new Date(today.getFullYear(), today.getMonth(), 1);
    const newEmployeesThisMonth = await Employee.countDocuments({
      joiningDate: { $gte: monthStart }
    });

    res.json({
      success: true,
      data: {
        totalEmployees,
        presentToday,
        absentToday,
        lateToday,
        pendingLeaves,
        totalSalaryThisMonth: Math.round(totalSalaryThisMonth * 100) / 100,
        salaryCount,
        newEmployeesThisMonth,
        currentMonth
      }
    });
  } catch (err) { next(err); }
});

module.exports = router;
