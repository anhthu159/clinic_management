const express = require('express');
const router = express.Router();
const serviceController = require('../controllers/serviceController');
const { protect } = require('../middleware/auth');
const { canManageServices } = require('../middleware/roleCheck');
router.use(protect);

router.post('/', canManageServices, serviceController.createService);
router.put('/:id', canManageServices, serviceController.updateService);
router.delete('/:id', canManageServices, serviceController.deleteService);


router.get('/', serviceController.getAllServices);
router.get('/:id', serviceController.getServiceById);



module.exports = router;