import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../../config/theme.dart';
import '../../config/app_config.dart';
import 'package:provider/provider.dart';
import '../../widgets/app_badge.dart';
import '../../providers/auth_provider.dart';
import '../../models/billing.dart';

class BillingListScreen extends StatefulWidget {
  final String? startDateIso;
  final String? endDateIso;

  const BillingListScreen({super.key, this.startDateIso, this.endDateIso});

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
      String url = AppConfig.billingEndpoint;
      if (widget.startDateIso != null && widget.endDateIso != null) {
        url = '$url?startDate=${widget.startDateIso}&endDate=${widget.endDateIso}';
      }
      final response = await _api.get(url);
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
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi tải dữ liệu: $e')),
          );
        });
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
          Consumer<AuthProvider>(builder: (context, auth, _) {
            return IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: auth.isActive ? _loadBillings : null,
              tooltip: auth.isActive ? 'Làm mới' : 'Tài khoản chưa kích hoạt',
            );
          }),
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
              boxShadow: AppShadows.cardShadowLight,
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
                  child: AppBadge(
                    radius: 20,
                    backgroundColor: AppTheme.primaryGreen,
                    icon: Icons.payments,
                    showRing: false,
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
                  // Show a clear avatar/initials so the colored box is not empty-looking
                  Builder(builder: (_) {
                    final fullName = billing.patientInfo?.fullName ?? '';
                    return Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: (billing.isPaid ? AppTheme.success : AppTheme.warning).withValues(alpha: 20),
                        ),
                        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6, offset: const Offset(0, 3))],
                      ),
                      child: CircleAvatar(
                        radius: 22,
                        backgroundColor: billing.isPaid ? AppTheme.success : AppTheme.warning,
                        child: fullName.isNotEmpty
                            ? Text(
                                _initialsFromName(fullName),
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              )
                            : const Icon(
                                Icons.person,
                                color: Colors.white,
                              ),
                      ),
                    );
                  }),
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
                  _buildStatusChip(
                    (billing.paymentStatus.trim().isEmpty)
                        ? (billing.isPaid ? 'Đã thanh toán' : 'Chưa thanh toán')
                        : billing.paymentStatus,
                  ),
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
                    ConstrainedBox(
                      constraints: const BoxConstraints(minWidth: 88, minHeight: 28),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryGreen,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryGreen.withValues(alpha: 20),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Text(
                          '${billing.serviceCharges.length} dịch vụ',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  if (billing.medicineCharges.isNotEmpty)
                    ConstrainedBox(
                      constraints: const BoxConstraints(minWidth: 88, minHeight: 28),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.secondaryBlue,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.secondaryBlue.withValues(alpha: 20),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Text(
                          '${billing.medicineCharges.length} thuốc',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                ],
              ),

              // Action Buttons
              if (billing.isUnpaid) ...[
                const SizedBox(height: 12),
                Consumer<AuthProvider>(builder: (context, auth, _) {
                  if (!auth.canManageBilling) return const SizedBox.shrink();
                  return SizedBox(
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
                  );
                }),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    // Normalize and provide a safe fallback so the chip never appears empty.
    final label = (status.trim().isEmpty) ? 'Chưa thanh toán' : status.trim();

    Color color;
    IconData icon;
    switch (label) {
      case 'Đã thanh toán':
        color = AppTheme.success;
        icon = Icons.check_circle;
        break;
      case 'Chưa thanh toán':
        color = AppTheme.warning;
        icon = Icons.pending;
        break;
      default:
        color = AppTheme.error;
        icon = Icons.cancel;
    }

    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 92),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color, // solid background so the label is always readable
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: color.withValues(alpha: 31), blurRadius: 4, offset: const Offset(0, 1)),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: Colors.white),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
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
                    initialValue: paymentMethod,
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

  String _initialsFromName(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    final first = parts.first.substring(0, 1).toUpperCase();
    final last = parts.last.substring(0, 1).toUpperCase();
    return '$first$last';
  }
}