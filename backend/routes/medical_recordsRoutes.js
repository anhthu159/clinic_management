const express = require('express');
const router = express.Router();
const medicalRecordController = require('../controllers/medical_recordController');
const { protect } = require('../middleware/auth');
const { canManageMedicalRecord } = require('../middleware/roleCheck');
const { body } = require('express-validator');
router.use(protect);

router.post('/',
	canManageMedicalRecord,
	[
		body('patientId').notEmpty().withMessage('patientId bắt buộc').isMongoId().withMessage('patientId không hợp lệ'),
		body('visitDate').notEmpty().withMessage('visitDate bắt buộc').isISO8601().withMessage('visitDate không hợp lệ'),
		body('symptoms').trim().notEmpty().withMessage('Triệu chứng không được để trống')
	],
	medicalRecordController.createMedicalRecord
);

router.put('/:id',
	canManageMedicalRecord,
	[
		body('visitDate').optional().isISO8601().withMessage('visitDate không hợp lệ')
	],
	medicalRecordController.updateMedicalRecord
);


router.get('/', medicalRecordController.getAllMedicalRecords);
router.get('/patient/:patientId', medicalRecordController.getMedicalRecordsByPatient);
router.get('/:id', medicalRecordController.getMedicalRecordById);


module.exports = router;