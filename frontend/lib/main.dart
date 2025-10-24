import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/theme.dart';
import 'providers/auth_provider.dart';
import 'services/storage_service.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/patients/patient_list_screen.dart';
import 'screens/patients/add_patient_screen.dart';
import 'screens/patients/patient_detail_screen.dart';
import 'screens/patients/edit_patient_screen.dart';
import 'screens/appointments/appointment_list_screen.dart';
import 'screens/appointments/add_appointment_screen.dart';
import 'screens/medical_records/medical_record_list_screen.dart';
import 'screens/medical_records/add_medical_record_screen.dart';
import 'screens/billing/billing_list_screen.dart';
import 'screens/reports/reports_screen.dart';
import 'screens/services/service_list_screen.dart';
import 'screens/medicines/medicine_list_screen.dart';
import 'models/patient.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize storage
  await StorageService().init();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: MaterialApp(
        title: 'Quản lý Phòng khám',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const AuthWrapper(),
        onGenerateRoute: (settings) {
          switch (settings.name) {
            // Auth
            case '/login':
              return MaterialPageRoute(builder: (_) => const LoginScreen());
            case '/register':
              return MaterialPageRoute(builder: (_) => const RegisterScreen());
            case '/dashboard':
              return MaterialPageRoute(builder: (_) => const DashboardScreen());
            
            // Patients
            case '/patients':
              return MaterialPageRoute(builder: (_) => const PatientListScreen());
            case '/patients/add':
              return MaterialPageRoute(builder: (_) => const AddPatientScreen());
            case '/patients/detail':
              final patientId = settings.arguments as String;
              return MaterialPageRoute(
                builder: (_) => PatientDetailScreen(patientId: patientId),
              );
            case '/patients/edit':
              final patient = settings.arguments as Patient;
              return MaterialPageRoute(
                builder: (_) => EditPatientScreen(patient: patient),
              );
            
            // Appointments
            case '/appointments':
              return MaterialPageRoute(builder: (_) => const AppointmentListScreen());
            case '/appointments/add':
              return MaterialPageRoute(builder: (_) => const AddAppointmentScreen());
            
            // Medical Records
            case '/medical-records':
              final args = settings.arguments as Map<String, dynamic>?;
              return MaterialPageRoute(
                builder: (_) => MedicalRecordListScreen(
                  patientId: args?['patientId'],
                ),
              );
            case '/medical-records/add':
              final patientId = settings.arguments as String?;
              return MaterialPageRoute(
                builder: (_) => AddMedicalRecordScreen(patientId: patientId),
              );
            
            // Billing
            case '/billing':
              return MaterialPageRoute(builder: (_) => const BillingListScreen());
            
            // Reports
            case '/reports':
              return MaterialPageRoute(builder: (_) => const ReportsScreen());
            
            // Services & Medicines
            case '/services':
              return MaterialPageRoute(builder: (_) => const ServiceListScreen());
            case '/medicines':
              return MaterialPageRoute(builder: (_) => const MedicineListScreen());
            
            default:
              return MaterialPageRoute(
                builder: (_) => Scaffold(
                  appBar: AppBar(title: const Text('404')),
                  body: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 80, color: AppTheme.error),
                        SizedBox(height: 16),
                        Text(
                          '404 - Trang không tồn tại',
                          style: TextStyle(fontSize: 18),
                        ),
                      ],
                    ),
                  ),
                ),
              );
          }
        },
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.checkAuthStatus();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        if (authProvider.isLoading) {
          return Scaffold(
            body: Container(
              decoration: const BoxDecoration(
                gradient: AppGradients.primaryGradient,
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.local_hospital, size: 80, color: Colors.white),
                    SizedBox(height: 24),
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      'Đang tải...',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        if (authProvider.isAuthenticated) {
          return const DashboardScreen();
        }

        return const LoginScreen();
      },
    );
  }
}: (_) => const AddAppointmentScreen());
            
            // Medical Records
            case '/medical-records':
              final args = settings.arguments as Map<String, dynamic>?;
              return MaterialPageRoute(
                builder: (_) => MedicalRecordListScreen(
                  patientId: args?['patientId'],
                ),
              );
            case '/medical-records/add':
              final patientId = settings.arguments as String?;
              return MaterialPageRoute(
                builder: (_) => AddMedicalRecordScreen(patientId: patientId),
              );
            
            // Billing
            case '/billing':
              return MaterialPageRoute(builder: (_) => const BillingListScreen());
            
            // Reports
            case '/reports':
              return MaterialPageRoute(builder: (_) => const ReportsScreen());
            
            default:
              return MaterialPageRoute(
                builder: (_) => const Scaffold(
                  body: Center(child: Text('404 - Page not found')),
                ),
              );
          }
        },
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.checkAuthStatus();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        if (authProvider.isLoading) {
          return Scaffold(
            body: Container(
              decoration: const BoxDecoration(
                gradient: AppGradients.primaryGradient,
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.local_hospital, size: 80, color: Colors.white),
                    SizedBox(height: 24),
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      'Đang tải...',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        if (authProvider.isAuthenticated) {
          return const DashboardScreen();
        }

        return const LoginScreen();
      },
    );
  }
}