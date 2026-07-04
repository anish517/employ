const express = require('express');
const router = express.Router();
const Expense = require('../models/expense.model');
const AuditLog = require('../models/auditLog.model');

// GET /api/expenses
router.get('/', async (req,res,next)=>{
  try{ const { category, from, to } = req.query; const q={}; if(category) q.category = category; if(from || to){ q.date = {}; if(from) q.date.$gte = new Date(from); if(to) q.date.$lte = new Date(to); } const docs = await Expense.find(q); res.json({ success:true, data: docs }); }catch(err){ next(err); }
});

// POST /api/expenses
router.post('/', async (req,res,next)=>{
  try{ const { category, description, amount, date } = req.body; if(!category || !amount) return res.status(400).json({ success:false, error:{ code:'VALIDATION_ERROR', message:'category and amount required' } }); if(Number(amount) <= 0) return res.status(400).json({ success:false, error:{ code:'VALIDATION_ERROR', message:'amount must be > 0' } }); const ex = await Expense.create({ category, description, amount: Number(amount), date: date? new Date(date): new Date() }); await AuditLog.create({ adminId: req.admin ? req.admin._id : null, action:'CREATE', collectionName:'expenses', documentId: ex._id, metadata: { amount } }); res.status(201).json({ success:true, data: ex }); }catch(err){ next(err); } });

// PUT /api/expenses/:id
router.put('/:id', async (req,res,next)=>{ try{ const ex = await Expense.findByIdAndUpdate(req.params.id, req.body, { new: true }); if(!ex) return res.status(404).json({ success:false, error:{ code:'NOT_FOUND', message:'Expense not found' } }); await AuditLog.create({ adminId: req.admin ? req.admin._id : null, action:'UPDATE', collectionName:'expenses', documentId: ex._id, metadata: req.body }); res.json({ success:true, data: ex }); }catch(err){ next(err); } });

// DELETE /api/expenses/:id
router.delete('/:id', async (req,res,next)=>{ try{ await Expense.findByIdAndDelete(req.params.id); await AuditLog.create({ adminId: req.admin ? req.admin._id : null, action:'DELETE', collectionName:'expenses', documentId: req.params.id }); res.json({ success:true }); }catch(err){ next(err); } });

module.exports = router;
