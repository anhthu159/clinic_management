const mongoose = require('mongoose');

const medicineSchema = new mongoose.Schema({
  medicineName: { type: String, required: true },
  unit: { type: String, required: true },
  price: { type: Number, required: true },
  stockQuantity: { type: Number, default: 0 },
  description: String
}, { timestamps: true });

module.exports = mongoose.model('Medicine', medicineSchema);