const Appointment = require('../models/appointment');
const Patient = require('../models/patient');

// Tạo lịch hẹn mới
exports.createAppointment = async (req, res) => {
  try {
    const patient = await Patient.findById(req.body.patientId);
    if (!patient) {
      return res.status(404).json({ success: false, message: 'Không tìm thấy bệnh nhân' });
    }
    
    // Kiểm tra xem đã có lịch hẹn vào thời gian này chưa
    const existingAppointment = await Appointment.findOne({
      appointmentDate: req.body.appointmentDate,
      appointmentTime: req.body.appointmentTime,
      doctorName: req.body.doctorName,
      status: { $nin: ['Hủy', 'Không đến'] }
    });
    
    if (existingAppointment) {
      return res.status(400).json({ 
        success: false, 
        message: 'Đã có lịch hẹn vào thời gian này' 
      });
    }
    
    const appointment = new Appointment(req.body);
    await appointment.save();
    
    const populatedAppointment = await Appointment.findById(appointment._id)
      .populate('patientId', 'fullName phone');
    
    res.status(201).json({ success: true, data: populatedAppointment });
  } catch (error) {
    res.status(400).json({ success: false, message: error.message });
  }
};

// Lấy danh sách lịch hẹn
exports.getAllAppointments = async (req, res) => {
  try {
    const { status, date, doctorName } = req.query;
    let query = {};
    
    if (status) {
      query.status = status;
    }
    
    if (date) {
      const startDate = new Date(date);
      const endDate = new Date(date);
      endDate.setDate(endDate.getDate() + 1);
      query.appointmentDate = { $gte: startDate, $lt: endDate };
    }
    
    if (doctorName) {
      query.doctorName = { $regex: doctorName, $options: 'i' };
    }
    
    const appointments = await Appointment.find(query)
      .populate('patientId', 'fullName phone patientType')
      .sort({ appointmentDate: 1, appointmentTime: 1 });
    
    res.json({ success: true, data: appointments });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// Lấy lịch hẹn theo bệnh nhân
exports.getAppointmentsByPatient = async (req, res) => {
  try {
    const appointments = await Appointment.find({ patientId: req.params.patientId })
      .sort({ appointmentDate: -1 });
    res.json({ success: true, data: appointments });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// Lấy chi tiết lịch hẹn
exports.getAppointmentById = async (req, res) => {
  try {
    const appointment = await Appointment.findById(req.params.id)
      .populate('patientId', 'fullName phone patientType address');
    
    if (!appointment) {
      return res.status(404).json({ success: false, message: 'Không tìm thấy lịch hẹn' });
    }
    res.json({ success: true, data: appointment });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// Cập nhật lịch hẹn
exports.updateAppointment = async (req, res) => {
  try {
    const appointment = await Appointment.findByIdAndUpdate(
      req.params.id, 
      req.body, 
      { new: true }
    ).populate('patientId', 'fullName phone');
    
    if (!appointment) {
      return res.status(404).json({ success: false, message: 'Không tìm thấy lịch hẹn' });
    }
    res.json({ success: true, data: appointment });
  } catch (error) {
    res.status(400).json({ success: false, message: error.message });
  }
};

// Cập nhật trạng thái lịch hẹn
exports.updateAppointmentStatus = async (req, res) => {
  try {
    const { status } = req.body;
    
    if (!['Chờ khám', 'Đã khám', 'Hủy', 'Không đến'].includes(status)) {
      return res.status(400).json({ success: false, message: 'Trạng thái không hợp lệ' });
    }
    
    const appointment = await Appointment.findByIdAndUpdate(
      req.params.id,
      { status },
      { new: true }
    ).populate('patientId', 'fullName phone');
    
    if (!appointment) {
      return res.status(404).json({ success: false, message: 'Không tìm thấy lịch hẹn' });
    }
    
    res.json({ success: true, data: appointment });
  } catch (error) {
    res.status(400).json({ success: false, message: error.message });
  }
};

// Xóa lịch hẹn
exports.deleteAppointment = async (req, res) => {
  try {
    const appointment = await Appointment.findByIdAndDelete(req.params.id);
    if (!appointment) {
      return res.status(404).json({ success: false, message: 'Không tìm thấy lịch hẹn' });
    }
    res.json({ success: true, message: 'Đã xóa lịch hẹn thành công' });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// Lấy lịch hẹn hôm nay
exports.getTodayAppointments = async (req, res) => {
  try {
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const tomorrow = new Date(today);
    tomorrow.setDate(tomorrow.getDate() + 1);
    
    const appointments = await Appointment.find({
      appointmentDate: { $gte: today, $lt: tomorrow },
      status: { $ne: 'Hủy' }
    })
      .populate('patientId', 'fullName phone patientType')
      .sort({ appointmentTime: 1 });
    
    res.json({ success: true, data: appointments });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};