const express = require('express');
const router = express.Router();
const medicineController = require('../controllers/medicineController');
const { protect } = require('../middleware/auth');
const { canManageServices } = require('../middleware/roleCheck');
router.use(protect);

router.post('/', canManageServices, medicineController.createMedicine);
router.put('/:id', canManageServices, medicineController.updateMedicine);
router.delete('/:id', canManageServices, medicineController.deleteMedicine);

router.get('/', medicineController.getAllMedicines);
router.get('/:id', medicineController.getMedicineById);

module.exports = router;