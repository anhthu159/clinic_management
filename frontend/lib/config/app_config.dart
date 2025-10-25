class AppConfig {
  // API Configuration
  // Cho Android Emulator: 10.0.2.2
  // Cho iOS Simulator: localhost
  // Cho thiết bị thật: IP máy tính (vd: 192.168.1.100)
  static const String baseUrl = 'http://10.0.2.2:5000/api';
  
  // Alternative URLs (uncomment khi cần)
  // static const String baseUrl = 'http://localhost:5000/api'; // iOS
  // static const String baseUrl = 'http://192.168.1.100:5000/api'; // Real device
  
  // Endpoints
  static const String loginEndpoint = '/auth/login';
  static const String registerEndpoint = '/auth/register';
  static const String meEndpoint = '/auth/me';
  static const String changePasswordEndpoint = '/auth/change-password';
  static const String updateProfileEndpoint = '/auth/profile';
  
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
  static const String apiDateFormat = 'yyyy-MM-dd';
  
  // Pagination
  static const int pageSize = 20;
  
  // App Info
  static const String appName = 'Quản lý Phòng khám';
  static const String appVersion = '1.0.0';
  static const String appDescription = 'Hệ thống quản lý phòng khám tư nhân';
  
  // Timeout
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  
  // Validation
  static const int minPasswordLength = 6;
  static const int phoneLength = 10;
  
  // Status
  static const List<String> appointmentStatuses = [
    'Chờ khám',
    'Đã khám',
    'Hủy',
    'Không đến'
  ];
  
  static const List<String> medicalRecordStatuses = [
    'Đang khám',
    'Hoàn thành',
    'Hủy'
  ];
  
  static const List<String> paymentStatuses = [
    'Chưa thanh toán',
    'Đã thanh toán',
    'Thanh toán một phần'
  ];
  
  static const List<String> patientTypes = [
    'Thường',
    'BHYT',
    'VIP'
  ];
  
  static const List<String> genders = [
    'Nam',
    'Nữ',
    'Khác'
  ];
  
  static const List<String> roles = [
    'admin',
    'doctor',
    'receptionist',
    'accountant'
  ];
  
  static String getRoleDisplayName(String role) {
    switch (role) {
      case 'admin':
        return 'Quản trị viên';
      case 'doctor':
        return 'Bác sĩ';
      case 'receptionist':
        return 'Lễ tân';
      case 'accountant':
        return 'Kế toán';
      default:
        return role;
    }
  }
}