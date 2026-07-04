const express = require('express');
const router = express.Router();
const LeaveType = require('../models/leaveType.model');
const LeaveRequest = require('../models/leaveRequest.model');
const AuditLog = require('../models/auditLog.model');

// Leave types
router.get('/types', async (req, res, next) => {
  try {
    const docs = await LeaveType.find();
    res.json({ success: true, data: docs });
  } catch (err) { next(err); }
});

router.post('/types', async (req, res, next) => {
  try {
    const { name, maxDaysPerYear, isPaid } = req.body;
    if (!name) return res.status(400).json({ success: false, error: { code: 'VALIDATION_ERROR', message: 'name required' } });
    const lt = await LeaveType.create({ name, maxDaysPerYear, isPaid });
    await AuditLog.create({ adminId: req.admin ? req.admin._id : null, action: 'CREATE', collectionName: 'leave_types', documentId: lt._id });
    res.status(201).json({ success: true, data: lt });
  } catch (err) { next(err); }
});

// Leave requests
router.get('/requests', async (req, res, next) => {
  try {
    const { status, employeeId } = req.query;
    const q = {};
    if (status) q.status = status;
    if (employeeId) q.employeeId = employeeId;
    const docs = await LeaveRequest.find(q);
    res.json({ success: true, data: docs });
  } catch (err) { next(err); }
});

// POST /api/leave/requests
router.post('/requests', async (req, res, next) => {
  try {
    const { employeeId, leaveTypeId, startDate, endDate, reason } = req.body;
    if (!employeeId || !leaveTypeId || !startDate || !endDate) return res.status(400).json({ success: false, error: { code: 'VALIDATION_ERROR', message: 'employeeId, leaveTypeId, startDate, endDate required' } });
    const s = new Date(startDate);
    const e = new Date(endDate);
    if (s > e) return res.status(400).json({ success: false, error: { code: 'VALIDATION_ERROR', message: 'startDate must be <= endDate' } });

    // overlap check with existing pending/approved
    const overlap = await LeaveRequest.findOne({
      employeeId,
      status: { $in: ['Pending','Approved'] },
      $or: [
        { startDate: { $lte: e, $gte: s } },
        { endDate: { $lte: e, $gte: s } },
        { startDate: { $lte: s }, endDate: { $gte: e } }
      ]
    });
    if (overlap) return res.status(400).json({ success: false, error: { code: 'CONFLICT', message: 'Overlapping leave request exists' } });

    const totalDays = Math.round((e - s) / (1000*60*60*24)) + 1;
    const lr = await LeaveRequest.create({ employeeId, leaveTypeId, startDate: s, endDate: e, totalDays, reason });
    await AuditLog.create({ adminId: req.admin ? req.admin._id : null, action: 'CREATE', collectionName: 'leave_requests', documentId: lr._id, metadata: { employeeId, startDate, endDate } });
    res.status(201).json({ success: true, data: lr });
  } catch (err) { next(err); }
});

router.put('/requests/:id/approve', async (req, res, next) => {
  try {
    const lr = await LeaveRequest.findById(req.params.id);
    if (!lr) return res.status(404).json({ success: false, error: { code: 'NOT_FOUND', message: 'Leave request not found' } });
    lr.status = 'Approved';
    lr.reviewedAt = new Date();
    await lr.save();
    await AuditLog.create({ adminId: req.admin ? req.admin._id : null, action: 'APPROVE', collectionName: 'leave_requests', documentId: lr._id });
    res.json({ success: true, data: lr });
  } catch (err) { next(err); }
});

router.put('/requests/:id/reject', async (req, res, next) => {
  try {
    const lr = await LeaveRequest.findById(req.params.id);
    if (!lr) return res.status(404).json({ success: false, error: { code: 'NOT_FOUND', message: 'Leave request not found' } });
    lr.status = 'Rejected';
    lr.reviewedAt = new Date();
    await lr.save();
    await AuditLog.create({ adminId: req.admin ? req.admin._id : null, action: 'REJECT', collectionName: 'leave_requests', documentId: lr._id });
    res.json({ success: true, data: lr });
  } catch (err) { next(err); }
});

router.get('/balance/:employeeId', async (req, res, next) => {
  try {
    const employeeId = req.params.employeeId;
    const types = await LeaveType.find();
    const year = new Date().getFullYear();
    const result = [];
    for (const t of types) {
      const used = await LeaveRequest.aggregate([
        { $match: { employeeId, leaveTypeId: t._id, status: 'Approved', startDate: { $gte: new Date(year,0,1) } } },
        { $group: { _id: null, total: { $sum: '$totalDays' } } }
      ]);
      const usedDays = (used[0] && used[0].total) || 0;
      result.push({ leaveType: t.name, maxDays: t.maxDaysPerYear, used: usedDays, remaining: (t.maxDaysPerYear || 0) - usedDays });
    }
    res.json({ success: true, data: result });
  } catch (err) { next(err); }
});

module.exports = router;
