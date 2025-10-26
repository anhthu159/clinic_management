const express = require('express');
const router = express.Router();
const medicineController = require('../controllers/medicineController');
const { protect } = require('../middleware/auth');
const { canManageServices } = require('../middleware/roleCheck');
const { body } = require('express-validator');
router.use(protect);

router.post('/',
	canManageServices,
	[
		body('medicineName').trim().notEmpty().withMessage('Tên thuốc không được để trống'),
		body('price').isFloat({ min: 0 }).withMessage('Giá phải là số không âm'),
		body('stock').optional().isInt({ min: 0 }).withMessage('Stock phải là số nguyên không âm')
	],
	medicineController.createMedicine
);

router.put('/:id',
	canManageServices,
	[
		body('medicineName').optional().trim(),
		body('price').optional().isFloat({ min: 0 }).withMessage('Giá phải là số không âm'),
		body('stock').optional().isInt({ min: 0 }).withMessage('Stock phải là số nguyên không âm')
	],
	medicineController.updateMedicine
);
router.delete('/:id', canManageServices, medicineController.deleteMedicine);

router.get('/', medicineController.getAllMedicines);
router.get('/:id', medicineController.getMedicineById);

module.exports = router;