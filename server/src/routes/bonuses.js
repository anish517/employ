const express = require('express');
const router = express.Router();
const Bonus = require('../models/bonus.model');
const AuditLog = require('../models/auditLog.model');

// GET /api/bonuses
router.get('/', async (req,res,next)=>{
  try{ const { employeeId, month } = req.query; const q={}; if(employeeId) q.employeeId = employeeId; if(month) q.month = month; const docs = await Bonus.find(q); res.json({ success:true, data: docs }); }catch(err){ next(err); }
});

// POST /api/bonuses
router.post('/', async (req,res,next)=>{
  try{
    const { employeeId, type, amount, reason, month } = req.body;
    if(!employeeId || !amount || !month) return res.status(400).json({ success:false, error:{ code:'VALIDATION_ERROR', message:'employeeId, amount, month required' } });
    if(Number(amount) <= 0) return res.status(400).json({ success:false, error:{ code:'VALIDATION_ERROR', message:'amount must be > 0' } });
    const b = await Bonus.create({ employeeId, type, amount: Number(amount), reason, month });
    await AuditLog.create({ adminId: req.admin ? req.admin._id : null, action: 'CREATE', collectionName: 'bonuses', documentId: b._id, metadata: { employeeId, amount } });
    res.status(201).json({ success:true, data: b });
  }catch(err){ next(err); }
});

// DELETE /api/bonuses/:id
router.delete('/:id', async (req,res,next)=>{
  try{ await Bonus.findByIdAndDelete(req.params.id); await AuditLog.create({ adminId: req.admin ? req.admin._id : null, action:'DELETE', collectionName:'bonuses', documentId: req.params.id }); res.json({ success:true }); }catch(err){ next(err); }
});

module.exports = router;
