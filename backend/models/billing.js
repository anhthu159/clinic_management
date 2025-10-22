const mongoose = require('mongoose');

const billingSchema = new mongoose.Schema({
  medicalRecordId: { type: mongoose.Schema.Types.ObjectId, ref: 'MedicalRecord', required: true },
  patientId: { type: mongoose.Schema.Types.ObjectId, ref: 'Patient', required: true },
  serviceCharges: [{
    serviceName: String,
    price: Number,
    quantity: { type: Number, default: 1 }
  }],
  medicineCharges: [{
    medicineName: String,
    price: Number,
    quantity: Number
  }],
  subtotal: { type: Number, required: true },
  discount: { type: Number, default: 0 },
  totalAmount: { type: Number, required: true },
  paymentStatus: { 
    type: String, 
    enum: ['Chưa thanh toán', 'Đã thanh toán', 'Thanh toán một phần'],
    default: 'Chưa thanh toán'
  },
  paymentMethod: String,
  paidDate: Date
}, { timestamps: true });

module.exports = mongoose.model('Billing', billingSchema);