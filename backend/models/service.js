const mongoose = require('mongoose');

const serviceSchema = new mongoose.Schema({
  serviceName: { type: String, required: true },
  description: String,
  price: { type: Number, required: true },
  department: String,
  isActive: { type: Boolean, default: true }
}, { timestamps: true });

module.exports = mongoose.model('Service', serviceSchema);