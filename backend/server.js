require('dotenv').config();
const express = require('express');
const cors = require('cors');
const bodyParser = require('body-parser');
const connectDB = require('./config/database');
const errorHandler = require('./middleware/errorHandler');

// Import routes
const patientRoutes = require('./routes/patientsRoutes');
const medicalRecordRoutes = require('./routes/medical_recordsRoutes');
const serviceRoutes = require('./routes/servicesRoutes');
const medicineRoutes = require('./routes/medicinesRoutes');
const billingRoutes = require('./routes/billingRoutes');
const reportRoutes = require('./routes/reportsRoutes');
const authRoutes = require('./routes/authRoutes');

const app = express();

// Kết nối database
connectDB();

// Middleware
app.use(cors());
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: true }));

// Routes
app.use('/api/patients', patientRoutes);
app.use('/api/medical-records', medicalRecordRoutes);
app.use('/api/services', serviceRoutes);
app.use('/api/medicines', medicineRoutes);
app.use('/api/billing', billingRoutes);
app.use('/api/reports', reportRoutes);
app.use('/api/auth', authRoutes);

// Root route
app.get('/', (req, res) => {
  res.json({ 
    message: 'Clinic Management System API',
    version: '1.0.0',
    endpoints: {
      auth: '/api/auth',
      patients: '/api/patients',
      medicalRecords: '/api/medical-records',
      services: '/api/services',
      medicines: '/api/medicines',
      billing: '/api/billing',
      reports: '/api/reports'
    }
  });
});

// Error handler
app.use(errorHandler);

// Start server
const PORT = process.env.PORT || 5000;
app.listen(PORT, () => {
  console.log(`🚀 Server đang chạy tại http://localhost:${PORT}`);
});