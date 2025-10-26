const MedicalRecord = require('../models/medical_record');
const Patient = require('../models/patient');
const { validationResult } = require('express-validator');

// Tạo hồ sơ khám bệnh mới
exports.createMedicalRecord = async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ success: false, errors: errors.array() });
    }

    const patient = await Patient.findById(req.body.patientId);
    if (!patient) {
      return res.status(404).json({ success: false, message: 'Không tìm thấy bệnh nhân' });
    }

    const medicalRecord = new MedicalRecord(req.body);
    await medicalRecord.save();
    res.status(201).json({ success: true, data: medicalRecord });
  } catch (error) {
    res.status(400).json({ success: false, message: error.message });
  }
};

// Lấy lịch sử khám bệnh của bệnh nhân
exports.getMedicalRecordsByPatient = async (req, res) => {
  try {
    const records = await MedicalRecord.find({ patientId: req.params.patientId })
      .populate('patientId', 'fullName phone')
      .sort({ visitDate: -1 });
    res.json({ success: true, data: records });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// Lấy chi tiết hồ sơ khám bệnh
exports.getMedicalRecordById = async (req, res) => {
  try {
    const record = await MedicalRecord.findById(req.params.id)
      .populate('patientId', 'fullName phone patientType');
    if (!record) {
      return res.status(404).json({ success: false, message: 'Không tìm thấy hồ sơ' });
    }
    res.json({ success: true, data: record });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// Cập nhật hồ sơ khám bệnh
exports.updateMedicalRecord = async (req, res) => {
  try {
    const record = await MedicalRecord.findByIdAndUpdate(req.params.id, req.body, { new: true });
    if (!record) {
      return res.status(404).json({ success: false, message: 'Không tìm thấy hồ sơ' });
    }
    res.json({ success: true, data: record });
  } catch (error) {
    res.status(400).json({ success: false, message: error.message });
  }
};

// Lấy danh sách tất cả hồ sơ khám bệnh
exports.getAllMedicalRecords = async (req, res) => {
  try {
    const { status, startDate, endDate } = req.query;
    let query = {};
    
    if (status) {
      query.status = status;
    }
    
    if (startDate && endDate) {
      query.visitDate = { 
        $gte: new Date(startDate), 
        $lte: new Date(endDate) 
      };
    }
    
    const records = await MedicalRecord.find(query)
      .populate('patientId', 'fullName phone')
      .sort({ visitDate: -1 });
    res.json({ success: true, data: records });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};