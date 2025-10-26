const Billing = require('../models/billing');
const MedicalRecord = require('../models/medical_record');
const { validationResult } = require('express-validator');

// Tạo hóa đơn từ hồ sơ khám bệnh
exports.createBilling = async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ success: false, errors: errors.array() });
    }
    const medicalRecord = await MedicalRecord.findById(req.body.medicalRecordId);
    if (!medicalRecord) {
      return res.status(404).json({ success: false, message: 'Không tìm thấy hồ sơ khám bệnh' });
    }
    
    // Tính toán chi phí
    let subtotal = 0;
    
    const serviceCharges = medicalRecord.services.map(s => {
      subtotal += s.price;
      return { serviceName: s.serviceName, price: s.price, quantity: 1 };
    });
    
    const medicineCharges = medicalRecord.prescriptions.map(p => {
      const cost = p.price * p.quantity;
      subtotal += cost;
      return { medicineName: p.medicineName, price: p.price, quantity: p.quantity };
    });
    
    const discount = req.body.discount || medicalRecord.discount || 0;
    const totalAmount = subtotal - discount;
    
    const billing = new Billing({
      medicalRecordId: req.body.medicalRecordId,
      patientId: medicalRecord.patientId,
      serviceCharges,
      medicineCharges,
      subtotal,
      discount,
      totalAmount,
      paymentStatus: req.body.paymentStatus || 'Chưa thanh toán',
      paymentMethod: req.body.paymentMethod
    });
    
    await billing.save();
    res.status(201).json({ success: true, data: billing });
  } catch (error) {
    res.status(400).json({ success: false, message: error.message });
  }
};

// Lấy danh sách hóa đơn
exports.getAllBillings = async (req, res) => {
  try {
    const { paymentStatus, startDate, endDate } = req.query;
    let query = {};
    
    if (paymentStatus) {
      query.paymentStatus = paymentStatus;
    }
    
    if (startDate && endDate) {
      query.createdAt = { 
        $gte: new Date(startDate), 
        $lte: new Date(endDate) 
      };
    }
    
    const billings = await Billing.find(query)
      .populate('patientId', 'fullName phone')
      .populate('medicalRecordId', 'visitDate')
      .sort({ createdAt: -1 });
    res.json({ success: true, data: billings });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// Lấy chi tiết hóa đơn
exports.getBillingById = async (req, res) => {
  try {
    const billing = await Billing.findById(req.params.id)
      .populate('patientId')
      .populate('medicalRecordId');
    if (!billing) {
      return res.status(404).json({ success: false, message: 'Không tìm thấy hóa đơn' });
    }
    res.json({ success: true, data: billing });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// Cập nhật trạng thái thanh toán
exports.updatePaymentStatus = async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ success: false, errors: errors.array() });
    }

    const { paymentStatus, paymentMethod, paidDate } = req.body;
    
    const billing = await Billing.findByIdAndUpdate(
      req.params.id, 
      { paymentStatus, paymentMethod, paidDate: paidDate || Date.now() },
      { new: true }
    );
    
    if (!billing) {
      return res.status(404).json({ success: false, message: 'Không tìm thấy hóa đơn' });
    }
    res.json({ success: true, data: billing });
  } catch (error) {
    res.status(400).json({ success: false, message: error.message });
  }
};