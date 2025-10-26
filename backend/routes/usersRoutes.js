const express = require('express');
const router = express.Router();
const userController = require('../controllers/userController');
const { protect } = require('../middleware/auth');
const { authorize } = require('../middleware/roleCheck');
const { body } = require('express-validator');

// Chỉ admin mới có quyền quản lý users
router.use(protect);
router.use(authorize('admin'));

router.post('/',
	[
		body('username').trim().notEmpty().withMessage('Username không được để trống'),
		body('password').isLength({ min: 6 }).withMessage('Password cần >= 6 ký tự'),
		body('email').optional().isEmail().withMessage('Email không hợp lệ'),
		body('role').optional().isIn(['admin','doctor','receptionist','accountant']).withMessage('Role không hợp lệ')
	],
	userController.createUser
);
router.get('/', userController.getAllUsers);
router.get('/:id', userController.getUserById);
router.put('/:id',
	[
		body('fullName').optional().trim(),
		body('email').optional().isEmail().withMessage('Email không hợp lệ'),
		body('role').optional().isIn(['admin','doctor','receptionist','accountant']).withMessage('Role không hợp lệ'),
	],
	userController.updateUser
);
router.patch('/:id/toggle-status', userController.toggleUserStatus);
router.delete('/:id', userController.deleteUser);

module.exports = router;