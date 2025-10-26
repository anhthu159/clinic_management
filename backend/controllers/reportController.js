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
    
    // Match records where either visitDate or createdAt falls in the requested range.
    const dateQuery = {
      $or: [
        { visitDate: { $gte: new Date(startDate), $lte: new Date(endDate) } },
        { createdAt: { $gte: new Date(startDate), $lte: new Date(endDate) } }
      ]
    };

  // Populate patient basic info (type, fullName, phone) so the frontend can show meaningful rows
  // Note: patient model uses 'fullName' field, map it to 'name' in the payload below for frontend compatibility.
  const records = await MedicalRecord.find(dateQuery).populate('patientId', 'patientType fullName phone');

    // Debug: log matched records count and a sample (first record) to help diagnose empty results
    console.log('getPatientVisitReport - matched records:', records.length);
    if (records.length > 0) {
      const sample = records[0].toObject ? records[0].toObject() : records[0];
      console.log('getPatientVisitReport - first record sample:', JSON.stringify({
        _id: sample._id,
        visitDate: sample.visitDate,
        createdAt: sample.createdAt,
        patient: sample.patientId
      }));
    }

    const totalVisits = records.length;
    // Count patient types using the actual value from the populated patient document.
    // If patientType is missing, record it under 'Không xác định' so UI can display missing values explicitly.
    const patientTypes = records.reduce((acc, record) => {
      const type = record.patientId && record.patientId.patientType ? record.patientId.patientType : 'Không xác định';
      acc[type] = (acc[type] || 0) + 1;
      return acc;
    }, {});

    // Build a list of visit rows that the frontend can display (one per MedicalRecord)
    const visits = records.map(record => ({
      _id: record._id,
      visitDate: record.visitDate,
      reason: record.reason || null,
      // Keep patientType as-is (may be undefined/null) so frontend can render actual value or show explicitly missing
      patient: record.patientId ? {
        _id: record.patientId._id,
        // map fullName -> name for frontend
        name: record.patientId.fullName || null,
        phone: record.patientId.phone || null,
        patientType: record.patientId.patientType || null
      } : null
    }));

    // Aggregate unique patients with visit counts
    const patientsMap = {};
    records.forEach(record => {
      const p = record.patientId;
      if (!p) return;
      const id = p._id.toString();
      if (!patientsMap[id]) {
        patientsMap[id] = {
          _id: id,
          // map fullName -> name for frontend
          name: p.fullName || null,
          phone: p.phone || null,
          // Preserve actual patientType (or null) without forcing a default here
          patientType: p.patientType || null,
          visits: 0
        };
      }
      patientsMap[id].visits += 1;
    });

    const patients = Object.values(patientsMap);

    res.json({ 
      success: true, 
      data: {
        period: { startDate, endDate },
        totalVisits,
        patientTypes,
        visits,
        patients
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
    
    // Aggregate service usage and billed revenue from Billing.serviceCharges.
    // This is more accurate for revenue-based reports because it reflects billed amounts
    // rather than only service definitions stored on medical records.

    const match = {};
    if (startDate && endDate) {
      match.createdAt = {
        $gte: new Date(startDate),
        $lte: new Date(endDate),
      };
    }

    const pipeline = [
      { $match: match },
      { $unwind: '$serviceCharges' },
      {
        $group: {
          _id: '$serviceCharges.serviceName',
          count: { $sum: 1 },
          totalRevenue: { $sum: { $multiply: [ '$serviceCharges.price', { $ifNull: [ '$serviceCharges.quantity', 1 ] } ] } }
        }
      },
      { $project: { _id: 0, serviceName: '$_id', count: 1, totalRevenue: 1 } },
      { $sort: { count: -1, totalRevenue: -1 } },
      { $limit: parseInt(limit) }
    ];

    const billingBased = await Billing.aggregate(pipeline);

    // Also compute record-based stats from MedicalRecord.services for comparison
    const recordMatch = {};
    if (startDate && endDate) {
      recordMatch.visitDate = {
        $gte: new Date(startDate),
        $lte: new Date(endDate),
      };
    }

    const recordPipeline = [
      { $match: recordMatch },
      { $unwind: '$services' },
      {
        $group: {
          _id: '$services.serviceName',
          count: { $sum: 1 },
          totalRevenue: { $sum: { $ifNull: [ '$services.price', 0 ] } }
        }
      },
      { $project: { _id: 0, serviceName: '$_id', count: 1, totalRevenue: 1 } },
      { $sort: { count: -1, totalRevenue: -1 } },
      { $limit: parseInt(limit) }
    ];

    const recordBased = await MedicalRecord.aggregate(recordPipeline);

    res.json({ success: true, data: { billingBased, recordBased } });
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

// Return a small sample of MedicalRecord documents for debugging/inspection
exports.getSampleMedicalRecords = async (req, res) => {
  try {
    const limit = parseInt(req.query.limit || '10');
    const samples = await MedicalRecord.find()
      .sort({ createdAt: -1 })
      .limit(limit)
      .populate('patientId', 'fullName phone patientType');

    // Map populated fullName -> name for frontend compatibility
    const mapped = samples.map(s => {
      const obj = s.toObject ? s.toObject() : s;
      if (obj.patientId) {
        obj.patientId.name = obj.patientId.fullName || obj.patientId.name || null;
      }
      return obj;
    });

    res.json({ success: true, data: { count: mapped.length, samples: mapped } });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};