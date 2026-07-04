const mongoose = require('mongoose');

const RefreshTokenSchema = new mongoose.Schema({
  adminId: { type: mongoose.Schema.Types.ObjectId, ref: 'Admin', required: true },
  tokenHash: { type: String, required: true },
  expiresAt: Date,
  revoked: { type: Boolean, default: false },
  createdAt: { type: Date, default: Date.now }
});

module.exports = mongoose.model('RefreshToken', RefreshTokenSchema);
