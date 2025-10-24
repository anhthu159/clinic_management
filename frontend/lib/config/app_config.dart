class AppConfig {
  // API Configuration
  static const String baseUrl = 'http://localhost:5000/api';
  
  // Endpoints
  static const String loginEndpoint = '/auth/login';
  static const String registerEndpoint = '/auth/register';
  static const String meEndpoint = '/auth/me';
  
  static const String patientsEndpoint = '/patients';
  static const String appointmentsEndpoint = '/appointments';
  static const String medicalRecordsEndpoint = '/medical-records';
  static const String servicesEndpoint = '/services';
  static const String medicinesEndpoint = '/medicines';
  static const String billingEndpoint = '/billing';
  static const String reportsEndpoint = '/reports';
  static const String usersEndpoint = '/users';
  
  // Storage Keys
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';
  
  // Date Format
  static const String dateFormat = 'dd/MM/yyyy';
  static const String timeFormat = 'HH:mm';
  static const String dateTimeFormat = 'dd/MM/yyyy HH:mm';
  
  // Pagination
  static const int pageSize = 20;
  
  // App Info
  static const String appName = 'Quản lý Phòng khám';
  static const String appVersion = '1.0.0';
}