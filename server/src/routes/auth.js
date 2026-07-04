const express = require('express');
const router = express.Router();
const Admin = require('../models/admin.model');
const RefreshToken = require('../models/refreshToken.model');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const crypto = require('crypto');

function signAccessToken(admin){
  return jwt.sign({ id: admin._id, email: admin.email }, process.env.JWT_ACCESS_SECRET || 'secret', { expiresIn: process.env.ACCESS_TOKEN_EXPIRY || '15m' });
}

async function issueRefreshToken(admin){
  const token = crypto.randomBytes(40).toString('hex');
  const hash = await bcrypt.hash(token, 10);
  const expiresAt = new Date(Date.now() + (parseExpiry(process.env.REFRESH_TOKEN_EXPIRY || '30d')));
  const rt = new RefreshToken({ adminId: admin._id, tokenHash: hash, expiresAt });
  await rt.save();
  return token;
}

function parseExpiry(spec){
  // supports simple formats like 30d, 15m
  if(!spec) return 30*24*60*60*1000;
  if(spec.endsWith('d')) return parseInt(spec)*24*60*60*1000;
  if(spec.endsWith('m')) return parseInt(spec)*60*1000;
  return parseInt(spec);
}

// POST /api/auth/login
router.post('/login', async (req,res,next)=>{
  try{
    const { email, password } = req.body;
    if(!email || !password) return res.status(400).json({ success:false, error:{ code:'VALIDATION_ERROR', message:'email and password required' } });
    const admin = await Admin.findOne({ email });
    if(!admin) return res.status(401).json({ success:false, error:{ code:'UNAUTHORIZED', message:'Invalid credentials' } });
    const ok = await admin.verifyPassword(password);
    if(!ok) return res.status(401).json({ success:false, error:{ code:'UNAUTHORIZED', message:'Invalid credentials' } });
    const accessToken = signAccessToken(admin);
    const refreshToken = await issueRefreshToken(admin);
    res.json({ success:true, data:{ accessToken, refreshToken, admin: { id: admin._id, fullName: admin.fullName, email: admin.email } } });
  }catch(err){ next(err); }
});

// POST /api/auth/refresh
router.post('/refresh', async (req,res,next)=>{
  try{
    const { refreshToken } = req.body;
    if(!refreshToken) return res.status(400).json({ success:false, error:{ code:'VALIDATION_ERROR', message:'refreshToken required' } });
    const all = await RefreshToken.find({ revoked: false }).sort({ createdAt: -1 }).limit(10);
    // find matching hash
    let matched = null;
    for(const r of all){
      const ok = await bcrypt.compare(refreshToken, r.tokenHash);
      if(ok){ matched = r; break; }
    }
    if(!matched) return res.status(401).json({ success:false, error:{ code:'UNAUTHORIZED', message:'Invalid refresh token' } });
    if(matched.expiresAt && matched.expiresAt < new Date()){
      matched.revoked = true; await matched.save();
      return res.status(401).json({ success:false, error:{ code:'UNAUTHORIZED', message:'Refresh token expired' } });
    }
    // rotate
    matched.revoked = true; await matched.save();
    const admin = await Admin.findById(matched.adminId);
    const accessToken = signAccessToken(admin);
    const newRefresh = await issueRefreshToken(admin);
    res.json({ success:true, data:{ accessToken, refreshToken: newRefresh } });
  }catch(err){ next(err); }
});

// POST /api/auth/logout
router.post('/logout', async (req,res,next)=>{
  try{
    const { refreshToken } = req.body;
    if(!refreshToken) return res.status(400).json({ success:false, error:{ code:'VALIDATION_ERROR', message:'refreshToken required' } });
    const all = await RefreshToken.find({ revoked: false }).limit(10);
    for(const r of all){ const ok = await bcrypt.compare(refreshToken, r.tokenHash); if(ok){ r.revoked = true; await r.save(); break; } }
    res.json({ success:true });
  }catch(err){ next(err); }
});

// POST /api/auth/change-password
router.post('/change-password', async (req,res,next)=>{
  try{
    const auth = req.headers.authorization;
    if(!auth || !auth.startsWith('Bearer ')) return res.status(401).json({ success:false, error:{ code:'UNAUTHORIZED', message:'Missing token' } });
    const token = auth.slice(7);
    let payload;
    try{ payload = jwt.verify(token, process.env.JWT_ACCESS_SECRET || 'secret'); }catch(e){ return res.status(401).json({ success:false, error:{ code:'UNAUTHORIZED', message:'Invalid token' } }); }
    const admin = await Admin.findById(payload.id);
    const { currentPassword, newPassword } = req.body;
    if(!currentPassword || !newPassword) return res.status(400).json({ success:false, error:{ code:'VALIDATION_ERROR', message:'currentPassword and newPassword required' } });
    const ok = await admin.verifyPassword(currentPassword);
    if(!ok) return res.status(401).json({ success:false, error:{ code:'UNAUTHORIZED', message:'Current password incorrect' } });
    admin.passwordHash = await bcrypt.hash(newPassword, 10);
    await admin.save();
    res.json({ success:true });
  }catch(err){ next(err); }
});

module.exports = router;
