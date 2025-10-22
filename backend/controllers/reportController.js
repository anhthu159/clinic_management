const MedicalRecord = require('../models/medical_record');
const Billing = require('../models/billing');
const Patient = require('../models/patient');

// Báo cáo doanh thu theo khoảng thời gian
exports.getRevenueReport = async (req, res) => {
  try {
    const { startDate, endDate } = req.query;
    
    if (!startDate || !endDate) {
      return res.status(400).json({ 
        success: false, 
        message: 'Vui lòng cung cấp startDate và endDate' 
      });
    }
    
    const billings = await Billing.find({
      createdAt: { 
        $gte: new Date(startDate), 
        $lte: new Date(endDate) 
      },
      paymentStatus: 'Đã thanh toán'
    });
    
    const totalRevenue = billings.reduce((sum, bill) => sum + bill.totalAmount, 0);
    const totalBills = billings.length;
    const totalDiscount = billings.reduce((sum, bill) => sum + bill.discount, 0);
    
    res.json({ 
      success: true, 
      data: {
        period: { startDate, endDate },
        totalRevenue,
        totalBills,
        totalDiscount,
        averagePerBill: totalBills > 0 ? totalRevenue / totalBills : 0
      }
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// Báo cáo số lượng bệnh nhân khám theo khoảng thời gian
exports.getPatientVisitReport = async (req, res) => {
  try {
    const { startDate, endDate } = req.query;
    
    if (!startDate || !endDate) {
      return res.status(400).json({ 
        success: false, 
        message: 'Vui lòng cung cấp startDate và endDate' 
      });
    }
    
    const records = await MedicalRecord.find({
      visitDate: { 
        $gte: new Date(startDate), 
        $lte: new Date(endDate) 
      }
    }).populate('patientId', 'patientType');
    
    const totalVisits = records.length;
    const patientTypes = records.reduce((acc, record) => {
      const type = record.patientId?.patientType || 'Thường';
      acc[type] = (acc[type] || 0) + 1;
      return acc;
    }, {});
    
    res.json({ 
      success: true, 
      data: {
        period: { startDate, endDate },
        totalVisits,
        patientTypes
      }
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// Báo cáo dịch vụ được sử dụng nhiều nhất
exports.getTopServicesReport = async (req, res) => {
  try {
    const { startDate, endDate, limit = 10 } = req.query;
    
    let query = {};
    if (startDate && endDate) {
      query.visitDate = { 
        $gte: new Date(startDate), 
        $lte: new Date(endDate) 
      };
    }
    
    const records = await MedicalRecord.find(query);
    
    const serviceCount = {};
    records.forEach(record => {
      record.services.forEach(service => {
        const name = service.serviceName;
        if (!serviceCount[name]) {
          serviceCount[name] = { count: 0, totalRevenue: 0 };
        }
        serviceCount[name].count += 1;
        serviceCount[name].totalRevenue += service.price;
      });
    });
    
    const topServices = Object.entries(serviceCount)
      .map(([name, data]) => ({ serviceName: name, ...data }))
      .sort((a, b) => b.count - a.count)
      .slice(0, parseInt(limit));
    
    res.json({ success: true, data: topServices });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// Thống kê tổng quan
exports.getDashboardStats = async (req, res) => {
  try {
    const totalPatients = await Patient.countDocuments();
    const totalRecordsToday = await MedicalRecord.countDocuments({
      visitDate: { 
        $gte: new Date(new Date().setHours(0, 0, 0, 0)) 
      }
    });
    
    const pendingPayments = await Billing.countDocuments({ 
      paymentStatus: 'Chưa thanh toán' 
    });
    
    const todayRevenue = await Billing.aggregate([
      {
        $match: { 
          createdAt: { 
            $gte: new Date(new Date().setHours(0, 0, 0, 0)) 
          },
          paymentStatus: 'Đã thanh toán'
        }
      },
      {
        $group: {
          _id: null,
          total: { $sum: '$totalAmount' }
        }
      }
    ]);
    
    res.json({ 
      success: true, 
      data: {
        totalPatients,
        totalRecordsToday,
        pendingPayments,
        todayRevenue: todayRevenue.length > 0 ? todayRevenue[0].total : 0
      }
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};