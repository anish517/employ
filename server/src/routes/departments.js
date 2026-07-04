const express = require('express');
const router = express.Router();
const mongoose = require('mongoose');

const departmentSchema = new mongoose.Schema({
  name: { type: String, required: true, unique: true },
  description: String,
}, { timestamps: true });

const Department = mongoose.models.Department || mongoose.model('Department', departmentSchema);

// GET /api/departments
router.get('/', async (req, res, next) => {
  try {
    const docs = await Department.find().sort({ name: 1 });
    res.json({ success: true, data: docs });
  } catch (err) { next(err); }
});

// POST /api/departments
router.post('/', async (req, res, next) => {
  try {
    const { name, description } = req.body;
    if (!name) return res.status(400).json({ success: false, error: { code: 'VALIDATION_ERROR', message: 'name is required' } });
    const dept = await Department.create({ name, description });
    res.status(201).json({ success: true, data: dept });
  } catch (err) { next(err); }
});

// PUT /api/departments/:id
router.put('/:id', async (req, res, next) => {
  try {
    const dept = await Department.findByIdAndUpdate(req.params.id, req.body, { new: true });
    if (!dept) return res.status(404).json({ success: false, error: { code: 'NOT_FOUND', message: 'Department not found' } });
    res.json({ success: true, data: dept });
  } catch (err) { next(err); }
});

// DELETE /api/departments/:id
router.delete('/:id', async (req, res, next) => {
  try {
    const dept = await Department.findByIdAndDelete(req.params.id);
    if (!dept) return res.status(404).json({ success: false, error: { code: 'NOT_FOUND', message: 'Department not found' } });
    res.json({ success: true });
  } catch (err) { next(err); }
});

module.exports = router;
