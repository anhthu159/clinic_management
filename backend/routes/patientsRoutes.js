const express = require('express');
const router = express.Router();
const patientController = require('../controllers/patientController');
const { protect } = require('../middleware/auth');
const { canCreatePatient, canDeletePatient } = require('../middleware/roleCheck');

router.use(protect);

router.post('/', canCreatePatient, patientController.createPatient);
router.put('/:id', canCreatePatient, patientController.updatePatient);
router.delete('/:id', canDeletePatient, patientController.deletePatient);


router.get('/', patientController.getAllPatients);
router.get('/:id', patientController.getPatientById);


module.exports = router;