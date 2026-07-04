const express = require('express');
const router = express.Router();
const LeaveType = require('../models/leaveType.model');
const AuditLog = require('../models/auditLog.model');

// GET /api/leave-types
router.get('/', async (req, res, next) => {
  try {
    const docs = await LeaveType.find();
    res.json({ success: true, data: docs });
  } catch (err) { next(err); }
});

// POST /api/leave-types
router.post('/', async (req, res, next) => {
  try {
    const { name, maxDaysPerYear, isPaid } = req.body;
    if (!name) return res.status(400).json({ success: false, error: { code: 'VALIDATION_ERROR', message: 'name required' } });
    const lt = await LeaveType.create({ name, maxDaysPerYear, isPaid });
    await AuditLog.create({ adminId: req.admin ? req.admin._id : null, action: 'CREATE', collectionName: 'leave_types', documentId: lt._id });
    res.status(201).json({ success: true, data: lt });
  } catch (err) { next(err); }
});

// PUT /api/leave-types/:id
router.put('/:id', async (req, res, next) => {
  try {
    const lt = await LeaveType.findByIdAndUpdate(req.params.id, req.body, { new: true });
    if (!lt) return res.status(404).json({ success: false, error: { code: 'NOT_FOUND', message: 'Leave type not found' } });
    res.json({ success: true, data: lt });
  } catch (err) { next(err); }
});

// DELETE /api/leave-types/:id
router.delete('/:id', async (req, res, next) => {
  try {
    await LeaveType.findByIdAndDelete(req.params.id);
    res.json({ success: true });
  } catch (err) { next(err); }
});

module.exports = router;
