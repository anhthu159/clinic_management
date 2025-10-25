const express = require('express');
const router = express.Router();
const billingController = require('../controllers/billingController');
const { protect } = require('../middleware/auth');
const { canManageBilling } = require('../middleware/roleCheck');

router.use(protect);

router.post('/', canManageBilling, billingController.createBilling);
router.put('/:id/payment', canManageBilling, billingController.updatePaymentStatus);


router.get('/', billingController.getAllBillings);
router.get('/:id', billingController.getBillingById);


module.exports = router;