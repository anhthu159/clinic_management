const mongoose = require('mongoose');

const appointmentSchema = new mongoose.Schema({
  patientId: { type: mongoose.Schema.Types.ObjectId, ref: 'Patient', required: true },
  appointmentDate: { type: Date, required: true },
  appointmentTime: { type: String, required: true }, // Format: "09:00", "14:30"
  doctorName: String,
  roomNumber: String,
  serviceType: String, // Loại dịch vụ khám
  reason: String, // Lý do khám
  status: { 
    type: String, 
    enum: ['Chờ khám', 'Đã khám', 'Hủy', 'Không đến'],
    default: 'Chờ khám'
  },
  notes: String
}, { timestamps: true });

module.exports = mongoose.model('Appointment', appointmentSchema);