import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../config/theme.dart';
import '../../config/app_config.dart';

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải dữ liệu: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userName = authProvider.userName;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trang chủ'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStats,
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.account_circle),
            onSelected: (value) {
              if (value == 'logout') {
                _handleLogout();
              } else if (value == 'profile') {
                Navigator.pushNamed(context, '/profile');
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: const [
                    Icon(Icons.person, color: AppTheme.primaryGreen),
                    SizedBox(width: 8),
                    Text('Hồ sơ'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: const [
                    Icon(Icons.logout, color: AppTheme.error),
                    SizedBox(width: 8),
                    Text('Đăng xuất'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      drawer: _buildDrawer(context, authProvider),
      body: RefreshIndicator(
        onRefresh: _loadStats,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Welcome Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: AppGradients.primaryGradient,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: AppShadows.cardShadow,
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.waving_hand,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Xin chào, $userName!',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Chào mừng bạn trở lại',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Statistics Cards
                    Text(
                      'Thống kê hôm nay',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.5,
                      children: [
                        _buildStatCard(
                          icon: Icons.people,
                          title: 'Tổng bệnh nhân',
                          value: '${_stats?['totalPatients'] ?? 0}',
                          color: AppTheme.primaryGreen,
                          gradient: const LinearGradient(
                            colors: [Color(0xFF2E7D32), Color(0xFF4CAF50)],
                          ),
                        ),
                        _buildStatCard(
                          icon: Icons.medical_services,
                          title: 'Lượt khám hôm nay',
                          value: '${_stats?['totalRecordsToday'] ?? 0}',
                          color: AppTheme.secondaryBlue,
                          gradient: const LinearGradient(
                            colors: [Color(0xFF1976D2), Color(0xFF42A5F5)],
                          ),
                        ),
                        _buildStatCard(
                          icon: Icons.attach_money,
                          title: 'Doanh thu hôm nay',
                          value: _formatCurrency(_stats?['todayRevenue'] ?? 0),
                          color: AppTheme.accentOrange,
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF9800), Color(0xFFFFB74D)],
                          ),
                          isSmallText: true,
                        ),
                        _buildStatCard(
                          icon: Icons.pending_actions,
                          title: 'Chưa thanh toán',
                          value: '${_stats?['pendingPayments'] ?? 0}',
                          color: AppTheme.accentRed,
                          gradient: const LinearGradient(
                            colors: [Color(0xFFE53935), Color(0xFFEF5350)],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Quick Actions
                    Text(
                      'Thao tác nhanh',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    GridView.count(
                      crossAxisCount: 3,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1,
                      children: [
                        _buildQuickAction(
                          icon: Icons.person_add,
                          label: 'Tiếp nhận',
                          onTap: () => Navigator.pushNamed(context, '/patients/add'),
                        ),
                        _buildQuickAction(
                          icon: Icons.calendar_today,
                          label: 'Lịch hẹn',
                          onTap: () => Navigator.pushNamed(context, '/appointments'),
                        ),
                        _buildQuickAction(
                          icon: Icons.assignment,
                          label: 'Khám bệnh',
                          onTap: () => Navigator.pushNamed(context, '/medical-records'),
                        ),
                        _buildQuickAction(
                          icon: Icons.receipt_long,
                          label: 'Thanh toán',
                          onTap: () => Navigator.pushNamed(context, '/billing'),
                        ),
                        _buildQuickAction(
                          icon: Icons.medication,
                          label: 'Thuốc',
                          onTap: () => Navigator.pushNamed(context, '/medicines'),
                        ),
                        _buildQuickAction(
                          icon: Icons.analytics,
                          label: 'Báo cáo',
                          onTap: () => Navigator.pushNamed(context, '/reports'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    required Gradient gradient,
    bool isSmallText = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppShadows.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: Colors.white, size: 32),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isSmallText ? 18 : 24,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: AppShadows.cardShadow,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppTheme.primaryGreen, size: 28),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppTheme.darkGrey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, AuthProvider authProvider) {
    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              gradient: AppGradients.primaryGradient,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person, size: 50, color: AppTheme.primaryGreen),
                ),
                const SizedBox(height: 12),
                Text(
                  authProvider.userName ?? 'User',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  authProvider.userRole ?? '',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildDrawerItem(
                  icon: Icons.dashboard,
                  title: 'Trang chủ',
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.people,
                  title: 'Quản lý bệnh nhân',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/patients');
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.calendar_today,
                  title: 'Lịch hẹn',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/appointments');
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.assignment,
                  title: 'Hồ sơ khám bệnh',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/medical-records');
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.receipt_long,
                  title: 'Thanh toán',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/billing');
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.medical_services,
                  title: 'Dịch vụ',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/services');
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.medication,
                  title: 'Thuốc',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/medicines');
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.analytics,
                  title: 'Báo cáo thống kê',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/reports');
                  },
                ),
                const Divider(),
                _buildDrawerItem(
                  icon: Icons.settings,
                  title: 'Cài đặt',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/settings');
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primaryGreen),
      title: Text(title),
      onTap: onTap,
    );
  }

  String _formatCurrency(dynamic value) {
    if (value == null) return '0đ';
    final amount = value is int ? value : (value as num).toInt();
    return '${amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}đ';
  }

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận đăng xuất'),
        content: const Text('Bạn có chắc chắn muốn đăng xuất?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await Provider.of<AuthProvider>(context, listen: false).logout();
              if (mounted) {
                Navigator.of(context).pushReplacementNamed('/login');
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );
  }
}