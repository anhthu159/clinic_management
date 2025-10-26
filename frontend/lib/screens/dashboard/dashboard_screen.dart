import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../config/app_config.dart';
import '../../config/theme.dart';
import '../../widgets/app_badge.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ApiService _api = ApiService();
  Map<String, dynamic>? _stats;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    try {
      final response = await _api.get('${AppConfig.reportsEndpoint}/dashboard');
      if (response['success']) {
        setState(() {
          _stats = response['data'];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi tải dữ liệu: $e')),
          );
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    

  // Palette (use AppTheme constants for consistency)
  final primaryGreen = AppTheme.darkGreen;
  final accentGreen = AppTheme.lightGreen;
  final cardMint = AppTheme.lightGrey; // fallback light card background
  final bg = AppTheme.lightGrey;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        elevation: 2,
        titleSpacing: 16,
        // simplified title for a cleaner header
        title: const Text('Phòng khám', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            tooltip: 'Làm mới',
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: auth.isActive ? _loadStats : null,
          ),
          PopupMenuButton<String>(
            tooltip: 'Tài khoản',
            icon: const Icon(Icons.account_circle_rounded, color: Colors.white, size: 28),
            onSelected: (value) {
              if (value == 'profile') {
                Navigator.pushNamed(context, '/profile');
              } else if (value == 'logout') {
                _handleLogout();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'profile', child: Text('Hồ sơ')),
              const PopupMenuItem(value: 'logout', child: Text('Đăng xuất')),
            ],
          ),
        ],
      ),
      drawer: _buildDrawer(context, auth), // drawer/menu restored
      body: RefreshIndicator(
        color: accentGreen,
        onRefresh: _loadStats,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header banner (subtle)
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [primaryGreen, accentGreen],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: primaryGreen.withValues(alpha: 20),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                      child: Row(
                        children: [
                          AppBadge(
                            radius: 22,
                            backgroundColor: Colors.white,
                            icon: Icons.health_and_safety_rounded,
                            iconColor: primaryGreen,
                            showRing: true,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Trang chủ',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                    )),
                                const SizedBox(height: 4),
                                Text('Tổng quan hệ thống phòng khám',
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 242),
                                      fontSize: 13,
                                    )),
                              ],
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: () => Navigator.pushNamed(context, '/reports'),
                            icon: const Icon(Icons.analytics_outlined, size: 18),
                            label: const Text('Báo cáo'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: primaryGreen,
                              elevation: 4,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 22),

                    // Title
                    Text(
                      'Tổng quan hôm nay',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: primaryGreen,
                          ),
                    ),
                    const SizedBox(height: 14),

                    // Stats grid (cards)
                    LayoutBuilder(builder: (context, constraints) {
                      int crossAxisCount = constraints.maxWidth > 900 ? 4 : 2;
                      return GridView.count(
                        crossAxisCount: crossAxisCount,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 1.05,
                        children: [
                          _statCardPro(
                            icon: Icons.people_alt_rounded,
                            title: 'Bệnh nhân',
                            value: '${_stats?['totalPatients'] ?? 0}',
                            color: const Color(0xFF1B5E20),
                            bg: cardMint,
                          ),
                          _statCardPro(
                            icon: Icons.medical_services_rounded,
                            title: 'Lượt khám',
                            value: '${_stats?['totalRecordsToday'] ?? 0}',
                            color: const Color(0xFF2E7D32),
                            bg: cardMint,
                          ),
                          _statCardPro(
                            icon: Icons.attach_money_rounded,
                            title: 'Doanh thu',
                            value: _formatCurrency(_stats?['todayRevenue'] ?? 0),
                            color: const Color(0xFF4CAF50),
                            bg: cardMint,
                          ),
                          _statCardPro(
                            icon: Icons.pending_actions_rounded,
                            title: 'Chưa thanh toán',
                            value: '${_stats?['pendingPayments'] ?? 0}',
                            color: const Color(0xFFD32F2F),
                            bg: cardMint,
                          ),
                        ],
                      );
                    }),

                    const SizedBox(height: 28),

                    // Quick actions label
                  // Thao tác nhanh – layout đều hàng hơn, responsive mobile
                  // --- Thao tác nhanh: Responsive, đều hàng, cân lề ---
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Thao tác nhanh',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: primaryGreen,
                              ),
                        ),
                        const SizedBox(height: 14),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final crossAxisCount = constraints.maxWidth > 600 ? 4 : 3;
                            final itemSpacing = 14.0;
              // itemWidth intentionally unused — layout handled by GridView

                            final quickActions = [
                              if (auth.canCreatePatient)
                                _quickActionTile(Icons.person_add, 'Tiếp nhận', '/patients/add', primaryGreen),
                              _quickActionTile(Icons.calendar_today, 'Lịch hẹn', '/appointments', const Color(0xFF2E7D32)),
                              if (auth.canCreateMedicalRecord)
                                _quickActionTile(Icons.assignment, 'Khám bệnh', '/medical-records', const Color(0xFF388E3C)),
                              if (auth.canManageBilling)
                                _quickActionTile(Icons.receipt_long, 'Thanh toán', '/billing', const Color(0xFF4CAF50)),
                              if (auth.canManageMedicines)
                                _quickActionTile(Icons.medication, 'Thuốc', '/medicines', const Color(0xFF66BB6A)),
                              if (auth.canViewReports)
                                _quickActionTile(Icons.analytics, 'Báo cáo', '/reports', accentGreen),
                              if (auth.isAdmin && auth.isActive)
                                _quickActionTile(Icons.manage_accounts, 'Người dùng', '/users', const Color(0xFF8BC34A)),
                            ];

                            return GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: quickActions.length,
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                crossAxisSpacing: itemSpacing,
                                mainAxisSpacing: itemSpacing,
                                childAspectRatio: 1,
                              ),
                              itemBuilder: (context, index) => quickActions[index],
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                    const SizedBox(height: 26),
                  ],
                ),
              ),
      ),
    );
  }

  // --- Pro stat card (elevated, crisp) ---
  Widget _statCardPro({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    required Color bg,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
  border: Border.all(color: color.withValues(alpha: 20)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 15),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 14),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // circular icon badge with subtle glow
          Container(
            // white circular badge with subtle ring — cleaner and more modern
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(color: color.withValues(alpha: 15)),
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6, offset: const Offset(0, 3))],
            ),
            padding: const EdgeInsets.all(10),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: color),
          ),
          const SizedBox(height: 6),
          Text(title, style: const TextStyle(fontSize: 13, color: Colors.black54)),
        ],
      ),
    );
  }

  // --- Quick action tile (clean card) ---
  Widget _quickActionTile(IconData icon, String label, String route, Color color) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => Navigator.pushNamed(context, route),
      child: Container(
        width: 140,
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 10)),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: const Offset(0, 3))],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBadge(
              radius: 22,
              backgroundColor: color,
              icon: icon,
              showRing: false,
            ),
            const SizedBox(height: 8),
            Text(label, textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black87)),
          ],
        ),
      ),
    );
  }

  // --- Drawer (restored menu) ---
  Widget _buildDrawer(BuildContext context, AuthProvider authProvider) {
    return Drawer(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 48, bottom: 28),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1B5E20), Color(0xFF4CAF50)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(26),
                bottomRight: Radius.circular(26),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 6,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 15),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      )
                    ],
                  ),
                  child: AppBadge(
                    radius: 38,
                    backgroundColor: Colors.white,
                    icon: Icons.person,
                    iconColor: const Color(0xFF1B5E20),
                    showRing: false,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  authProvider.userName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 46),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    authProvider.userRole ?? '',
                    style: TextStyle(
                      color: AppTheme.primaryGreen,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),


          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildDrawerItem(Icons.dashboard, 'Trang chủ', () {
                  Navigator.pop(context);
                }),
                _buildDrawerItem(Icons.people, 'Quản lý bệnh nhân', () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/patients');
                }),
                _buildDrawerItem(Icons.calendar_today, 'Lịch hẹn', () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/appointments');
                }),
                _buildDrawerItem(Icons.assignment, 'Hồ sơ khám bệnh', () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/medical-records');
                }),
                if (authProvider.canManageBilling)
                  _buildDrawerItem(Icons.receipt_long, 'Thanh toán', () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/billing');
                  }),
                if (authProvider.canManageServices)
                  _buildDrawerItem(Icons.medical_services, 'Dịch vụ', () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/services');
                  }),
                if (authProvider.isAdmin && authProvider.isActive)
                  _buildDrawerItem(Icons.manage_accounts, 'Quản lý người dùng', () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/users');
                  }),
                if (authProvider.canManageMedicines)
                  _buildDrawerItem(Icons.medication, 'Thuốc', () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/medicines');
                  }),
                if (authProvider.canViewReports)
                  _buildDrawerItem(Icons.analytics, 'Báo cáo thống kê', () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/reports');
                  }),
                const Divider(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF1B5E20)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      onTap: onTap,
    );
  }

  String _formatCurrency(dynamic value) {
    if (value == null) return '0đ';
    final amount = value is int ? value : (value as num).toInt();
    return '${amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}đ';
  }

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận đăng xuất'),
        content: const Text('Bạn có chắc chắn muốn đăng xuất?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              navigator.pop();
              await Provider.of<AuthProvider>(context, listen: false).logout();
              if (mounted) navigator.pushReplacementNamed('/login');
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Đăng xuất'),
          )
        ],
      ),
    );
  }
}
