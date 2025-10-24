const express = require('express');
const router = express.Router();
const medicineController = require('../controllers/medicineController');
const { protect } = require('../middleware/auth');
router.use(protect);

router.post('/', medicineController.createMedicine);
router.get('/', medicineController.getAllMedicines);
router.get('/:id', medicineController.getMedicineById);
router.put('/:id', medicineController.updateMedicine);
router.delete('/:id', medicineController.deleteMedicine);

module.exports = router;