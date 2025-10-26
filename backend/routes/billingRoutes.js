const express = require('express');
const router = express.Router();
const billingController = require('../controllers/billingController');
const { protect } = require('../middleware/auth');
const { canManageBilling } = require('../middleware/roleCheck');
const { body } = require('express-validator');

router.use(protect);

router.post('/',
	canManageBilling,
	[
		body('medicalRecordId').notEmpty().withMessage('medicalRecordId bắt buộc').isMongoId().withMessage('medicalRecordId không hợp lệ'),
		body('discount').optional().isNumeric().withMessage('discount phải là số')
	],
	billingController.createBilling
);

router.put('/:id/payment',
	canManageBilling,
	[
		body('paymentStatus').notEmpty().withMessage('paymentStatus bắt buộc')
	],
	billingController.updatePaymentStatus
);


router.get('/', billingController.getAllBillings);
router.get('/:id', billingController.getBillingById);


module.exports = router;