const express = require('express');
const router = express.Router();
const patientController = require('../controllers/patientController');
const { protect } = require('../middleware/auth');
const { canCreatePatient, canDeletePatient } = require('../middleware/roleCheck');
const { body } = require('express-validator');

router.use(protect);

router.post('/',
	canCreatePatient,
	[
		body('fullName').trim().notEmpty().withMessage('Họ tên không được để trống'),
		body('phone').matches(/^[0-9]{9,12}$/).withMessage('Số điện thoại không hợp lệ'),
		body('dateOfBirth').isISO8601().withMessage('Ngày sinh không hợp lệ'),
	],
	patientController.createPatient
);
router.put('/:id', canCreatePatient, patientController.updatePatient);
router.delete('/:id', canDeletePatient, patientController.deletePatient);


router.get('/', patientController.getAllPatients);
router.get('/:id', patientController.getPatientById);


module.exports = router;