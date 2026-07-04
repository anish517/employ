const express = require('express');
const router = express.Router();
const authMiddleware = require('../middlewares/auth.middleware');

// Public routes
router.use('/auth', require('./auth'));

// Protected routes (require admin JWT)
router.use('/dashboard', authMiddleware, require('./dashboard'));
router.use('/employees', authMiddleware, require('./employees'));
router.use('/departments', authMiddleware, require('./departments'));
router.use('/designations', authMiddleware, require('./designations'));
router.use('/attendance', authMiddleware, require('./attendance'));
router.use('/salary', authMiddleware, require('./salary'));
router.use('/salary-history', authMiddleware, require('./salary_history'));
router.use('/bonuses', authMiddleware, require('./bonuses'));
router.use('/fines', authMiddleware, require('./fines'));
router.use('/loans', authMiddleware, require('./loans'));
router.use('/expenses', authMiddleware, require('./expenses'));
router.use('/holidays', authMiddleware, require('./holidays'));
router.use('/leave-types', authMiddleware, require('./leave_types'));
router.use('/leave', authMiddleware, require('./leave'));
router.use('/reports', authMiddleware, require('./reports'));
router.use('/settings', authMiddleware, require('./settings'));

module.exports = router;
