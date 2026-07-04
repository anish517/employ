const express = require('express');
const router = express.Router();
const Attendance = require('../models/attendance.model');
const CompanySettings = require('../models/companySettings.model');
const AuditLog = require('../models/auditLog.model');

function computeHours(checkInStr, checkOutStr, company){
  if(!checkInStr || !checkOutStr) return { workingHours: 0, overtimeHours: 0, isLate: false };
  const [inH,inM] = checkInStr.split(':').map(Number);
  const [outH,outM] = checkOutStr.split(':').map(Number);
  const checkIn = new Date(); checkIn.setHours(inH, inM, 0, 0);
  const checkOut = new Date(); checkOut.setHours(outH, outM, 0, 0);
  let worked = (checkOut - checkIn) / (1000*60*60);
  if(worked < 0) worked = 0;
  let standard = 8;
  let isLate = false;
  if(company && company.workingHours && company.workingHours.start){
    const [sh, sm] = company.workingHours.start.split(':').map(Number);
    const [eh, em] = company.workingHours.end.split(':').map(Number);
    standard = (eh + em/60) - (sh + sm/60);
    const grace = (company.gracePeriodMinutes || 10)/60;
    const startTime = new Date(); startTime.setHours(sh, sm+ (company.gracePeriodMinutes||10),0,0);
    isLate = checkIn > startTime;
  }
  const overtime = Math.max(0, worked - standard);
  const regular = Math.min(standard, worked);
  return { workingHours: Number(regular.toFixed(2)), overtimeHours: Number(overtime.toFixed(2)), isLate };
}

// POST /api/attendance/mark
router.post('/mark', async (req,res,next)=>{
  try{
    const { employeeId, date, status, checkIn, checkOut } = req.body;
    if(!employeeId || !date) return res.status(400).json({ success:false, error:{ code:'VALIDATION_ERROR', message:'employeeId and date required' } });
    const company = await CompanySettings.findOne();
    const hrs = computeHours(checkIn, checkOut, company || {});
    const att = await Attendance.findOneAndUpdate({ employeeId, date: new Date(date) }, { $set: { status, checkIn: checkIn? new Date(date+'T'+checkIn): undefined, checkOut: checkOut? new Date(date+'T'+checkOut): undefined, workingHours: hrs.workingHours, overtimeHours: hrs.overtimeHours, isLate: hrs.isLate } }, { upsert: true, new: true });
    await AuditLog.create({ adminId: req.admin ? req.admin._id : null, action: 'CREATE', collectionName: 'attendance', documentId: att._id, metadata: { employeeId, date } });
    res.status(201).json({ success:true, data: att });
  }catch(err){ next(err); }
});

// POST /api/attendance/bulk-mark
router.post('/bulk-mark', async (req,res,next)=>{
  try{
    const { date, entries } = req.body;
    if(!date || !Array.isArray(entries)) return res.status(400).json({ success:false, error:{ code:'VALIDATION_ERROR', message:'date and entries required' } });
    const company = await CompanySettings.findOne();
    const results = [];
    for(const e of entries){
      const hrs = computeHours(e.checkIn, e.checkOut, company || {});
      const att = await Attendance.findOneAndUpdate({ employeeId: e.employeeId, date: new Date(date) }, { $set: { status: e.status, checkIn: e.checkIn? new Date(date+'T'+e.checkIn): undefined, checkOut: e.checkOut? new Date(date+'T'+e.checkOut): undefined, workingHours: hrs.workingHours, overtimeHours: hrs.overtimeHours, isLate: hrs.isLate } }, { upsert: true, new: true });
      await AuditLog.create({ adminId: req.admin ? req.admin._id : null, action: 'CREATE', collectionName: 'attendance', documentId: att._id, metadata: { employeeId: e.employeeId, date } });
      results.push(att);
    }
    res.status(201).json({ success:true, data: results });
  }catch(err){ next(err); }
});

// GET /api/attendance/monthly?month=YYYY-MM&employeeId=
router.get('/monthly', async (req,res,next)=>{
  try{
    const { month, employeeId } = req.query;
    if(!month) return res.status(400).json({ success:false, error:{ code:'VALIDATION_ERROR', message:'month required' } });
    const [y,m] = month.split('-').map(Number);
    const start = new Date(y, m-1, 1);
    const end = new Date(y, m, 1);
    const q = { date: { $gte: start, $lt: end } };
    if(employeeId) q.employeeId = employeeId;
    const docs = await Attendance.find(q);
    res.json({ success:true, data: docs });
  }catch(err){ next(err); }
});

module.exports = router;
