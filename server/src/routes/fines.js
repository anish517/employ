const express = require('express');
const router = express.Router();
const Fine = require('../models/fine.model');
const AuditLog = require('../models/auditLog.model');

// GET /api/fines
router.get('/', async (req,res,next)=>{
  try{ const { employeeId, month } = req.query; const q={}; if(employeeId) q.employeeId = employeeId; if(month) q.month = month; const docs = await Fine.find(q); res.json({ success:true, data: docs }); }catch(err){ next(err); }
});

// POST /api/fines
router.post('/', async (req,res,next)=>{
  try{
    const { employeeId, type, amount, reason, month } = req.body;
    if(!employeeId || !amount || !month) return res.status(400).json({ success:false, error:{ code:'VALIDATION_ERROR', message:'employeeId, amount, month required' } });
    if(Number(amount) <= 0) return res.status(400).json({ success:false, error:{ code:'VALIDATION_ERROR', message:'amount must be > 0' } });
    const f = await Fine.create({ employeeId, type, amount: Number(amount), reason, month });
    await AuditLog.create({ adminId: req.admin ? req.admin._id : null, action: 'CREATE', collectionName: 'fines', documentId: f._id, metadata: { employeeId, amount } });
    res.status(201).json({ success:true, data: f });
  }catch(err){ next(err); }
});

// DELETE /api/fines/:id
router.delete('/:id', async (req,res,next)=>{
  try{ await Fine.findByIdAndDelete(req.params.id); await AuditLog.create({ adminId: req.admin ? req.admin._id : null, action:'DELETE', collectionName:'fines', documentId: req.params.id }); res.json({ success:true }); }catch(err){ next(err); }
});

module.exports = router;
