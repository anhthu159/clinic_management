const Medicine = require('../models/medicine');
const { validationResult } = require('express-validator');

// Tạo thuốc mới
exports.createMedicine = async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ success: false, errors: errors.array() });
    }
    const medicine = new Medicine(req.body);
    await medicine.save();
    res.status(201).json({ success: true, data: medicine });
  } catch (error) {
    res.status(400).json({ success: false, message: error.message });
  }
};

// Lấy danh sách thuốc
exports.getAllMedicines = async (req, res) => {
  try {
    const { search } = req.query;
    let query = {};
    
    if (search) {
      query.medicineName = { $regex: search, $options: 'i' };
    }
    
    const medicines = await Medicine.find(query);
    res.json({ success: true, data: medicines });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// Lấy chi tiết thuốc
exports.getMedicineById = async (req, res) => {
  try {
    const medicine = await Medicine.findById(req.params.id);
    if (!medicine) {
      return res.status(404).json({ success: false, message: 'Không tìm thấy thuốc' });
    }
    res.json({ success: true, data: medicine });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// Cập nhật thuốc
exports.updateMedicine = async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ success: false, errors: errors.array() });
    }
    const medicine = await Medicine.findByIdAndUpdate(req.params.id, req.body, { new: true });
    if (!medicine) {
      return res.status(404).json({ success: false, message: 'Không tìm thấy thuốc' });
    }
    res.json({ success: true, data: medicine });
  } catch (error) {
    res.status(400).json({ success: false, message: error.message });
  }
};

// Xóa thuốc
exports.deleteMedicine = async (req, res) => {
  try {
    const medicine = await Medicine.findByIdAndDelete(req.params.id);
    if (!medicine) {
      return res.status(404).json({ success: false, message: 'Không tìm thấy thuốc' });
    }
    res.json({ success: true, message: 'Đã xóa thuốc thành công' });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};