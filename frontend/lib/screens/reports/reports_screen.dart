import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../config/theme.dart';
import '../../config/app_config.dart';
import '../../providers/auth_provider.dart';
import '../medical_records/medical_record_detail_screen.dart';
import '../../widgets/app_badge.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> with SingleTickerProviderStateMixin {
  final ApiService _api = ApiService();
  late TabController _tabController;

  bool _isLoading = true;
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  Map<String, dynamic>? _revenueData;
  Map<String, dynamic>? _visitData;
  List<dynamic>? _topServicesBilling;
  List<dynamic>? _topServicesRecord;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadReports();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadReports() async {
    setState(() => _isLoading = true);

    try {
      // Use ISO timestamps so backend can correctly include the entire end date.
      final startOfDay = DateTime(_startDate.year, _startDate.month, _startDate.day);
      final endOfDay = DateTime(_endDate.year, _endDate.month, _endDate.day, 23, 59, 59);
      final startIso = startOfDay.toIso8601String();
      final endIso = endOfDay.toIso8601String();

      // Load revenue report (separate try/catch so one failing endpoint doesn't block others)
      dynamic revenueResponse;
      try {
        revenueResponse = await _api.get(
          '${AppConfig.reportsEndpoint}/revenue?startDate=$startIso&endDate=$endIso',
        );
      } catch (e) {
        revenueResponse = {'success': false, 'message': e.toString()};
      }

      // Load patient visit report
      dynamic visitResponse;
      try {
        visitResponse = await _api.get(
          '${AppConfig.reportsEndpoint}/patient-visits?startDate=$startIso&endDate=$endIso',
        );
      } catch (e) {
        visitResponse = {'success': false, 'message': e.toString()};
      }

      // Load top services (backend may return { billingBased, recordBased } or an array for backward compatibility)
      dynamic servicesResponse;
      try {
        servicesResponse = await _api.get(
          '${AppConfig.reportsEndpoint}/top-services?startDate=$startIso&endDate=$endIso&limit=10',
        );
      } catch (e) {
        servicesResponse = {'success': false, 'message': e.toString()};
      }

      // Parse revenue response
      if (revenueResponse != null && revenueResponse['success'] == true) {
        _revenueData = revenueResponse['data'] as Map<String, dynamic>?;
      } else {
        _revenueData = null;
        if (mounted) {
          final msg = revenueResponse != null ? (revenueResponse['message'] ?? 'Lỗi báo cáo doanh thu') : 'Lỗi kết nối báo cáo doanh thu';
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
          });
        }
      }

  // Parse visit response
      if (visitResponse != null && visitResponse['success'] == true) {
        _visitData = visitResponse['data'] as Map<String, dynamic>?;
      } else {
        _visitData = null;
        if (mounted) {
          final msg = visitResponse != null ? (visitResponse['message'] ?? 'Lỗi báo cáo bệnh nhân') : 'Lỗi kết nối báo cáo bệnh nhân';
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
          });
        }
      }

      // Parse services response (backward-compatible)
      if (servicesResponse != null && servicesResponse['success'] == true) {
        final servicesData = servicesResponse['data'];
        List<dynamic> billingBased = [];
        List<dynamic> recordBased = [];

        if (servicesData is List) {
          billingBased = servicesData;
        } else if (servicesData is Map) {
          billingBased = (servicesData['billingBased'] as List<dynamic>?) ?? [];
          recordBased = (servicesData['recordBased'] as List<dynamic>?) ?? [];
        }

        _topServicesBilling = billingBased;
        _topServicesRecord = recordBased;
      } else {
        _topServicesBilling = [];
        _topServicesRecord = [];
        if (mounted) {
          final msg = servicesResponse != null ? (servicesResponse['message'] ?? 'Lỗi báo cáo dịch vụ') : 'Lỗi kết nối báo cáo dịch vụ';
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
          });
        }
      }

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi tải báo cáo: $e')),
          );
        });
      }
    }
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryGreen,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _loadReports();
    }
  }

  void _applyPresetDays(int days) {
    setState(() {
      _endDate = DateTime.now();
      _startDate = DateTime.now().subtract(Duration(days: days - 1));
    });
    _loadReports();
  }

  // Info dialog removed
  

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Báo cáo thống kê'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          indicatorPadding: const EdgeInsets.symmetric(horizontal: 16),
          labelStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          unselectedLabelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Doanh thu'),
            Tab(text: 'Bệnh nhân'),
            Tab(text: 'Dịch vụ'),
          ],
        ),
        actions: [
          Consumer<AuthProvider>(builder: (context, auth, _) {
            return IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: auth.isActive ? _loadReports : null,
              tooltip: auth.isActive ? 'Làm mới' : 'Tài khoản chưa kích hoạt',
            );
          }),
        ],
      ),
      body: Column(
        children: [
          // Date Range Selector + Presets
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  onTap: _selectDateRange,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppTheme.primaryGreen),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.date_range, color: AppTheme.primaryGreen),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            '${dateFormat.format(_startDate)} - ${dateFormat.format(_endDate)}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primaryGreen,
                            ),
                          ),
                        ),
                        const Icon(Icons.arrow_drop_down, color: AppTheme.primaryGreen),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    OutlinedButton(
                      onPressed: () => _applyPresetDays(1),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primaryGreen,
                        side: const BorderSide(color: AppTheme.primaryGreen),
                      ),
                      child: const Text('Hôm nay'),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: () => _applyPresetDays(7),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primaryGreen,
                        side: const BorderSide(color: AppTheme.primaryGreen),
                      ),
                      child: const Text('7 ngày'),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: () => _applyPresetDays(30),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primaryGreen,
                        side: const BorderSide(color: AppTheme.primaryGreen),
                      ),
                      child: const Text('30 ngày'),
                    ),
                    const Spacer(),
                    // (Removed debug/info/sample icons)
                  ],
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: _isLoading
                ? _buildLoadingSkeleton()
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildRevenueTab(),
                      _buildVisitTab(),
                      _buildServicesTab(),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueTab() {
    if (_revenueData == null) return const Center(child: Text('Không có dữ liệu'));

    final totalRevenue = _revenueData!['totalRevenue'] ?? 0;
    final totalBills = _revenueData!['totalBills'] ?? 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary Cards: only Total Revenue + Number of Bills
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.3,
            children: [
              _buildStatCard(
                'Tổng doanh thu',
                _formatCurrency(totalRevenue.toDouble()),
                Icons.attach_money,
                const LinearGradient(
                  colors: [Color(0xFF2E7D32), Color(0xFF4CAF50)],
                ),
              ),
              // Make the bills card tappable so users can view the invoice list filtered by the same date range
              GestureDetector(
                onTap: () {
                  final startOfDay = DateTime(_startDate.year, _startDate.month, _startDate.day);
                  final endOfDay = DateTime(_endDate.year, _endDate.month, _endDate.day, 23, 59, 59);
                  Navigator.pushNamed(
                    context,
                    '/billing',
                    arguments: {
                      'startDate': startOfDay.toIso8601String(),
                      'endDate': endOfDay.toIso8601String(),
                    },
                  );
                },
                child: _buildStatCard(
                  'Số hóa đơn',
                  totalBills.toString(),
                  Icons.receipt_long,
                  const LinearGradient(
                    colors: [Color(0xFF1976D2), Color(0xFF42A5F5)],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),
          // Only surface essential details per request
          _buildSectionTitle('Chi tiết doanh thu'),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildDetailRow('Tổng doanh thu', totalRevenue.toDouble()),
                  const Divider(),
                  _buildDetailRow('Số hóa đơn', totalBills.toDouble(), isBold: true, color: AppTheme.primaryGreen),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    // Simple skeleton UI: grey boxes resembling cards and detail rows
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.3,
            children: List.generate(4, (index) {
              return Container(
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(width: 36, height: 36, color: Colors.grey[300]),
                    const Spacer(),
                    Container(width: 120, height: 20, color: Colors.grey[300]),
                    const SizedBox(height: 8),
                    Container(width: 80, height: 14, color: Colors.grey[300]),
                  ],
                ),
              );
            }),
          ),

          const SizedBox(height: 24),
          Container(
            height: 140,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVisitTab() {
    if (_visitData == null) return const Center(child: Text('Không có dữ liệu'));

    final totalVisits = _visitData!['totalVisits'] ?? 0;
    final patientTypes = _visitData!['patientTypes'] as Map<String, dynamic>? ?? {};
  final visits = (_visitData!['visits'] as List<dynamic>?) ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Total Visits Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: AppGradients.primaryGradient,
              borderRadius: BorderRadius.circular(12),
              boxShadow: AppShadows.cardShadowLight,
            ),
            child: Column(
              children: [
                const Icon(Icons.people, color: Colors.white, size: 48),
                const SizedBox(height: 12),
                const Text(
                  'Tổng lượt khám',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  totalVisits.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 56,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
          _buildSectionTitle('Phân loại bệnh nhân'),
          const SizedBox(height: 12),

          // Patient Types
          if (patientTypes.isNotEmpty) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: patientTypes.entries.map((entry) {
                    final type = entry.key;
                    final count = entry.value as int;
                    final percentage = totalVisits > 0 
                        ? (count / totalVisits * 100).toStringAsFixed(1)
                        : '0.0';
                    
                    Color color;
                    switch (type) {
                      case 'BHYT':
                        color = AppTheme.secondaryBlue;
                        break;
                      case 'VIP':
                        color = AppTheme.accentOrange;
                        break;
                      default:
                        color = AppTheme.primaryGreen;
                    }

                    return Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                type,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Text(
                              '$count ($percentage%)',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: color,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: count / totalVisits,
                          backgroundColor: color.withValues(alpha: 51),
                          valueColor: AlwaysStoppedAnimation<Color>(color),
                          minHeight: 8,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        if (entry.key != patientTypes.keys.last)
                          const Divider(height: 24),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],

          const SizedBox(height: 24),
          // List of visit rows (one per recorded visit)
          _buildSectionTitle('Danh sách bệnh nhân'),
          const SizedBox(height: 12),
          if (visits.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Không có lượt khám trong phạm vi thời gian này.'),
              ),
            )
          else
            Card(
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: visits.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final v = visits[index] as Map<String, dynamic>;
                  final patient = v['patient'] as Map<String, dynamic>?;
                  final name = patient != null ? (patient['name'] ?? 'Bệnh nhân') : 'Bệnh nhân';
                  final type = patient != null ? (patient['patientType'] ?? '') : '';
                  final visitDateRaw = v['visitDate'];
                  String visitDateStr = '';
                  try {
                    visitDateStr = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(visitDateRaw));
                  } catch (_) {
                    visitDateStr = visitDateRaw?.toString() ?? '';
                  }

                  return ListTile(
                    title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text('${(type ?? 'Không xác định')} • $visitDateStr'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      // Open the medical record detail for this visit
                      final recordId = v['_id']?.toString();
                      if (recordId != null && recordId.isNotEmpty) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => MedicalRecordDetailScreen(recordId: recordId),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Không tìm thấy id hồ sơ')));
                      }
                    },
                  );
                },
              ),
            ),

          
        ],
      ),
    );
  }

  Widget _buildServicesTab() {
    final billing = _topServicesBilling ?? [];
    final record = _topServicesRecord ?? [];

    if ((billing.isEmpty) && (record.isEmpty)) {
      return const Center(child: Text('Không có dữ liệu'));
    }

    return LayoutBuilder(builder: (context, constraints) {
      final isWide = constraints.maxWidth >= 800;

      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: isWide
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildServicesColumn('Dựa trên hóa đơn', billing)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildServicesColumn('Dựa trên hồ sơ khám', record)),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildServicesColumn('Dựa trên hóa đơn', billing),
                  const SizedBox(height: 16),
                  _buildServicesColumn('Dựa trên hồ sơ khám', record),
                ],
              ),
      );
    });
  }

  Widget _buildServicesColumn(String title, List<dynamic> services) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(title),
        const SizedBox(height: 8),
        
        const SizedBox(height: 12),

        // Totals summary
        Builder(builder: (context) {
          final totalServices = services.length;
          final totalUses = services.fold<int>(0, (sum, item) {
            final c = (item is Map && item['count'] != null) ? (item['count'] as num).toInt() : 0;
            return sum + c;
          });
          final totalRevenue = services.fold<double>(0.0, (sum, item) {
            num r = 0;
            if (item is Map) {
              r = (item['totalRevenue'] ?? item['revenue'] ?? 0) as num;
            }
            return sum + r.toDouble();
          });

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Số mục', style: TextStyle(fontSize: 12, color: AppTheme.darkGrey)),
                        const SizedBox(height: 6),
                        Text(totalServices.toString(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Tổng lượt', style: TextStyle(fontSize: 12, color: AppTheme.darkGrey)),
                        const SizedBox(height: 6),
                        Text(totalUses.toString(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('Tổng doanh thu', style: TextStyle(fontSize: 12, color: AppTheme.darkGrey)),
                        const SizedBox(height: 6),
                        Text(
                          _formatCurrency(totalRevenue),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }),

        if (services.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Không có dịch vụ trong phạm vi thời gian này.'),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: services.length,
            itemBuilder: (context, index) {
              final service = services[index] as Map<String, dynamic>;
              final serviceName = service['serviceName'] ?? 'N/A';
              final count = service['count'] ?? 0;
              final revenue = (service['totalRevenue'] ?? service['revenue'] ?? 0);

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: AppBadge(
                    radius: 20,
                    backgroundColor: AppTheme.primaryGreen,
                    showRing: false,
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    serviceName,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text('$count lần sử dụng'),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'Doanh thu',
                        style: TextStyle(fontSize: 11, color: AppTheme.grey),
                      ),
                      Text(
                        _formatCurrency((revenue as num).toDouble()),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryGreen,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Gradient gradient) {
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
          Icon(icon, color: Colors.white, size: 36),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: AppTheme.primaryGreen,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.black,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, double value, 
      {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isBold ? 18 : 16,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: AppTheme.darkGrey,
            ),
          ),
          Text(
            _formatCurrency(value),
            style: TextStyle(
              fontSize: isBold ? 20 : 18,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: color ?? AppTheme.black,
            ),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(double value) {
    final amount = value.toInt();
    return '${amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}đ';
  }
}