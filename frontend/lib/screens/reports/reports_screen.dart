import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
// import 'package:fl_chart/fl_chart.dart';
import '../../services/api_service.dart';
import '../../config/theme.dart';
import '../../config/app_config.dart';

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
  List<dynamic>? _topServices;

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
      final dateFormat = DateFormat('yyyy-MM-dd');
      final startDateStr = dateFormat.format(_startDate);
      final endDateStr = dateFormat.format(_endDate);

      // Load revenue report
      final revenueResponse = await _api.get(
        '${AppConfig.reportsEndpoint}/revenue?startDate=$startDateStr&endDate=$endDateStr',
      );
      
      // Load patient visit report
      final visitResponse = await _api.get(
        '${AppConfig.reportsEndpoint}/patient-visits?startDate=$startDateStr&endDate=$endDateStr',
      );
      
      // Load top services
      final servicesResponse = await _api.get(
        '${AppConfig.reportsEndpoint}/top-services?startDate=$startDateStr&endDate=$endDateStr&limit=10',
      );

      if (revenueResponse['success'] && visitResponse['success'] && servicesResponse['success']) {
        setState(() {
          _revenueData = revenueResponse['data'];
          _visitData = visitResponse['data'];
          _topServices = servicesResponse['data'];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải báo cáo: $e')),
        );
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

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Báo cáo thống kê'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Doanh thu'),
            Tab(text: 'Bệnh nhân'),
            Tab(text: 'Dịch vụ'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadReports,
          ),
        ],
      ),
      body: Column(
        children: [
          // Date Range Selector
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: InkWell(
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
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryGreen,
                        ),
                      ),
                    ),
                    const Icon(Icons.arrow_drop_down, color: AppTheme.primaryGreen),
                  ],
                ),
              ),
            ),
          ),

          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
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
    final totalDiscount = _revenueData!['totalDiscount'] ?? 0;
    final averagePerBill = _revenueData!['averagePerBill'] ?? 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary Cards
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
              _buildStatCard(
                'Số hóa đơn',
                totalBills.toString(),
                Icons.receipt_long,
                const LinearGradient(
                  colors: [Color(0xFF1976D2), Color(0xFF42A5F5)],
                ),
              ),
              _buildStatCard(
                'Giảm giá',
                _formatCurrency(totalDiscount.toDouble()),
                Icons.discount,
                const LinearGradient(
                  colors: [Color(0xFFFF9800), Color(0xFFFFB74D)],
                ),
              ),
              _buildStatCard(
                'TB/Hóa đơn',
                _formatCurrency(averagePerBill.toDouble()),
                Icons.calculate,
                const LinearGradient(
                  colors: [Color(0xFF7B1FA2), Color(0xFFBA68C8)],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),
          _buildSectionTitle('Chi tiết doanh thu'),
          const SizedBox(height: 12),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildDetailRow('Tổng doanh thu', totalRevenue.toDouble()),
                  const Divider(),
                  _buildDetailRow('Tổng giảm giá', totalDiscount.toDouble(), 
                      color: AppTheme.accentOrange),
                  const Divider(),
                  _buildDetailRow('Doanh thu thuần', 
                      (totalRevenue - totalDiscount).toDouble(),
                      isBold: true, color: AppTheme.primaryGreen),
                ],
              ),
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
              boxShadow: AppShadows.cardShadow,
            ),
            child: Column(
              children: [
                const Icon(Icons.people, color: Colors.white, size: 48),
                const SizedBox(height: 12),
                const Text(
                  'Tổng lượt khám',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  totalVisits.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 48,
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
        ],
      ),
    );
  }

  Widget _buildServicesTab() {
    if (_topServices == null || _topServices!.isEmpty) {
      return const Center(child: Text('Không có dữ liệu'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Top 10 dịch vụ sử dụng nhiều nhất'),
          const SizedBox(height: 12),

          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _topServices!.length,
            itemBuilder: (context, index) {
              final service = _topServices![index];
              final serviceName = service['serviceName'] ?? 'N/A';
              final count = service['count'] ?? 0;
              final revenue = service['totalRevenue'] ?? 0;

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppTheme.primaryGreen,
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
                        _formatCurrency(revenue.toDouble()),
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
      ),
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
          Icon(icon, color: Colors.white, size: 28),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 230),
              fontSize: 12,
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
            fontSize: 18,
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
              fontSize: isBold ? 16 : 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: AppTheme.darkGrey,
            ),
          ),
          Text(
            _formatCurrency(value),
            style: TextStyle(
              fontSize: isBold ? 18 : 16,
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