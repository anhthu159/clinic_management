const express = require('express');
const router = express.Router();
const serviceController = require('../controllers/serviceController');
const { protect } = require('../middleware/auth');
const { canManageServices } = require('../middleware/roleCheck');
const { body } = require('express-validator');
router.use(protect);

router.post('/',
	canManageServices,
	[
		body('serviceName').trim().notEmpty().withMessage('Tên dịch vụ không được để trống'),
		body('price').isFloat({ min: 0 }).withMessage('Giá phải là số không âm'),
	],
	serviceController.createService
);

router.put('/:id',
	canManageServices,
	[
		body('serviceName').optional().trim(),
		body('price').optional().isFloat({ min: 0 }).withMessage('Giá phải là số không âm'),
	],
	serviceController.updateService
);
router.delete('/:id', canManageServices, serviceController.deleteService);


router.get('/', serviceController.getAllServices);
router.get('/:id', serviceController.getServiceById);



module.exports = router;