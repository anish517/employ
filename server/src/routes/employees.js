const express = require('express');
const router = express.Router();
const Employee = require('../models/employee.model');
const AuditLog = require('../models/auditLog.model');

function nextEmployeeId(num){ return 'EMP-' + String(num).padStart(4,'0'); }

// POST /api/employees
router.post('/', async (req,res,next)=>{
  try{
    const data = req.body;
    if(!data.fullName || !data.phone || !data.hourlyRate) return res.status(400).json({ success:false, error:{ code:'VALIDATION_ERROR', message:'fullName, phone, hourlyRate required' } });
    const count = await Employee.countDocuments();
    const employeeId = nextEmployeeId(count+1);
    const emp = new Employee(Object.assign({}, data, { employeeId }));
    await emp.save();
    await AuditLog.create({ adminId: req.admin ? req.admin._id : null, action: 'CREATE', collectionName: 'employees', documentId: emp._id, metadata: { fullName: emp.fullName } });
    res.status(201).json({ success:true, data: emp });
  }catch(err){ next(err); }
});

// GET /api/employees
router.get('/', async (req,res,next)=>{
  try{
    const { search, department, status, page = 1, limit = 20 } = req.query;
    const q = {};
    if(search) q.$or = [{ fullName: new RegExp(search, 'i') }, { email: new RegExp(search, 'i') }, { phone: new RegExp(search, 'i') }];
    if(department) q.departmentId = department;
    if(status) q.status = status;
    const skip = (page-1)*limit;
    const docs = await Employee.find(q).skip(skip).limit(Number(limit));
    const total = await Employee.countDocuments(q);
    res.json({ success:true, data: docs, meta: { total, page: Number(page), totalPages: Math.ceil(total/limit) } });
  }catch(err){ next(err); }
});

// GET /api/employees/:id
router.get('/:id', async (req,res,next)=>{
  try{ const emp = await Employee.findById(req.params.id); if(!emp) return res.status(404).json({ success:false, error:{ code:'NOT_FOUND', message:'Employee not found' } }); res.json({ success:true, data: emp }); }catch(err){ next(err); }
});

// PUT /api/employees/:id
router.put('/:id', async (req,res,next)=>{
  try{
    const updates = req.body;
    const emp = await Employee.findByIdAndUpdate(req.params.id, updates, { new: true });
    if(!emp) return res.status(404).json({ success:false, error:{ code:'NOT_FOUND', message:'Employee not found' } });
    await AuditLog.create({ adminId: req.admin ? req.admin._id : null, action: 'UPDATE', collectionName: 'employees', documentId: emp._id, metadata: updates });
    res.json({ success:true, data: emp });
  }catch(err){ next(err); }
});

// DELETE /api/employees/:id
router.delete('/:id', async (req,res,next)=>{
  try{
    const emp = await Employee.findById(req.params.id);
    if(!emp) return res.status(404).json({ success:false, error:{ code:'NOT_FOUND', message:'Employee not found' } });
    // soft delete
    emp.status = 'Inactive';
    emp.deletedAt = new Date();
    await emp.save();
    await AuditLog.create({ adminId: req.admin ? req.admin._id : null, action: 'DELETE', collectionName: 'employees', documentId: emp._id, metadata: { reason: 'soft delete' } });
    res.json({ success:true });
  }catch(err){ next(err); }
});

module.exports = router;
