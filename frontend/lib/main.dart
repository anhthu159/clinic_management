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
import 'screens/medical_records/medical_record_detail_screen.dart';
import 'screens/medical_records/add_medical_record_screen.dart';
import 'screens/billing/billing_list_screen.dart';
import 'screens/billing/billing_detail_screen.dart';
import 'screens/reports/reports_screen.dart';
import 'services/service_list_screen.dart';
import 'services/medicine_list_screen.dart';
import 'models/patient.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/admin/user_management_screen.dart';

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
              return MaterialPageRoute(
                builder: (_) => RoleGuard(
                  canAccess: (auth) => auth.canCreatePatient,
                  child: const AddPatientScreen(),
                ),
              );
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
                builder: (_) => RoleGuard(
                  canAccess: (auth) => auth.canCreateMedicalRecord,
                  child: AddMedicalRecordScreen(patientId: patientId),
                ),
              );

            case '/medical-records/detail':
              final recordId = settings.arguments as String;
              return MaterialPageRoute(
                builder: (_) => MedicalRecordDetailScreen(recordId: recordId),
              );
            
            // Billing
            case '/billing':
              final args = settings.arguments as Map<String, dynamic>?;
              return MaterialPageRoute(
                builder: (_) => RoleGuard(
                  canAccess: (auth) => auth.canManageBilling,
                  child: BillingListScreen(
                    startDateIso: args?['startDate'] as String?,
                    endDateIso: args?['endDate'] as String?,
                  ),
                ),
              );
            case '/billing/detail':
              final billingId = settings.arguments as String;
              return MaterialPageRoute(
                builder: (_) => RoleGuard(
                  canAccess: (auth) => auth.canManageBilling,
                  child: BillingDetailScreen(billingId: billingId),
                ),
              );
            
            // Reports
            case '/reports':
              return MaterialPageRoute(
                builder: (_) => RoleGuard(
                  canAccess: (auth) => auth.canViewReports,
                  child: const ReportsScreen(),
                ),
              );
            
            // Services & Medicines
            case '/services':
              return MaterialPageRoute(
                builder: (_) => RoleGuard(
                  canAccess: (auth) => auth.canManageServices,
                  child: const ServiceListScreen(),
                ),
              );
            case '/medicines':
              return MaterialPageRoute(
                builder: (_) => RoleGuard(
                  canAccess: (auth) => auth.canManageMedicines,
                  child: const MedicineListScreen(),
                ),
              );

            // Profile
            case '/profile':
              return MaterialPageRoute(builder: (_) => const ProfileScreen());
            // Users (admin only)
            case '/users':
              return MaterialPageRoute(
                builder: (_) => RoleGuard(
                  canAccess: (auth) => auth.isAdmin && auth.isActive,
                  child: const UserManagementScreen(),
                ),
              );
            
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
    // Đặt lịch để kiểm tra auth sau khi widget được build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AuthProvider>(context, listen: false).checkAuthStatus();
    });
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

        // Only treat the user as signed-in if authenticated AND active.
        if (authProvider.isAuthenticated && authProvider.isActive) {
          return const DashboardScreen();
        }

        // If authenticated but not active, we fall back to LoginScreen. The
        // provider will have cleared auth state if the token was invalid or
        // the account is inactive.
        return const LoginScreen();
      },
    );
  }
}

/// Simple role-based guard widget used in route builders.
/// It reads the current `AuthProvider` and evaluates `canAccess`.
/// If the check fails it shows a small permission-denied screen.
class RoleGuard extends StatelessWidget {
  final Widget child;
  final bool Function(AuthProvider) canAccess;

  const RoleGuard({super.key, required this.child, required this.canAccess});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(builder: (context, auth, _) {
      if (auth.isAuthenticated && canAccess(auth)) return child;

      return Scaffold(
        appBar: AppBar(title: const Text('Không có quyền')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_outline, size: 72, color: AppTheme.grey),
              const SizedBox(height: 16),
              Text(
                'Bạn không có quyền truy cập vào trang này',
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
                child: const Text('Quay về'),
              ),
            ],
          ),
        ),
      );
    });
  }
}