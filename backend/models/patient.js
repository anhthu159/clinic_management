const mongoose = require('mongoose');

const patientSchema = new mongoose.Schema({
  fullName: { type: String, required: true },
  phone: { type: String, required: true },
  dateOfBirth: { type: Date, required: true },
  address: String,
  gender: { type: String, enum: ['Nam', 'Nữ', 'Khác'] },
  idCard: String,
  email: String,
  patientType: { type: String, enum: ['Thường', 'BHYT', 'VIP'], default: 'Thường' }
}, { timestamps: true });

module.exports = mongoose.model('Patient', patientSchema);