const express = require('express');
const router = express.Router();
const Loan = require('../models/loan.model');
const LoanInstallment = require('../models/loanInstallment.model');
const AuditLog = require('../models/auditLog.model');

// GET /api/loans?employeeId=
router.get('/', async (req,res,next)=>{
  try{ const { employeeId } = req.query; const q={}; if(employeeId) q.employeeId = employeeId; const docs = await Loan.find(q); res.json({ success:true, data: docs }); }catch(err){ next(err); }
});

// POST /api/loans
router.post('/', async (req,res,next)=>{
  try{
    const { employeeId, totalAmount, emiAmount, startDate } = req.body;
    if(!employeeId || !totalAmount || !emiAmount) return res.status(400).json({ success:false, error:{ code:'VALIDATION_ERROR', message:'employeeId, totalAmount, emiAmount required' } });
    if(Number(emiAmount) > Number(totalAmount)) return res.status(400).json({ success:false, error:{ code:'VALIDATION_ERROR', message:'emiAmount must be <= totalAmount' } });
    // prevent second active loan
    const existing = await Loan.findOne({ employeeId, status: 'Active' });
    if(existing) return res.status(400).json({ success:false, error:{ code:'VALIDATION_ERROR', message:'Active loan already exists for this employee' } });
    const loan = await Loan.create({ employeeId, totalAmount: Number(totalAmount), emiAmount: Number(emiAmount), startDate });
    await AuditLog.create({ adminId: req.admin ? req.admin._id : null, action:'CREATE', collectionName:'loans', documentId: loan._id, metadata: { employeeId, totalAmount } });
    res.status(201).json({ success:true, data: loan });
  }catch(err){ next(err); }
});

// GET /api/loans/:id/installments
router.get('/:id/installments', async (req,res,next)=>{
  try{ const docs = await LoanInstallment.find({ loanId: req.params.id }); res.json({ success:true, data: docs }); }catch(err){ next(err); }
});

// POST /api/loans/:id/installments
router.post('/:id/installments', async (req,res,next)=>{
  try{
    const { amountPaid, month } = req.body;
    if(!amountPaid || !month) return res.status(400).json({ success:false, error:{ code:'VALIDATION_ERROR', message:'amountPaid and month required' } });
    const loan = await Loan.findById(req.params.id);
    if(!loan) return res.status(404).json({ success:false, error:{ code:'NOT_FOUND', message:'Loan not found' } });
    const inst = await LoanInstallment.create({ loanId: loan._id, amountPaid: Number(amountPaid), month });
    await AuditLog.create({ adminId: req.admin ? req.admin._id : null, action:'CREATE', collectionName:'loan_installments', documentId: inst._id, metadata: { loanId: loan._id, amountPaid } });
    // update loan status if fully paid
    const installments = await LoanInstallment.find({ loanId: loan._id });
    const paid = installments.reduce((s,i)=>s+Number(i.amountPaid||0),0);
    if(paid >= loan.totalAmount){ loan.status = 'Closed'; await loan.save(); }
    res.status(201).json({ success:true, data: inst });
  }catch(err){ next(err); }
});

module.exports = router;