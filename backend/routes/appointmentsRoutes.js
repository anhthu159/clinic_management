const express = require('express');
const router = express.Router();
const appointmentController = require('../controllers/appointmentController');
const { protect } = require('../middleware/auth');
const { body } = require('express-validator');

router.use(protect);

router.post('/',
	[
		body('patientId').notEmpty().withMessage('patientId bắt buộc').isMongoId().withMessage('patientId không hợp lệ'),
		body('appointmentDate').notEmpty().withMessage('appointmentDate bắt buộc').isISO8601().withMessage('appointmentDate không hợp lệ'),
		body('appointmentTime').notEmpty().withMessage('appointmentTime bắt buộc'),
	],
	appointmentController.createAppointment
);
router.get('/', appointmentController.getAllAppointments);
router.get('/today', appointmentController.getTodayAppointments);
router.get('/patient/:patientId', appointmentController.getAppointmentsByPatient);
router.get('/:id', appointmentController.getAppointmentById);
router.put('/:id',
	[
		body('appointmentDate').optional().isISO8601().withMessage('appointmentDate không hợp lệ'),
		body('appointmentTime').optional(),
	],
	appointmentController.updateAppointment
);
router.patch('/:id/status', appointmentController.updateAppointmentStatus);
router.delete('/:id', appointmentController.deleteAppointment);

module.exports = router;