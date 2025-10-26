const express = require('express');
const router = express.Router();
const reportController = require('../controllers/reportController');
const { protect } = require('../middleware/auth');

// Public sample endpoint (no auth) to fetch a few MedicalRecord documents for inspection
router.get('/sample-medical-records-public', reportController.getSampleMedicalRecords);

// Protect remaining report routes
router.use(protect);

router.get('/revenue', reportController.getRevenueReport);
router.get('/patient-visits', reportController.getPatientVisitReport);
router.get('/top-services', reportController.getTopServicesReport);
router.get('/dashboard', reportController.getDashboardStats);
router.get('/sample-medical-records', reportController.getSampleMedicalRecords);

module.exports = router;