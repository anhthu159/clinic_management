const Patient = require('../models/patient');

// Tạo bệnh nhân mới (Tiếp nhận)
exports.createPatient = async (req, res) => {
  try {
    // Thêm validation
    const { fullName, phone, dateOfBirth } = req.body;
    
    if (!fullName || !phone || !dateOfBirth) {
      return res.status(400).json({ 
        success: false, 
        message: 'Vui lòng nhập đầy đủ thông tin bắt buộc' 
      });
    }
    
    // Kiểm tra số điện thoại đã tồn tại
    const existingPatient = await Patient.findOne({ phone });
    if (existingPatient) {
      return res.status(400).json({ 
        success: false, 
        message: 'Số điện thoại đã tồn tại trong hệ thống' 
      });
    }
    
    const patient = new Patient(req.body);
    await patient.save();
    res.status(201).json({ success: true, data: patient });
  } catch (error) {
    res.status(400).json({ success: false, message: error.message });
  }
};

// Lấy danh sách bệnh nhân
exports.getAllPatients = async (req, res) => {
  try {
    const { search, patientType } = req.query;
    let query = {};
    
    if (search) {
      query.$or = [
        { fullName: { $regex: search, $options: 'i' } },
        { phone: { $regex: search, $options: 'i' } }
      ];
    }
    
    if (patientType) {
      query.patientType = patientType;
    }
    
    const patients = await Patient.find(query).sort({ createdAt: -1 });
    res.json({ success: true, data: patients });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// Lấy thông tin chi tiết bệnh nhân
exports.getPatientById = async (req, res) => {
  try {
    const patient = await Patient.findById(req.params.id);
    if (!patient) {
      return res.status(404).json({ success: false, message: 'Không tìm thấy bệnh nhân' });
    }
    res.json({ success: true, data: patient });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// Cập nhật thông tin bệnh nhân
exports.updatePatient = async (req, res) => {
  try {
    const patient = await Patient.findByIdAndUpdate(req.params.id, req.body, { new: true });
    if (!patient) {
      return res.status(404).json({ success: false, message: 'Không tìm thấy bệnh nhân' });
    }
    res.json({ success: true, data: patient });
  } catch (error) {
    res.status(400).json({ success: false, message: error.message });
  }
};

// Xóa bệnh nhân
exports.deletePatient = async (req, res) => {
  try {
    const patient = await Patient.findByIdAndDelete(req.params.id);
    if (!patient) {
      return res.status(404).json({ success: false, message: 'Không tìm thấy bệnh nhân' });
    }
    res.json({ success: true, message: 'Đã xóa bệnh nhân thành công' });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};