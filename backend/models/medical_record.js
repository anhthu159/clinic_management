const mongoose = require('mongoose');

const medicalRecordSchema = new mongoose.Schema({
  patientId: { type: mongoose.Schema.Types.ObjectId, ref: 'Patient', required: true },
  visitDate: { type: Date, required: true, default: Date.now },
  symptoms: { type: String, required: true },
  diagnosis: String,
  doctorName: String,
  roomNumber: String,
  services: [{
    serviceId: { type: mongoose.Schema.Types.ObjectId, ref: 'Service' },
    serviceName: String,
    price: Number
  }],
  prescriptions: [{
    medicineId: { type: mongoose.Schema.Types.ObjectId, ref: 'Medicine' },
    medicineName: String,
    quantity: Number,
    unit: String,
    price: Number,
    dosage: String
  }],
  discount: { type: Number, default: 0 },
  notes: String,
  status: { type: String, enum: ['Đang khám', 'Hoàn thành', 'Hủy'], default: 'Đang khám' }
}, { timestamps: true });

module.exports = mongoose.model('MedicalRecord', medicalRecordSchema);