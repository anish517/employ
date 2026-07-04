const express = require('express');
const router = express.Router();
const mongoose = require('mongoose');

const designationSchema = new mongoose.Schema({
  title: { type: String, required: true },
  departmentId: { type: mongoose.Schema.Types.ObjectId, ref: 'Department' },
}, { timestamps: true });

const Designation = mongoose.models.Designation || mongoose.model('Designation', designationSchema);

// GET /api/designations
router.get('/', async (req, res, next) => {
  try {
    const docs = await Designation.find().sort({ title: 1 });
    res.json({ success: true, data: docs });
  } catch (err) { next(err); }
});

// POST /api/designations
router.post('/', async (req, res, next) => {
  try {
    const { title, departmentId } = req.body;
    if (!title) return res.status(400).json({ success: false, error: { code: 'VALIDATION_ERROR', message: 'title is required' } });
    const desig = await Designation.create({ title, departmentId });
    res.status(201).json({ success: true, data: desig });
  } catch (err) { next(err); }
});

// PUT /api/designations/:id
router.put('/:id', async (req, res, next) => {
  try {
    const desig = await Designation.findByIdAndUpdate(req.params.id, req.body, { new: true });
    if (!desig) return res.status(404).json({ success: false, error: { code: 'NOT_FOUND', message: 'Designation not found' } });
    res.json({ success: true, data: desig });
  } catch (err) { next(err); }
});

// DELETE /api/designations/:id
router.delete('/:id', async (req, res, next) => {
  try {
    const desig = await Designation.findByIdAndDelete(req.params.id);
    if (!desig) return res.status(404).json({ success: false, error: { code: 'NOT_FOUND', message: 'Designation not found' } });
    res.json({ success: true });
  } catch (err) { next(err); }
});

module.exports = router;
