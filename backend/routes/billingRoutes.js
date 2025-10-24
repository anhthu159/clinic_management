const express = require('express');
const router = express.Router();
const billingController = require('../controllers/billingController');
const { protect } = require('../middleware/auth');

router.use(protect);

router.post('/', billingController.createBilling);
router.get('/', billingController.getAllBillings);
router.get('/:id', billingController.getBillingById);
router.put('/:id/payment', billingController.updatePaymentStatus);

module.exports = router;