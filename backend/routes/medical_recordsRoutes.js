const express = require('express');
const router = express.Router();
const medicalRecordController = require('../controllers/medical_recordController');
const { protect } = require('../middleware/auth');
const { canManageMedicalRecord } = require('../middleware/roleCheck');
router.use(protect);

router.post('/', canManageMedicalRecord, medicalRecordController.createMedicalRecord);
router.put('/:id', canManageMedicalRecord, medicalRecordController.updateMedicalRecord);


router.get('/', medicalRecordController.getAllMedicalRecords);
router.get('/patient/:patientId', medicalRecordController.getMedicalRecordsByPatient);
router.get('/:id', medicalRecordController.getMedicalRecordById);


module.exports = router;