const express = require('express');
const cors = require('cors');
const rateLimit = require('express-rate-limit');

const app = express();
app.use(express.json());
app.use(cors());

// basic rate limiter for auth endpoints (can be applied per-route in real app)
app.use('/api/auth', rateLimit({ windowMs: 15*60*1000, max: 20 }));

app.get('/api/health', (req,res) => res.json({ success: true, data: { status: 'ok' } }));

// placeholder for routes
app.use('/api', require('./routes'));

// error handler (simple)
app.use((err, req, res, next) => {
  console.error(err);
  const status = err.status || 500;
  res.status(status).json({ success: false, error: { code: err.code || 'SERVER_ERROR', message: err.message || 'Server error' } });
});

module.exports = app;
