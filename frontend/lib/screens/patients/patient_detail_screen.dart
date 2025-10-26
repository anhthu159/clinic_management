import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../../config/theme.dart';
import '../../config/app_config.dart';
import '../../models/patient.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class PatientDetailScreen extends StatefulWidget {
  final String patientId;

  const PatientDetailScreen({super.key, required this.patientId});

  @override
  State<PatientDetailScreen> createState() => _PatientDetailScreenState();
}

class _PatientDetailScreenState extends State<PatientDetailScreen> {
  final ApiService _api = ApiService();
  Patient? _patient;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPatient();
  }

  Future<void> _loadPatient() async {
    setState(() => _isLoading = true);
    try {
      final response = await _api.get(
        '${AppConfig.patientsEndpoint}/${widget.patientId}',
      );
      if (response['success']) {
        setState(() {
          _patient = Patient.fromJson(response['data']);
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

  Future<void> _deletePatient() async {
    try {
      await _api.delete('${AppConfig.patientsEndpoint}/${widget.patientId}');
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã xóa bệnh nhân thành công'),
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
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông tin bệnh nhân'),
        actions: [
          Consumer<AuthProvider>(builder: (context, auth, _) {
            final canEdit = auth.canCreatePatient;
            final canDelete = auth.canDeletePatient;
            final actions = <Widget>[];
            if (canEdit) {
              actions.add(IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () async {
                  final result = await Navigator.pushNamed(
                    context,
                    '/patients/edit',
                    arguments: _patient,
                  );
                  if (result == true) {
                    _loadPatient();
                  }
                },
              ));
            }
            if (canDelete) {
              actions.add(IconButton(
                icon: const Icon(Icons.delete),
                onPressed: _confirmDelete,
              ));
            }
            return Row(mainAxisSize: MainAxisSize.min, children: actions);
          }),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _patient == null
              ? const Center(child: Text('Không tìm thấy bệnh nhân'))
              : RefreshIndicator(
                  onRefresh: _loadPatient,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Avatar & Basic Info
                        Center(
                          child: Column(
                            children: [
                              Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  gradient: AppGradients.primaryGradient,
                                  shape: BoxShape.circle,
                                  boxShadow: AppShadows.cardShadow,
                                ),
                                child: Center(
                                  child: Text(
                                    _patient!.fullName[0].toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 40,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _patient!.fullName,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              _buildTypeChip(_patient!.patientType),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Personal Information
                        _buildSectionTitle('Thông tin cá nhân'),
                        const SizedBox(height: 16),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                _buildInfoRow(
                                  Icons.phone,
                                  'Số điện thoại',
                                  _patient!.phone,
                                ),
                                const Divider(height: 24),
                                _buildInfoRow(
                                  Icons.cake,
                                  'Ngày sinh',
                                  '${dateFormat.format(_patient!.dateOfBirth)} (${_patient!.age} tuổi)',
                                ),
                                const Divider(height: 24),
                                _buildInfoRow(
                                  _patient!.gender == 'Nam'
                                      ? Icons.male
                                      : Icons.female,
                                  'Giới tính',
                                  _patient!.gender ?? 'Chưa xác định',
                                ),
                                if (_patient!.idCard != null) ...[
                                  const Divider(height: 24),
                                  _buildInfoRow(
                                    Icons.credit_card,
                                    'CMND/CCCD',
                                    _patient!.idCard!,
                                  ),
                                ],
                                if (_patient!.email != null) ...[
                                  const Divider(height: 24),
                                  _buildInfoRow(
                                    Icons.email,
                                    'Email',
                                    _patient!.email!,
                                  ),
                                ],
                                if (_patient!.address != null) ...[
                                  const Divider(height: 24),
                                  _buildInfoRow(
                                    Icons.location_on,
                                    'Địa chỉ',
                                    _patient!.address!,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Quick Actions
                        _buildSectionTitle('Thao tác nhanh'),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: Consumer<AuthProvider>(builder: (context, auth, _) {
                                final enabled = auth.isActive && auth.canCreateAppointment;
                                return _buildActionCard(
                                  icon: Icons.calendar_today,
                                  label: 'Đặt lịch hẹn',
                                  color: AppTheme.secondaryBlue,
                                  onTap: enabled
                                      ? () {
                                          Navigator.pushNamed(
                                            context,
                                            '/appointments/add',
                                            arguments: _patient!.id,
                                          );
                                        }
                                      : null,
                                );
                              }),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Consumer<AuthProvider>(builder: (context, auth, _) {
                                final enabled = auth.isActive && auth.canCreateMedicalRecord;
                                return _buildActionCard(
                                  icon: Icons.assignment,
                                  label: 'Tạo hồ sơ',
                                  color: AppTheme.primaryGreen,
                                  onTap: enabled
                                      ? () {
                                          Navigator.pushNamed(
                                            context,
                                            '/medical-records/add',
                                            arguments: _patient!.id,
                                          );
                                        }
                                      : null,
                                );
                              }),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: Consumer<AuthProvider>(builder: (context, auth, _) {
                            final enabled = auth.isActive;
                            return _buildActionCard(
                              icon: Icons.history,
                              label: 'Xem lịch sử khám bệnh',
                              color: AppTheme.accentOrange,
                              onTap: enabled
                                  ? () {
                                      Navigator.pushNamed(
                                        context,
                                        '/medical-records',
                                        arguments: {'patientId': _patient!.id},
                                      );
                                    }
                                  : null,
                            );
                          }),
                        ),

                        const SizedBox(height: 24),

                        // Registration Info
                        _buildSectionTitle('Thông tin đăng ký'),
                        const SizedBox(height: 16),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                if (_patient!.createdAt != null)
                                  _buildInfoRow(
                                    Icons.person_add,
                                    'Ngày đăng ký',
                                    DateFormat('dd/MM/yyyy HH:mm')
                                        .format(_patient!.createdAt!),
                                  ),
                                if (_patient!.updatedAt != null &&
                                    _patient!.createdAt != null) ...[
                                  const Divider(height: 24),
                                  _buildInfoRow(
                                    Icons.update,
                                    'Cập nhật lần cuối',
                                    DateFormat('dd/MM/yyyy HH:mm')
                                        .format(_patient!.updatedAt!),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
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

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppTheme.primaryGreen),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.grey,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.black,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTypeChip(String type) {
    Color color;
    switch (type) {
      case 'BHYT':
        color = AppTheme.secondaryBlue;
        break;
      case 'VIP':
        color = AppTheme.accentOrange;
        break;
      default:
        color = AppTheme.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 26),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Text(
        type,
        style: TextStyle(
          color: color,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String label,
    required Color color,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 26),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 77)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text(
          'Bạn có chắc chắn muốn xóa bệnh nhân "${_patient!.fullName}"?\n\nHành động này không thể hoàn tác.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deletePatient();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }
}