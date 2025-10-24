const express = require('express');
const router = express.Router();
const medicalRecordController = require('../controllers/medical_recordController');
const { protect } = require('../middleware/auth');
router.use(protect);

router.post('/', medicalRecordController.createMedicalRecord);
router.get('/', medicalRecordController.getAllMedicalRecords);
router.get('/patient/:patientId', medicalRecordController.getMedicalRecordsByPatient);
router.get('/:id', medicalRecordController.getMedicalRecordById);
router.put('/:id', medicalRecordController.updateMedicalRecord);

module.exports = router;