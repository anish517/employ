const jwt = require('jsonwebtoken');
const Admin = require('../models/admin.model');

module.exports = async function authMiddleware(req, res, next){
  try{
    const auth = req.headers.authorization || req.headers.Authorization;
    if(!auth || !auth.startsWith('Bearer ')) return res.status(401).json({ success:false, error:{ code:'UNAUTHORIZED', message:'Missing token' } });
    const token = auth.slice(7);
    let payload;
    try{ payload = jwt.verify(token, process.env.JWT_ACCESS_SECRET || 'secret'); }catch(e){ return res.status(401).json({ success:false, error:{ code:'UNAUTHORIZED', message:'Invalid token' } }); }
    const admin = await Admin.findById(payload.id).select('-passwordHash');
    if(!admin) return res.status(401).json({ success:false, error:{ code:'UNAUTHORIZED', message:'Admin not found' } });
    req.admin = admin;
    next();
  }catch(err){ next(err); }
};
