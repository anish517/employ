const express = require('express');
const router = express.Router();
const Holiday = require('../models/holiday.model');
const AuditLog = require('../models/auditLog.model');

// GET /api/holidays
router.get('/', async (req,res,next)=>{ try{ const { year } = req.query; const q={}; if(year){ const y = Number(year); q.date = { $gte: new Date(y,0,1), $lte: new Date(y,11,31) }; } const docs = await Holiday.find(q); res.json({ success:true, data: docs }); }catch(err){ next(err); } });

// POST /api/holidays
router.post('/', async (req,res,next)=>{ try{ const { name, date, type } = req.body; if(!name || !date) return res.status(400).json({ success:false, error:{ code:'VALIDATION_ERROR', message:'name and date required' } }); // reject duplicate date+type
  const existing = await Holiday.findOne({ date: new Date(date), type }); if(existing) return res.status(400).json({ success:false, error:{ code:'CONFLICT', message:'Holiday with same date and type exists' } }); const h = await Holiday.create({ name, date: new Date(date), type }); await AuditLog.create({ adminId: req.admin ? req.admin._id : null, action:'CREATE', collectionName:'holidays', documentId: h._id, metadata: { name, date } }); res.status(201).json({ success:true, data: h }); }catch(err){ next(err); } });

// PUT /api/holidays/:id
router.put('/:id', async (req,res,next)=>{ try{ const h = await Holiday.findByIdAndUpdate(req.params.id, req.body, { new: true }); if(!h) return res.status(404).json({ success:false, error:{ code:'NOT_FOUND', message:'Holiday not found' } }); await AuditLog.create({ adminId: req.admin ? req.admin._id : null, action:'UPDATE', collectionName:'holidays', documentId: h._id, metadata: req.body }); res.json({ success:true, data: h }); }catch(err){ next(err); } });

// DELETE /api/holidays/:id
router.delete('/:id', async (req,res,next)=>{ try{ await Holiday.findByIdAndDelete(req.params.id); await AuditLog.create({ adminId: req.admin ? req.admin._id : null, action:'DELETE', collectionName:'holidays', documentId: req.params.id }); res.json({ success:true }); }catch(err){ next(err); } });

module.exports = router;
