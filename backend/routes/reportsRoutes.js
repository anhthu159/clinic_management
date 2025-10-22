const express = require('express');
const router = express.Router();
const reportController = require('../controllers/reportController');

router.get('/revenue', reportController.getRevenueReport);
router.get('/patient-visits', reportController.getPatientVisitReport);
router.get('/top-services', reportController.getTopServicesReport);
router.get('/dashboard', reportController.getDashboardStats);

module.exports = router;