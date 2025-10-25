import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../../config/theme.dart';
import '../../config/app_config.dart';
import '../../models/billing.dart';

class BillingListScreen extends StatefulWidget {
  const BillingListScreen({super.key});

  @override
  State<BillingListScreen> createState() => _BillingListScreenState();
}

class _BillingListScreenState extends State<BillingListScreen> {
  final ApiService _api = ApiService();
  List<Billing> _billings = [];
  bool _isLoading = true;
  String _selectedStatus = 'Tất cả';

  @override
  void initState() {
    super.initState();
    _loadBillings();
  }

  Future<void> _loadBillings() async {
    setState(() => _isLoading = true);
    try {
      final response = await _api.get(AppConfig.billingEndpoint);
      if (response['success']) {
        setState(() {
          _billings = (response['data'] as List)
              .map((json) => Billing.fromJson(json))
              .toList();
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

  List<Billing> get _filteredBillings {
    if (_selectedStatus == 'Tất cả') return _billings;
    return _billings.where((b) => b.paymentStatus == _selectedStatus).toList();
  }

  double get _totalRevenue {
    return _filteredBillings
        .where((b) => b.isPaid)
        .fold(0, (sum, b) => sum + b.totalAmount);
  }

  Future<void> _updatePaymentStatus(String id, String status) async {
    try {
      await _api.put(
        '${AppConfig.billingEndpoint}/$id/payment',
        {
          'paymentStatus': status,
          'paymentMethod': 'Tiền mặt',
          'paidDate': DateTime.now().toIso8601String(),
        },
      );
      _loadBillings();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã cập nhật trạng thái thanh toán'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý thanh toán'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadBillings,
          ),
        ],
      ),
      body: Column(
        children: [
          // Summary Card
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppGradients.primaryGradient,
              borderRadius: BorderRadius.circular(12),
              boxShadow: AppShadows.cardShadow,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tổng doanh thu',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _formatCurrency(_totalRevenue),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 51),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.payments,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
              ],
            ),
          ),

          // Filter Section
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('Tất cả'),
                  _buildFilterChip('Chưa thanh toán'),
                  _buildFilterChip('Đã thanh toán'),
                  _buildFilterChip('Thanh toán một phần'),
                ],
              ),
            ),
          ),

          // Billing Count
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: AppTheme.lightGrey,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Tổng số: ${_filteredBillings.length} hóa đơn',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.darkGrey,
                  ),
                ),
                if (_selectedStatus != 'Tất cả')
                  Text(
                    'Tổng: ${_formatCurrency(_filteredBillings.fold(0.0, (sum, b) => sum + b.totalAmount))}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
              ],
            ),
          ),

          // Billing List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredBillings.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadBillings,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(8),
                          itemCount: _filteredBillings.length,
                          itemBuilder: (context, index) {
                            return _buildBillingCard(_filteredBillings[index]);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedStatus == label;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() => _selectedStatus = label);
        },
        backgroundColor: Colors.white,
        selectedColor: AppTheme.accentGreen,
        checkmarkColor: Colors.white,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : AppTheme.darkGrey,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildBillingCard(Billing billing) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: InkWell(
        onTap: () async {
          final result = await Navigator.pushNamed(
            context,
            '/billing/detail',
            arguments: billing.id,
          );
          if (result == true) {
            _loadBillings();
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: billing.isPaid 
                          ? AppTheme.success.withValues(alpha: 26)
                          : AppTheme.warning.withValues(alpha: 26),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.receipt_long,
                      color: billing.isPaid ? AppTheme.success : AppTheme.warning,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          billing.patientInfo?.fullName ?? 'N/A',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          dateFormat.format(billing.createdAt ?? DateTime.now()),
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusChip(billing.paymentStatus),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 12),

              // Cost Details
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Tạm tính',
                        style: TextStyle(fontSize: 12, color: AppTheme.grey),
                      ),
                      Text(
                        _formatCurrency(billing.subtotal),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  if (billing.discount > 0)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text(
                          'Giảm giá',
                          style: TextStyle(fontSize: 12, color: AppTheme.grey),
                        ),
                        Text(
                          '- ${_formatCurrency(billing.discount)}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.accentOrange,
                          ),
                        ),
                      ],
                    ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'Tổng cộng',
                        style: TextStyle(fontSize: 12, color: AppTheme.grey),
                      ),
                      Text(
                        _formatCurrency(billing.totalAmount),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.secondaryBlue,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // Items Count
              const SizedBox(height: 12),
              Row(
                children: [
                  if (billing.serviceCharges.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreen.withValues(alpha: 26),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${billing.serviceCharges.length} dịch vụ',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.primaryGreen,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  if (billing.medicineCharges.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.secondaryBlue.withValues(alpha: 26),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${billing.medicineCharges.length} thuốc',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.secondaryBlue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),

              // Action Buttons
              if (billing.isUnpaid) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      _showPaymentDialog(billing);
                    },
                    icon: const Icon(Icons.payment, size: 18),
                    label: const Text('Thanh toán'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.success,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    IconData icon;
    
    switch (status) {
      case 'Đã thanh toán':
        color = AppTheme.success;
        icon = Icons.check_circle;
        break;
      case 'Thanh toán một phần':
        color = AppTheme.warning;
        icon = Icons.schedule;
        break;
      default:
        color = AppTheme.error;
        icon = Icons.pending;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 26),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 77)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            status,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 80,
            color: AppTheme.grey.withValues(alpha: 128),
          ),
          const SizedBox(height: 16),
          Text(
            'Chưa có hóa đơn nào',
            style: TextStyle(
              fontSize: 18,
              color: AppTheme.grey.withValues(alpha: 179),
            ),
          ),
        ],
      ),
    );
  }

  void _showPaymentDialog(Billing billing) {
    String paymentMethod = 'Tiền mặt';
    
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Xác nhận thanh toán'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bệnh nhân: ${billing.patientInfo?.fullName}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tổng tiền: ${_formatCurrency(billing.totalAmount)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Phương thức thanh toán:'),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: paymentMethod,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    items: ['Tiền mặt', 'Chuyển khoản', 'Thẻ'].map((method) {
                      return DropdownMenuItem(
                        value: method,
                        child: Text(method),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => paymentMethod = value);
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Hủy'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _updatePaymentStatus(billing.id!, 'Đã thanh toán');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.success,
                  ),
                  child: const Text('Xác nhận'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _formatCurrency(double value) {
    final amount = value.toInt();
    return '${amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}đ';
  }
}