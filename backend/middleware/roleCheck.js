
exports.authorize = (...roles) => {
  return (req, res, next) => {
    if (!roles.includes(req.user.role)) {
      return res.status(403).json({
        success: false,
        message: `Role '${req.user.role}' không có quyền truy cập chức năng này`
      });
    }
    next();
  };
};

// THÊM MỚI: Phân quyền chi tiết hơn
exports.canCreatePatient = (req, res, next) => {
  const role = req.user.role;
  // Chỉ admin và receptionist có thể tạo bệnh nhân
  if (['admin', 'receptionist'].includes(role)) {
    return next();
  }
  return res.status(403).json({
    success: false,
    message: 'Bạn không có quyền thêm bệnh nhân'
  });
};

exports.canDeletePatient = (req, res, next) => {
  const role = req.user.role;
  // Chỉ admin có thể xóa bệnh nhân
  if (role === 'admin') {
    return next();
  }
  return res.status(403).json({
    success: false,
    message: 'Chỉ admin mới có quyền xóa bệnh nhân'
  });
};

exports.canManageMedicalRecord = (req, res, next) => {
  const role = req.user.role;
  // Chỉ admin và doctor có thể tạo/sửa hồ sơ khám
  if (['admin', 'doctor'].includes(role)) {
    return next();
  }
  return res.status(403).json({
    success: false,
    message: 'Chỉ bác sĩ mới có quyền quản lý hồ sơ khám bệnh'
  });
};

exports.canManageBilling = (req, res, next) => {
  const role = req.user.role;
  // Chỉ admin và accountant có thể quản lý thanh toán
  if (['admin', 'accountant'].includes(role)) {
    return next();
  }
  return res.status(403).json({
    success: false,
    message: 'Chỉ kế toán mới có quyền cập nhật thanh toán'
  });
};

exports.canManageServices = (req, res, next) => {
  const role = req.user.role;
  // Chỉ admin có thể quản lý dịch vụ và thuốc
  if (role === 'admin') {
    return next();
  }
  return res.status(403).json({
    success: false,
    message: 'Chỉ admin mới có quyền quản lý dịch vụ/thuốc'
  });
};