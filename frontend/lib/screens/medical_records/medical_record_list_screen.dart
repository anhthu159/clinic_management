import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../../config/theme.dart';
import '../../config/app_config.dart';
import '../../models/medical_record.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class MedicalRecordListScreen extends StatefulWidget {
  final String? patientId;
  
  const MedicalRecordListScreen({super.key, this.patientId});

  @override
  State<MedicalRecordListScreen> createState() => _MedicalRecordListScreenState();
}

class _MedicalRecordListScreenState extends State<MedicalRecordListScreen> {
  final ApiService _api = ApiService();
  List<MedicalRecord> _records = [];
  bool _isLoading = true;
  String _selectedStatus = 'Tất cả';

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    setState(() => _isLoading = true);
    try {
      String endpoint = widget.patientId != null
          ? '${AppConfig.medicalRecordsEndpoint}/patient/${widget.patientId}'
          : AppConfig.medicalRecordsEndpoint;

      final response = await _api.get(endpoint);
      if (response['success']) {
        setState(() {
          _records = (response['data'] as List)
              .map((json) => MedicalRecord.fromJson(json))
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

  List<MedicalRecord> get _filteredRecords {
    if (_selectedStatus == 'Tất cả') return _records;
    return _records.where((r) => r.status == _selectedStatus).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.patientId != null 
            ? 'Lịch sử khám bệnh' 
            : 'Hồ sơ khám bệnh'),
        actions: [
          Consumer<AuthProvider>(builder: (context, auth, _) {
            return IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: auth.isActive ? _loadRecords : null,
              tooltip: auth.isActive ? 'Làm mới' : 'Tài khoản chưa kích hoạt',
            );
          }),
        ],
      ),
      body: Column(
        children: [
          // Filter Section
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('Tất cả'),
                  _buildFilterChip('Đang khám'),
                  _buildFilterChip('Hoàn thành'),
                  _buildFilterChip('Hủy'),
                ],
              ),
            ),
          ),

          // Record Count
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: AppTheme.lightGrey,
            child: Row(
              children: [
                Text(
                  'Tổng số: ${_filteredRecords.length} hồ sơ',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.darkGrey,
                  ),
                ),
              ],
            ),
          ),

          // Records List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredRecords.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadRecords,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(8),
                          itemCount: _filteredRecords.length,
                          itemBuilder: (context, index) {
                            return _buildRecordCard(_filteredRecords[index]);
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: Consumer<AuthProvider>(builder: (context, auth, _) {
        if (!auth.canCreateMedicalRecord) return const SizedBox.shrink();
        return FloatingActionButton.extended(
          onPressed: () async {
            final result = await Navigator.pushNamed(
              context,
              '/medical-records/add',
              arguments: widget.patientId,
            );
            if (result == true) {
              _loadRecords();
            }
          },
          icon: const Icon(Icons.add),
          label: const Text('Tạo hồ sơ'),
        );
      }),
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

  Widget _buildRecordCard(MedicalRecord record) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: InkWell(
        onTap: () async {
          final result = await Navigator.pushNamed(
            context,
            '/medical-records/detail',
            arguments: record.id,
          );
          if (result == true) {
            _loadRecords();
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
                  // White circular badge with subtle ring to replace heavy gradient box
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 15)),
                      boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6, offset: const Offset(0, 3))],
                    ),
                    padding: const EdgeInsets.all(8),
                    child: Icon(
                      Icons.assignment,
                      color: AppTheme.primaryGreen,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          record.patientInfo?.fullName ?? 'N/A',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          dateFormat.format(record.visitDate),
                          style: const TextStyle(
                              fontSize: 14,
                              color: AppTheme.textSecondary,
                            ),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusChip(record.status),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),

              // Symptoms
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.sick, size: 16, color: AppTheme.primaryGreen),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                              'Triệu chứng',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                        Text(
                          record.symptoms,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppTheme.textPrimary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              if (record.diagnosis != null) ...[
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.medical_information, 
                        size: 16, color: AppTheme.secondaryBlue),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Chẩn đoán',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                            Text(
                            record.diagnosis!,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 12),

              // Doctor and Room
              Row(
                children: [
                  if (record.doctorName != null) ...[ 
                    const Icon(Icons.person, size: 16, color: AppTheme.primaryGreen),
                    const SizedBox(width: 6),
                    Text(
                      record.doctorName!,
                      style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                    ),
                  ],
                  if (record.doctorName != null && record.roomNumber != null)
                    const SizedBox(width: 16),
                  if (record.roomNumber != null) ...[ 
                    const Icon(Icons.meeting_room, size: 16, color: AppTheme.darkGrey),
                    const SizedBox(width: 6),
                    Text(
                      'Phòng ${record.roomNumber}',
                      style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                    ),
                  ],
                ],
              ),

              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),

              // Cost Summary
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Chi phí',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatCurrency(record.subtotal),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryGreen,
                        ),
                      ),
                    ],
                  ),
                  if (record.discount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                              color: AppTheme.accentOrange.withValues(alpha: 26),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.discount,
                            size: 14,
                            color: AppTheme.accentOrange,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Giảm ${_formatCurrency(record.discount)}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.accentOrange,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                      Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'Tổng cộng',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatCurrency(record.totalAmount),
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

              // Services and Medicines count
              const SizedBox(height: 8),
              Row(
                children: [
                  if (record.services.isNotEmpty) ...[
                    ConstrainedBox(
                      constraints: const BoxConstraints(minWidth: 72, minHeight: 28),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: AppTheme.primaryGreen,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                '${record.services.length} dịch vụ',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.darkGrey,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  if (record.prescriptions.isNotEmpty)
                    ConstrainedBox(
                      constraints: const BoxConstraints(minWidth: 72, minHeight: 28),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: AppTheme.secondaryBlue,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                '${record.prescriptions.length} thuốc',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.darkGrey,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
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
      case 'Hoàn thành':
        color = AppTheme.success;
        icon = Icons.check_circle;
        break;
      case 'Hủy':
        color = AppTheme.error;
        icon = Icons.cancel;
        break;
      default:
        color = AppTheme.secondaryBlue;
        icon = Icons.access_time;
    }

    // Ensure label is visible: give a minimum width and use contrastText for readable text color
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 88),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 26),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 77)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color.contrastText),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                status,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: color.contrastText,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
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
            Icons.assignment_outlined,
            size: 80,
            color: AppTheme.grey.withValues(alpha: 128),
          ),
          const SizedBox(height: 16),
          Text(
            'Chưa có hồ sơ khám bệnh',
            style: TextStyle(
              fontSize: 18,
              color: AppTheme.grey.withValues(alpha: 179),
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