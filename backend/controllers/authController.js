const User = require('../models/user');
const jwt = require('jsonwebtoken');

// Tạo JWT token
const signToken = (id) => {
  return jwt.sign({ id }, process.env.JWT_SECRET, {
    expiresIn: process.env.JWT_EXPIRE
  });
};

// Đăng nhập
exports.login = async (req, res) => {
  try {
    const { username, password } = req.body;
    
    if (!username || !password) {
      return res.status(400).json({ 
        success: false, 
        message: 'Vui lòng nhập username và password' 
      });
    }
    
    // Tìm user
    const user = await User.findOne({ username });
    
    if (!user || !(await user.comparePassword(password))) {
      return res.status(401).json({ 
        success: false, 
        message: 'Username hoặc password không đúng' 
      });
    }
    
    if (!user.isActive) {
      return res.status(401).json({ 
        success: false, 
        message: 'Tài khoản đã bị khóa' 
      });
    }
    
    // Tạo token
    const token = signToken(user._id);
    
    // Đảm bảo user có fullName
    if (!user.fullName) {
      user.fullName = user.username;
      await user.save();
    }
    
    // Lấy thông tin user (loại bỏ password)
    const userWithoutPassword = {
      id: user._id,
      username: user.username,
      fullName: user.fullName,
      email: user.email,
      role: user.role,
      isActive: user.isActive
    };
    
    res.json({
      success: true,
      token,
      user: userWithoutPassword
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

//Đăng kí
exports.register = async (req, res) => {
  try {
    const { username, password, fullName, email, role } = req.body;

    if (!username || !password) {
      return res.status(400).json({ success: false, message: 'Vui lòng nhập username và password' });
    }

    const existed = await User.findOne({ username });
    if (existed) {
      return res.status(400).json({ success: false, message: 'Username đã tồn tại' });
    }

    const user = await User.create({
      username,
      password,          // sẽ được hash bởi pre('save') trong model
      fullName: fullName || '',
      email: email || '',
      role: role || 'receptionist',
      isActive: true
    });

    const token = signToken(user._id);

    res.status(201).json({
      success: true,
      token,
      user: {
        id: user._id,
        username: user.username,
        fullName: user.fullName,
        email: user.email,
        role: user.role
      }
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// Lấy thông tin user hiện tại
exports.getMe = async (req, res) => {
  try {
    const user = await User.findById(req.user.id).select('-password');
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'Không tìm thấy thông tin người dùng'
      });
    }

    const userData = {
      id: user._id,
      username: user.username,
      fullName: user.fullName || user.username, // Fallback to username if fullName is empty
      email: user.email,
      role: user.role,
      isActive: user.isActive
    };

    res.json({ 
      success: true, 
      data: userData
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// Đổi mật khẩu
exports.changePassword = async (req, res) => {
  try {
    const { currentPassword, newPassword } = req.body;
    
    if (!currentPassword || !newPassword) {
      return res.status(400).json({ 
        success: false, 
        message: 'Vui lòng nhập đầy đủ thông tin' 
      });
    }
    
    const user = await User.findById(req.user.id);
    
    // Kiểm tra mật khẩu hiện tại
    if (!(await user.comparePassword(currentPassword))) {
      return res.status(401).json({ 
        success: false, 
        message: 'Mật khẩu hiện tại không đúng' 
      });
    }
    
    // Cập nhật mật khẩu mới
    user.password = newPassword;
    await user.save();
    
    res.json({ 
      success: true, 
      message: 'Đổi mật khẩu thành công' 
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// Cập nhật thông tin profile
exports.updateProfile = async (req, res) => {
  try {
    const { fullName, email, phone } = req.body;
    
    // Validate input
    if (!fullName) {
      return res.status(400).json({
        success: false,
        message: 'Vui lòng nhập họ tên'
      });
    }

    // Tìm và cập nhật user
    const user = await User.findById(req.user.id);
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'Không tìm thấy thông tin người dùng'
      });
    }

    // Cập nhật thông tin
    user.fullName = fullName;
    user.email = email || user.email;
    user.phone = phone || user.phone;
    await user.save();

    // Trả về thông tin đã cập nhật
    const userData = {
      id: user._id,
      username: user.username,
      fullName: user.fullName,
      email: user.email,
      phone: user.phone,
      role: user.role,
      isActive: user.isActive
    };

    res.json({
      success: true,
      message: 'Cập nhật thông tin thành công',
      data: userData
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};