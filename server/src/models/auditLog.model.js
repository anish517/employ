const mongoose = require('mongoose');

const AuditLogSchema = new mongoose.Schema({
  adminId: { type: mongoose.Schema.Types.ObjectId, ref: 'Admin' },
  action: String,
  collectionName: String,
  documentId: mongoose.Schema.Types.ObjectId,
  metadata: Object,
  timestamp: { type: Date, default: Date.now }
});

module.exports = mongoose.model('AuditLog', AuditLogSchema);
