import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../config/theme.dart';
import '../../config/app_config.dart';
import '../../providers/auth_provider.dart';

class MedicalRecordDetailScreen extends StatefulWidget {
  final String recordId;
  const MedicalRecordDetailScreen({super.key, required this.recordId});

  @override
  State<MedicalRecordDetailScreen> createState() => _MedicalRecordDetailScreenState();
}

class _MedicalRecordDetailScreenState extends State<MedicalRecordDetailScreen> {
  final ApiService _api = ApiService();
  Map<String, dynamic>? _record;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecord();
  }

  Future<void> _loadRecord() async {
    setState(() => _isLoading = true);
    try {
      final response = await _api.get('${AppConfig.medicalRecordsEndpoint}/${widget.recordId}');
      if (response['success']) {
        setState(() {
          _record = response['data'] as Map<String, dynamic>?;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải chi tiết: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    return Scaffold(
      appBar: AppBar(title: const Text('Chi tiết hồ sơ')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _record == null
              ? const Center(child: Text('Không tìm thấy hồ sơ'))
              : Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _record!['patientName'] ?? _record!['patient'] ?? 'Bệnh nhân',
                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              if (_record!['visitDate'] != null)
                                Text('Ngày khám: ${dateFormat.format(DateTime.parse(_record!['visitDate']))}'),
                              const SizedBox(height: 8),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  if (_record!['doctorName'] != null)
                                        Padding(
                                          padding: const EdgeInsets.only(right: 8.0),
                                          child: Chip(
                                            backgroundColor: AppTheme.primaryGreen.withValues(alpha: 26),
                                            avatar: Icon(Icons.person, size: 16, color: AppTheme.primaryGreen.contrastText),
                                            label: Text('Bác sĩ: ${_record!['doctorName']}', style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary)),
                                          ),
                                        ),
                                  if (_record!['roomNumber'] != null)
                                    Padding(
                                      padding: const EdgeInsets.only(right: 8.0),
                                      child: Chip(
                                        backgroundColor: AppTheme.grey.withValues(alpha: 26),
                                        avatar: Icon(Icons.meeting_room, size: 16, color: AppTheme.darkGrey),
                                        label: Text('Phòng ${_record!['roomNumber']}', style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary)),
                                      ),
                                    ),
                                  if (_record!['status'] != null)
                                    Padding(
                                      padding: const EdgeInsets.only(right: 8.0),
                                      child: Chip(
                                        backgroundColor: _record!['status'] == 'Hoàn thành' ? Colors.green.shade100 : Colors.orange.shade100,
                                        avatar: const Icon(Icons.check_circle, size: 16, color: Colors.black54),
                                        label: Text('${_record!['status']}', style: const TextStyle(fontSize: 13)),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),
                      Expanded(
                        child: ListView(
                          children: [
                if (_record!['symptoms'] != null) _sectionCard('Triệu chứng', _record!['symptoms']),
              if (_record!['diagnosis'] != null) _sectionCard('Chẩn đoán', _record!['diagnosis']),
                            if ((_record!['services'] as List?)?.isNotEmpty == true)
                              _listSectionCard('Dịch vụ', (_record!['services'] as List)),
                            if ((_record!['prescriptions'] as List?)?.isNotEmpty == true)
                              _listSectionCard('Đơn thuốc', (_record!['prescriptions'] as List)),
                            if (_record!['notes'] != null) _sectionCard('Ghi chú', _record!['notes']),
                            const SizedBox(height: 8),
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('TỔNG CỘNG', style: TextStyle(fontWeight: FontWeight.bold)),
                                    Builder(builder: (context) {
                                      final raw = _record!['totalAmount'];
                                      double total = _toDouble(raw);
                                      // If API doesn't provide total or it's zero, compute from services & prescriptions
                                      if (total <= 0) {
                                        double sum = 0.0;
                                        final services = (_record!['services'] as List?) ?? [];
                                        for (final s in services) {
                                          sum += _toDouble(s['price']) * _toDouble(s['quantity'] ?? s['qty'] ?? 1);
                                        }
                                        final prescriptions = (_record!['prescriptions'] as List?) ?? [];
                                        for (final p in prescriptions) {
                                          sum += _toDouble(p['unitPrice'] ?? p['price']) * _toDouble(p['quantity'] ?? p['qty'] ?? 1);
                                        }
                                        total = sum;
                                      }
                                      return Text(_formatCurrency(total), style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryGreen));
                                    }),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Action buttons (guarded)
                            Consumer<AuthProvider>(builder: (context, auth, _) {
                              final List<Widget> actions = [];
                              if (auth.isActive && auth.canManageBilling) {
                                actions.add(ElevatedButton.icon(
                                  onPressed: () {
                                    // Navigate to billing create page or implement billing flow
                                  },
                                  icon: const Icon(Icons.receipt_long),
                                  label: const Text('Tạo hóa đơn'),
                                ));
                              }
                              if (auth.isActive) {
                                actions.add(ElevatedButton.icon(
                                  onPressed: () {
                                    // Placeholder: export/print
                                  },
                                  icon: const Icon(Icons.print),
                                  label: const Text('In/Export'),
                                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.secondaryBlue),
                                ));
                              }

                              if (actions.isEmpty) return const SizedBox.shrink();
                              return Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: actions.map((w) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: w))).toList(),
                              );
                            }),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _sectionCard(String title, dynamic content) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(content?.toString() ?? ''),
          ],
        ),
      ),
    );
  }

  Widget _listSectionCard(String title, List items) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...items.map<Widget>((it) {
              final name = it['serviceName'] ?? it['medicineName'] ?? it['name'] ?? 'N/A';
              final qty = it['quantity'] ?? it['qty'] ?? '';
              final price = it['price'] ?? it['unitPrice'] ?? '';
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text('- $name ${qty != '' ? 'x$qty' : ''}')),
                    if (price != '') Text(_formatCurrency(_toDouble(price))),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    if (v is String) {
      final cleaned = v.replaceAll(RegExp(r"[^0-9\.-]"), '');
      return double.tryParse(cleaned) ?? 0.0;
    }
    return 0.0;
  }

  String _formatCurrency(double value) {
    final amount = value.toInt();
    return '${amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}đ';
  }
}
