const User = require('../models/user');

// Tạo user mới (chỉ admin)
exports.createUser = async (req, res) => {
  try {
    const user = new User(req.body);
    await user.save();
    
    // Không trả về password
    const userResponse = user.toObject();
    delete userResponse.password;
    
    res.status(201).json({ success: true, data: userResponse });
  } catch (error) {
    res.status(400).json({ success: false, message: error.message });
  }
};

// Lấy danh sách users
exports.getAllUsers = async (req, res) => {
  try {
    const { role, isActive } = req.query;
    let query = {};
    
    if (role) query.role = role;
    if (isActive !== undefined) query.isActive = isActive === 'true';
    
    const users = await User.find(query).select('-password').sort({ createdAt: -1 });
    res.json({ success: true, data: users });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// Lấy chi tiết user
exports.getUserById = async (req, res) => {
  try {
    const user = await User.findById(req.params.id).select('-password');
    if (!user) {
      return res.status(404).json({ success: false, message: 'Không tìm thấy user' });
    }
    res.json({ success: true, data: user });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// Cập nhật user
exports.updateUser = async (req, res) => {
  try {
    // Không cho phép cập nhật password qua API này
    delete req.body.password;
    
    // Validate dữ liệu đầu vào
    if (req.body.fullName === '') {
      return res.status(400).json({
        success: false,
        message: 'Họ tên không được để trống'
      });
    }

    // Nếu không có fullName, sử dụng username
    if (!req.body.fullName) {
      const user = await User.findById(req.params.id);
      if (user) {
        req.body.fullName = user.username;
      }
    }
    
    const user = await User.findByIdAndUpdate(
      req.params.id, 
      req.body, 
      { new: true }
    ).select('-password');
    
    if (!user) {
      return res.status(404).json({ success: false, message: 'Không tìm thấy user' });
    }

    // Trả về dữ liệu theo format thống nhất
    const userData = {
      id: user._id,
      username: user.username,
      fullName: user.fullName || user.username,
      email: user.email,
      role: user.role,
      isActive: user.isActive
    };

    res.json({ 
      success: true, 
      message: 'Cập nhật thông tin thành công',
      data: userData 
    });
  } catch (error) {
    res.status(400).json({ success: false, message: error.message });
  }
};

// Khóa/Mở khóa user
exports.toggleUserStatus = async (req, res) => {
  try {
    const user = await User.findById(req.params.id);
    if (!user) {
      return res.status(404).json({ success: false, message: 'Không tìm thấy user' });
    }
    
    user.isActive = !user.isActive;
    await user.save();
    
    res.json({ 
      success: true, 
      message: user.isActive ? 'Đã mở khóa user' : 'Đã khóa user',
      data: { isActive: user.isActive }
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// Xóa user
exports.deleteUser = async (req, res) => {
  try {
    const user = await User.findByIdAndDelete(req.params.id);
    if (!user) {
      return res.status(404).json({ success: false, message: 'Không tìm thấy user' });
    }
    res.json({ success: true, message: 'Đã xóa user thành công' });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};