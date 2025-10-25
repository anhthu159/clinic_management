const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const userSchema = new mongoose.Schema({
  username: { type: String, required: true, unique: true, trim: true },
  password: { type: String, required: true },
  fullName: { type: String, default: '' }, // Cho phép empty, sẽ fallback về username
  email: { type: String, trim: true, lowercase: true },
  phone: String,
  role: { 
    type: String, 
    enum: ['admin', 'doctor', 'receptionist', 'accountant'],
    required: true,
    default: 'receptionist'
  },
  isActive: { type: Boolean, default: true }
}, { timestamps: true });

// Hash password trước khi lưu
userSchema.pre('save', async function(next) {
  // Chỉ hash nếu password được modified
  if (!this.isModified('password')) return next();
  
  try {
    this.password = await bcrypt.hash(this.password, 10);
    next();
  } catch (error) {
    next(error);
  }
});

// So sánh password
userSchema.methods.comparePassword = async function(candidatePassword) {
  try {
    return await bcrypt.compare(candidatePassword, this.password);
  } catch (error) {
    return false;
  }
};

// Đảm bảo fullName luôn có giá trị khi trả về
userSchema.methods.toJSON = function() {
  const obj = this.toObject();
  delete obj.password;
  obj.fullName = obj.fullName || obj.username;
  return obj;
};

module.exports = mongoose.model('User', userSchema);